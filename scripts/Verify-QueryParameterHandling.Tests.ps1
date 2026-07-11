#Requires -Version 7
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()
BeforeAll {
    $saveNetboxHost = $env:NETBOX_HOST
    $saveNetboxScheme = $env:NETBOX_SCHEME
    $saveNetboxToken = $env:NETBOX_TOKEN
    $saveNetboxVersion = $env:NETBOX_VERSION

    $Script:ScriptPath = Join-Path $PSScriptRoot 'Verify-QueryParameterHandling.ps1'
    $Script:ProjectRoot = Split-Path $Script:ScriptPath -Parent

    $psdPath = Join-Path -Path $Script:ProjectRoot -ChildPath '..' -AdditionalChildPath 'PowerNetbox','PowerNetbox.psd1'
    Import-Module $psdPath -Force -ErrorAction Stop
}

AfterAll {
    $env:NETBOX_HOST = $saveNetboxHost
    $env:NETBOX_SCHEME = $saveNetboxScheme
    $env:NETBOX_TOKEN = $saveNetboxToken
    $env:NETBOX_VERSION = $saveNetboxVersion
}
Describe 'Verify-QueryParameterHandling' {
    Context 'Basic tests' {
        It 'exists' {
            Test-Path $Script:ScriptPath | Should -BeTrue
        }

        It 'Uses the environment variable by default' {
            Mock Invoke-RestMethod { Throw "This should not happen" }
            Mock Invoke-RestMethod { Throw "Used expected default parameters" }-ParameterFilter { $uri -eq 'http://localhost/api/schema/?format=json' }

            $env:NETBOX_HOST = 'localhost'
            $env:NETBOX_SCHEME = 'http'
            $env:NETBOX_TOKEN = 'dummy'
            $env:NETBOX_VERSION = 'v1'

            { & $Script:ScriptPath } | Should -Throw "Used expected default parameters"
        }
}
    Context 'Query parameter handling' {
        BeforeAll {
            # restore environment variables to ensure a clean state for the tests
            $env:NETBOX_HOST = $saveNetboxHost
            $env:NETBOX_SCHEME = $saveNetboxScheme
            $env:NETBOX_TOKEN = $saveNetboxToken
            $env:NETBOX_VERSION = $saveNetboxVersion

            #region connection setup (taken from Integration tests)
            $secureToken = ConvertTo-SecureString -String $env:NETBOX_TOKEN -AsPlainText -Force
            $credential = [PSCredential]::new('api', $secureToken)

            # Parse hostname and port (supports "hostname" or "hostname:port" format)
            $hostValue = $env:NETBOX_HOST
            $hostname = $hostValue
            $port = $null

            if ($hostValue -match '^(.+):(\d+)$') {
                $hostname = $Matches[1]
                $port = [int]$Matches[2]
            }

            # Determine scheme - default to http for Docker CI, https for cloud
            $scheme = $env:NETBOX_SCHEME
            if ([string]::IsNullOrEmpty($scheme)) {
                # Docker CI uses http on localhost
                if ($hostname -match 'localhost|127\.0\.0\.1') {
                    $scheme = 'http'
                }
                else {
                    $scheme = 'https'
                }
            }

            $connectParams = @{
                Hostname   = $hostname
                Port       = 443
                Credential = $credential
                Scheme     = $scheme
            }

            # Add port if specified
            if ($port) {
                $connectParams['Port'] = $port
            }

            # Only skip certificate check for https
            if ($scheme -eq 'https') {
                $connectParams['SkipCertificateCheck'] = $true
            }

            Connect-NBAPI @connectParams
            #endregion

            # read the API schema for later use in the tests (avoids multiple calls to the API schema endpoint)
            $url = "$($connectParams['Scheme'])://$($connectParams['Hostname']):$($connectParams['Port'])/api/schema/?format=json"
            $ApiSchema = Invoke-RestMethod -Uri $url -ContentType 'application/json'

            #region determine, which mapping of query parameters to endpoints is currently used in the module
            $nbVersion = [version] (Get-NbVersion).'netbox-version'
            $ApiVersion = $nbVersion.Major.ToString() + '.' + $nbVersion.Minor.ToString()

            $OriginalCaseParameterDictonary = InModuleScope -ModuleName PowerNetBox {
                $Script:IgnoreCaseParameterDictonary
            }
            $OriginalCaseParameterDictonary | Should -Not -BeNullOrEmpty
            #endregion
            $saveParameterHash = $OriginalCaseParameterDictonary[$ApiVersion]

            $spaltScriptParams = @{
                OutputFormat = 'Object'
                QueryParameterHash = $null          # Be sure to add this parameter on every test
                ApiSchema = $ApiSchema              # Avoid multiple calls to the API schema endpoint
            }
        }
        BeforeEach {
        }
        It 'Should not detect anything about query parameters' {
            $thisParameterHash = $saveParameterHash.Clone()
            $ret = & $Script:ScriptPath @spaltScriptParams -QueryParameterHash $thisParameterHash | Where-Object finding -ne 'function name not found in module'
            $ret | Should -BeNullOrEmpty
        }
        It 'Should detect a missing query parameter' {
            $thisParameterHash = $saveParameterHash.Clone()
            $key = $thisParameterHash.Keys | Select-Object -First 1
            $thisParameterHash.Remove($key) | Out-Null

            $ret = & $Script:ScriptPath @spaltScriptParams -QueryParameterHash $thisParameterHash | Where-Object finding -ne 'function name not found in module'
            $ret | Should -Not -BeNullOrEmpty
            $ret.Finding | Should -Be 'not in dictionary'
            $ret.Data.Parameter | Should -Be $key
        }
        It 'Should find parameter which is not part of any API endpoint' {
            $thisParameterHash = $saveParameterHash.Clone()
            $thisParameterHash['nonexistent_parameter'] = @('nonexistent_endpoint')

            $ret = & $Script:ScriptPath @spaltScriptParams -QueryParameterHash $thisParameterHash | Where-Object finding -ne 'function name not found in module'
            $ret | Should -Not -BeNullOrEmpty
            $ret.Finding | Should -Be 'Dictionary entry without corresponding parametername'
            $ret.Data | Should -Be 'nonexistent_parameter'
        }
        It 'Should find notexisting endpoint, when there is no exception list for the parameter' {
            $thisParameterHash = $saveParameterHash.Clone()
            $key = $thisParameterHash.Keys | Where-Object { $thisParameterHash[$_].Count -eq 0 } | Select-Object -First 1
            $thisParameterHash[$key] = @('api/unknwon/endpoint/')

            $ret = & $Script:ScriptPath @spaltScriptParams -QueryParameterHash $thisParameterHash | Where-Object finding -ne 'function name not found in module'
            $ret | Should -Not -BeNullOrEmpty
            $ret.Finding | Should -Be 'exception list not empty'
            $ret.Data | Should -Be $key
        }
        It 'Should find missing endpoint' {
            $thisParameterHash = $saveParameterHash.Clone()
            $key = $thisParameterHash.Keys | Where-Object { $thisParameterHash[$_].Count -gt 2 } | Select-Object -First 1
            $exceptionListBefore = $thisParameterHash[$key]
            $thisParameterHash[$key] = $thisParameterHash[$key] | Select-Object -First ($thisParameterHash[$key].Count - 2)

            $ret = & $Script:ScriptPath @spaltScriptParams -QueryParameterHash $thisParameterHash | Where-Object finding -ne 'function name not found in module'
            $ret.Count | Should -Be 2 -Because 'We removed 2 endpoints from the exception list'
            $ret[0].Finding | Should -Be 'missing in exception list'
            $ret[0].Data.Parameter | Should -Be $key
            $ret[1].Finding | Should -Be 'missing in exception list'
            $ret[1].Data.Parameter | Should -Be $key
        }
    }
}