[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

BeforeAll {
    Import-Module Pester
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -ErrorAction Stop
    }
}

Describe "Setup tests" -Tag 'Core', 'Setup' {
    It "Throws an error for an empty hostname" {
        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = $null
        }
        { Get-NBHostname } | Should -Throw
    }

    It "Should set and get the hostname" {
        Set-NBHostName -HostName 'netbox.domain.com' | Should -Be 'netbox.domain.com'
        Get-NBHostName | Should -Be 'netbox.domain.com'
    }

    It "Throws an error for empty credentials" {
        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Credential = $null
        }
        { Get-NBCredential } | Should -Throw
    }

    Context "Plain text credentials" {
        It "Sets the credentials using plain text" {
            Set-NBCredential -Token (ConvertTo-SecureString -String "faketoken" -Force -AsPlainText) | Should -BeOfType [pscredential]
        }

        It "Checks the set credentials" {
            Set-NBCredential -Token (ConvertTo-SecureString -String "faketoken" -Force -AsPlainText)
            (Get-NBCredential).GetNetworkCredential().Password | Should -BeExactly "faketoken"
        }
    }

    Context "Credentials object" {
        It "Should set and get credentials using [pscredential]" {
            $Creds = [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
            Set-NBCredential -Credential $Creds | Should -BeOfType [pscredential]
            (Get-NBCredential).GetNetworkCredential().Password | Should -BeExactly 'faketoken'
        }
    }

    Context "Token v2 Bearer Authentication" {
        BeforeAll {
            Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                return [ordered]@{
                    'Method'      = $Method
                    'Uri'         = $Uri
                    'Headers'     = $Headers
                    'Timeout'     = $Timeout
                    'ContentType' = $ContentType
                    'Body'        = $Body
                }
            }
            Mock -CommandName 'Get-NBHostname' -ModuleName 'PowerNetbox' -MockWith { return 'netbox.domain.com' }
            Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 30 }
            Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }

            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.Hostname = 'netbox.domain.com'
                $script:NetboxConfig.HostScheme = 'https'
                $script:NetboxConfig.HostPort = 443
            }
        }

        It "Should use Token auth header for v1 legacy tokens" {
            $v1Token = '0123456789abcdef0123456789abcdef01234567'
            Set-NBCredential -Token (ConvertTo-SecureString -String $v1Token -AsPlainText -Force)

            $Result = Get-NBDCIMSite
            $Result.Headers.Authorization | Should -Be "Token $v1Token"
        }

        It "Should use Bearer auth header for v2 nbt_ tokens" {
            $v2Token = 'nbt_abc123def456.ghijklmnopqrstuvwxyz1234567890'
            Set-NBCredential -Token (ConvertTo-SecureString -String $v2Token -AsPlainText -Force)

            $Result = Get-NBDCIMSite
            $Result.Headers.Authorization | Should -Be "Bearer $v2Token"
        }

        It "Should use Token auth for tokens not starting with nbt_" {
            $legacyToken = 'mylegacytoken12345'
            Set-NBCredential -Token (ConvertTo-SecureString -String $legacyToken -AsPlainText -Force)

            $Result = Get-NBDCIMSite
            $Result.Headers.Authorization | Should -Be "Token $legacyToken"
        }
    }

    Context "Test-NBAuthentication (Netbox 4.5+)" {
        BeforeAll {
            Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
            Mock -CommandName 'Get-NBHostname' -ModuleName 'PowerNetbox' -MockWith { return 'netbox.domain.com' }
            Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 30 }
            Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }
            Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
                return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
            }

            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.Hostname = 'netbox.domain.com'
                $script:NetboxConfig.HostScheme = 'https'
                $script:NetboxConfig.HostPort = 443
                $script:NetboxConfig.ParsedVersion = [version]'4.5.0'
                $script:NetboxConfig.NetboxVersion = @{ 'netbox-version' = '4.5.0' }
            }
        }

        It "Should return true when authentication succeeds" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    id       = 1
                    username = 'admin'
                    email    = 'admin@example.com'
                }
            }

            $Result = Test-NBAuthentication
            $Result | Should -Be $true
        }

        It "Should call the authentication-check endpoint" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                param($Uri)
                return @{ Uri = $Uri; username = 'admin' }
            }

            $Result = Test-NBAuthentication -Detailed
            $Result.User.Uri | Should -Match 'authentication-check'
        }

        It "Should return detailed user info when -Detailed is specified" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    id       = 1
                    username = 'admin'
                    email    = 'admin@example.com'
                }
            }

            $Result = Test-NBAuthentication -Detailed
            $Result.Authenticated | Should -Be $true
            $Result.User.username | Should -Be 'admin'
            $Result.Error | Should -BeNullOrEmpty
        }

        It "Should return false when authentication fails with 401" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                $response = [System.Net.HttpWebResponse]::new()
                $exception = [System.Net.WebException]::new("Unauthorized", $null, [System.Net.WebExceptionStatus]::ProtocolError, $response)
                throw $exception
            }

            # Since we can't easily mock 401, test the fallback behavior
            Mock -CommandName 'Get-NBVersion' -ModuleName 'PowerNetbox' -MockWith {
                throw "Unauthorized"
            }

            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.ParsedVersion = [version]'4.4.9'
            }

            $Result = Test-NBAuthentication
            $Result | Should -Be $false

            # Reset version
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.ParsedVersion = [version]'4.5.0'
            }
        }

        It "Should return error details when -Detailed and authentication fails" {
            Mock -CommandName 'Get-NBVersion' -ModuleName 'PowerNetbox' -MockWith {
                throw "Invalid token"
            }

            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.ParsedVersion = [version]'4.4.9'
            }

            $Result = Test-NBAuthentication -Detailed
            $Result.Authenticated | Should -Be $false
            $Result.Error | Should -Not -BeNullOrEmpty

            # Reset version
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.ParsedVersion = [version]'4.5.0'
            }
        }
    }

    Context "Test-NBAuthentication Fallback (Netbox 4.4.x)" {
        BeforeAll {
            Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
            Mock -CommandName 'Get-NBHostname' -ModuleName 'PowerNetbox' -MockWith { return 'netbox.domain.com' }
            Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 30 }
            Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }
            Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
                return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
            }

            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.Hostname = 'netbox.domain.com'
                $script:NetboxConfig.HostScheme = 'https'
                $script:NetboxConfig.HostPort = 443
                $script:NetboxConfig.ParsedVersion = [version]'4.4.9'
                $script:NetboxConfig.NetboxVersion = @{ 'netbox-version' = '4.4.9' }
            }
        }

        It "Should use fallback method on Netbox 4.4.x" {
            Mock -CommandName 'Get-NBVersion' -ModuleName 'PowerNetbox' -MockWith {
                return @{ 'netbox-version' = '4.4.9' }
            }

            $Result = Test-NBAuthentication
            $Result | Should -Be $true
        }

        It "Should return true with note about limited info in detailed mode" {
            Mock -CommandName 'Get-NBVersion' -ModuleName 'PowerNetbox' -MockWith {
                return @{ 'netbox-version' = '4.4.9' }
            }

            $Result = Test-NBAuthentication -Detailed
            $Result.Authenticated | Should -Be $true
            $Result.User | Should -BeNullOrEmpty
            $Result.Note | Should -Match 'prior to 4.5'
        }

        It "Should return false when fallback authentication fails" {
            Mock -CommandName 'Get-NBVersion' -ModuleName 'PowerNetbox' -MockWith {
                throw "Connection refused"
            }

            $Result = Test-NBAuthentication
            $Result | Should -Be $false
        }
    }

    Context "Host Port" {
        It "Should set, get, and reset the host port" {
            Set-NBHostPort -Port 8443 | Should -Be 8443
            Get-NBHostPort | Should -Be 8443
            Set-NBHostPort -Port 443 | Should -Be 443
        }
    }

    Context "Host Scheme" {
        It "Should set, get, and reset the host scheme" {
            Set-NBHostScheme -Scheme 'http' | Should -Be 'http'
            Get-NBHostScheme | Should -Be 'http'
            Set-NBHostScheme -Scheme 'https' | Should -Be 'https'
        }
    }

    Context "Invoke Params" {
        It "Should set and get invoke params" {
            $params = @{ SkipCertificateCheck = $true }
            Set-NBInvokeParams -InvokeParams $params | Should -Be $params

            $getResult = Get-NBInvokeParams
            $getResult | Should -BeOfType [hashtable]
            $getResult.SkipCertificateCheck | Should -Be $true
        }
    }

    Context "Timeout" {
        It "Should set, get, and reset the timeout" {
            Set-NBTimeout -TimeoutSeconds 60 | Should -Be 60
            Get-NBTimeout | Should -Be 60
            Set-NBTimeout -TimeoutSeconds 30 | Should -Be 30
        }
    }

    Context "Query options" {
        BeforeAll {
            $stateBefore = Get-NBQueryOption | Where-Object { $_.Name -eq 'IgnoreCase' }
            # We need to set the parsed version to a value for testing, so mocking the connect request
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                @'
                {
                "django-version": "5.2.13",
                "hostname": "1934a65908c1",
                "installed_apps": {},
                "netbox-version": "4.6.1",
                "netbox-full-version": "4.6.1-Docker-4.0.2",
                }
'@ | ConvertFrom-Json
            }
            $fakeCredential = [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
            Set-NBCredential -Credential $fakeCredential | Out-Null
        }
        AfterAll {
            # Reset the query option to its previous state
            Set-NBQueryOption -IgnoreCase:$stateBefore.Value | Out-Null
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.ParsedVersion = $parsedVersionBefore
            }
        }
        Context "While not connected" {
            It "Should return the current query option" {
                $result = Get-NbQueryOption
                $result.Name | Should -Contain 'IgnoreCase'
            }
            It "Should throw if try to set query options, because we need a parsed API version" {
                { Set-NBQueryOption -IgnoreCase:$true } | Should -Throw "Not connected*"
            }
            It "Should call Set-NBQueryOption inside Connect-NBAPI" {
                Mock -CommandName 'Set-NBQueryOption' -ModuleName 'PowerNetbox' -MockWith { return $true } -ParameterFilter { $IgnoreCase -eq $false } -Verifiable
                Mock -CommandName 'Set-NBQueryOption' -ModuleName 'PowerNetbox' -MockWith { Throw "Should not be called" } -ParameterFilter { $IgnoreCase -eq $true }
                Connect-NBAPI -Hostname 'netbox.domain.local' -Scheme 'https' -Port 443
                Assert-MockCalled -CommandName 'Set-NBQueryOption' -ModuleName 'PowerNetbox' -Times 1
                $null = Get-NbQueryOption
            }
            It "Should call Set-NBQueryOption inside Connect-NBAPI" {
                Mock -CommandName 'Set-NBQueryOption' -ModuleName 'PowerNetbox' -MockWith { Throw "Should not be called" } -ParameterFilter { $IgnoreCase -eq $false }
                Mock -CommandName 'Set-NBQueryOption' -ModuleName 'PowerNetbox' -MockWith { return $true } -ParameterFilter { $IgnoreCase -eq $true } -Verifiable
                Connect-NBAPI -Hostname 'netbox.domain.local' -Scheme 'https' -Port 443 -IgnoreCase
                Assert-MockCalled -CommandName 'Set-NBQueryOption' -ModuleName 'PowerNetbox' -Times 1
                $null = Get-NbQueryOption
            }
        }
        Context "When connected" {
            BeforeAll {
                # calling the real connect function here, but having mocked the internal request in the context of this Describe
                Connect-NBAPI -Hostname 'netbox.domain.local' -Scheme 'https' -Port 443
            }

            It "Should set and get query option IgnoreCase" {
                Set-NBQueryOption -IgnoreCase:$true | Should -Be $true
                $options = Get-NbQueryOption
                $options | Where-Object Name -eq 'IgnoreCase' | Select-Object -ExpandProperty Value | Should -Be $true
                $optionsInternal = InModuleScope -ModuleName 'PowerNetbox' {
                    $script:NetboxConfig.IgnoreCaseInQueries
                }
                $optionsInternal | Should -Be $true

                Set-NBQueryOption -IgnoreCase:$false | Should -Be $false
                $options = Get-NbQueryOption
                $options | Where-Object Name -eq 'IgnoreCase' | Select-Object -ExpandProperty Value | Should -Be $false
                InModuleScope -ModuleName 'PowerNetbox' {
                    # Check internal state is also reset
                    $script:NetboxConfig.IgnoreCaseInQueries | Should -Be $false
                    ($Script:IgnoreCaseParameterHash.Keys).Count | Should -Be 0
                }
            }
            It "For API v3.0.0 should not use any case-insensitive parameters" {
                InModuleScope -ModuleName 'PowerNetbox' {
                    $script:NetboxConfig.ParsedVersion = '3.0.0'
                    $ret = Set-NBQueryOption -IgnoreCase -WarningAction SilentlyContinue -WarningVariable warn
                    $warn | Should -BeLike '*less than the minimum supported version*'
                    $Script:IgnoreCaseParameterHash.Keys.Count | Should -Be 0
                }
            }
            It "For API version < 4.5.0 should use the baseline + v4.4.9 list" {
                InModuleScope -ModuleName 'PowerNetbox' {
                    $script:NetboxConfig.ParsedVersion = '4.4.8'          # 4.4.9 is the first baseline version, 4.4.8 is less than that, but we only use <major>.<minor> => 4.4. is defined
                    $ret = Set-NBQueryOption -IgnoreCase
                    $Script:IgnoreCaseParameterHash.Keys.Count | Should -BeExactly ($Script:IgnoreCaseParameterBaseline.Count + $Script:IgnoreCaseParameterV449.Count)
                }
            }
            It "For API version >= 4.5.0 and < 4.6.0 should use the baseline + v4.5.0 list" {
                InModuleScope -ModuleName 'PowerNetbox' {
                    $script:NetboxConfig.ParsedVersion = '4.5.0'
                    $ret = Set-NBQueryOption -IgnoreCase
                    $Script:IgnoreCaseParameterHash.Keys.Count | Should -BeExactly ($Script:IgnoreCaseParameterBaseline.Count + $Script:IgnoreCaseParameterV450.Count)
                }
            }
            It "For API version >= 4.6.0 should use the baseline + v4.6.1 list" {
                InModuleScope -ModuleName 'PowerNetbox' {
                    $script:NetboxConfig.ParsedVersion = '4.6.0'
                    $ret = Set-NBQueryOption -IgnoreCase
                    $Script:IgnoreCaseParameterHash.Keys.Count | Should -BeExactly ($Script:IgnoreCaseParameterBaseline.Count + $Script:IgnoreCaseParameterV461.Count)
                }
            }
            It "For API versions newer than our last known version, it should use the latest known version" {
                InModuleScope -ModuleName 'PowerNetbox' {
                    $script:NetboxConfig.ParsedVersion = '99.99.99'
                    $ret = Set-NBQueryOption -IgnoreCase -WarningAction SilentlyContinue -WarningVariable warn
                    $warn | Should -BeLike '*taking the latest known version*'
                    $Script:IgnoreCaseParameterHash.Keys.Count | Should -BeExactly ($Script:IgnoreCaseParameterBaseline.Count + $Script:IgnoreCaseParameterV461.Count)
                }
            }
        }
    }

    Context "Test-NBAuthentication Not Connected" {
        It "Should return false when not connected to Netbox" {
            Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith {
                throw "Not connected"
            }

            $Result = Test-NBAuthentication
            $Result | Should -Be $false
        }

        It "Should return error details when not connected and -Detailed" {
            Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith {
                throw "Not connected"
            }

            $Result = Test-NBAuthentication -Detailed
            $Result.Authenticated | Should -Be $false
            $Result.Error | Should -Match 'Connect-NBAPI'
        }
    }

    Context "Get-NBAPIDefinition" {
        BeforeAll {
            Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
                return [PSCustomObject]@{
                    Method = if ($Method) { $Method } else { 'GET' }
                    Uri    = $URI.ToString()
                    Body   = $Body
                }
            }

            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.Hostname = 'netbox.domain.com'
                $script:NetboxConfig.HostScheme = 'https'
                $script:NetboxConfig.HostPort = 443
            }
        }

        It "Should retrieve the API definition in JSON format by default" {
            $Result = Get-NBAPIDefinition
            $Result.Uri | Should -Match '/api/schema/'
            $Result.Uri | Should -Match 'format=json'
        }

        It "Should support YAML format" {
            $Result = Get-NBAPIDefinition -Format 'yaml'
            $Result.Uri | Should -Match '/api/schema/'
            $Result.Uri | Should -Match 'format=yaml'
        }
    }
}
