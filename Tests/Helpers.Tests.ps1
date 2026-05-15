[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

BeforeAll {
    Import-Module Pester
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -ErrorAction Stop
    }

    $script:TestPath = $PSScriptRoot
}

Describe "Helpers tests" -Tag 'Core', 'Helpers' {
    It "Should throw because we are not connected" {
        InModuleScope -ModuleName 'PowerNetbox' {
            { CheckNetboxIsConnected } | Should -Throw
        }
    }

    Context "Building URIBuilder" {
        BeforeAll {
            # Configure the module's NetboxConfig since BuildNewURI now reads from it directly
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.Hostname = 'netbox.domain.com'
                $script:NetboxConfig.HostScheme = 'https'
                $script:NetboxConfig.HostPort = 443
            }
        }

        It "Should give a basic URI object" {
            InModuleScope -ModuleName 'PowerNetbox' {
                BuildNewURI -SkipConnectedCheck | Should -BeOfType [System.UriBuilder]
            }
        }

        It "Should generate a URI using configured hostname" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIBuilder = BuildNewURI -SkipConnectedCheck
                $URIBuilder.Host | Should -BeExactly 'netbox.domain.com'
                $URIBuilder.Path | Should -BeExactly 'api//'
                $URIBuilder.Scheme | Should -Be 'https'
                $URIBuilder.Port | Should -Be 443
                $URIBuilder.URI.AbsoluteUri | Should -Be 'https://netbox.domain.com/api//'
            }
        }

        It "Should generate a URI with segments" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIBuilder = BuildNewURI -Segments 'seg1', 'seg2' -SkipConnectedCheck
                $URIBuilder.Host | Should -BeExactly 'netbox.domain.com'
                $URIBuilder.Path | Should -BeExactly 'api/seg1/seg2/'
                $URIBuilder.URI.AbsoluteUri | Should -BeExactly 'https://netbox.domain.com/api/seg1/seg2/'
            }
        }

        It "Should generate a URI using HTTP when configured" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.HostScheme = 'http'
                $script:NetboxConfig.HostPort = 80
                $URIBuilder = BuildNewURI -Segments 'seg1', 'seg2' -SkipConnectedCheck
                $URIBuilder.Scheme | Should -Be 'http'
                $URIBuilder.Port | Should -Be 80
                $URIBuilder.URI.AbsoluteURI | Should -Be 'http://netbox.domain.com/api/seg1/seg2/'
                # Reset to HTTPS
                $script:NetboxConfig.HostScheme = 'https'
                $script:NetboxConfig.HostPort = 443
            }
        }

        It "Should generate a URI on custom port when configured" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.HostPort = 1234
                $URIBuilder = BuildNewURI -Segments 'seg1', 'seg2' -SkipConnectedCheck
                $URIBuilder.Scheme | Should -Be 'https'
                $URIBuilder.Port | Should -Be 1234
                $URIBuilder.URI.AbsoluteURI | Should -BeExactly 'https://netbox.domain.com:1234/api/seg1/seg2/'
                # Reset to default port
                $script:NetboxConfig.HostPort = 443
            }
        }

        It "Should generate a URI with parameters" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIParameters = @{
                    'param1' = 'paramval1'
                }

                $URIBuilder = BuildNewURI -Segments 'seg1', 'seg2' -Parameters $URIParameters -SkipConnectedCheck
                $URIBuilder.Query | Should -Match 'param1=paramval1'
                $URIBuilder.URI.AbsoluteURI | Should -Match 'https://netbox.domain.com/api/seg1/seg2/\?param1=paramval1'
            }
        }
    }

    Context "Building URI components" {
        It "Should give a basic hashtable" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIComponents = BuildURIComponents -URISegments @('segment1', 'segment2') -ParametersDictionary @{'param1' = 1 }

                $URIComponents | Should -BeOfType [hashtable]
                $URIComponents.Keys.Count | Should -BeExactly 2
                $URIComponents.Keys | Should -Contain "Segments"
                $URIComponents.Keys | Should -Contain "Parameters"
                $URIComponents.Segments | Should -Be @("segment1", "segment2")
                $URIComponents.Parameters.Count | Should -BeExactly 1
                $URIComponents.Parameters | Should -BeOfType [hashtable]
                $URIComponents.Parameters['param1'] | Should -Be 1
            }
        }

        It "Should add a single ID parameter to the segments" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIComponents = BuildURIComponents -URISegments @('segment1', 'segment2') -ParametersDictionary @{'id' = 123 }

                $URIComponents | Should -BeOfType [hashtable]
                $URIComponents.Keys.Count | Should -BeExactly 2
                $URIComponents.Keys | Should -Contain "Segments"
                $URIComponents.Keys | Should -Contain "Parameters"
                $URIComponents.Segments | Should -Be @("segment1", "segment2", '123')
                $URIComponents.Parameters.Count | Should -BeExactly 0
                $URIComponents.Parameters | Should -BeOfType [hashtable]
            }
        }

        It "Should add multiple IDs to the parameters id__in" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIComponents = BuildURIComponents -URISegments @('segment1', 'segment2') -ParametersDictionary @{'id' = "123", "456" }

                $URIComponents | Should -BeOfType [hashtable]
                $URIComponents.Keys.Count | Should -BeExactly 2
                $URIComponents.Keys | Should -Contain "Segments"
                $URIComponents.Keys | Should -Contain "Parameters"
                $URIComponents.Segments | Should -Be @("segment1", "segment2")
                $URIComponents.Parameters.Count | Should -BeExactly 1
                $URIComponents.Parameters | Should -BeOfType [hashtable]
                $URIComponents.Parameters['id__in'] | Should -Be '123,456'
            }
        }

        It "Should skip a particular parameter name" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIComponents = BuildURIComponents -URISegments @('segment1', 'segment2') -ParametersDictionary @{'param1' = 1; 'param2' = 2 } -SkipParameterByName 'param2'

                $URIComponents | Should -BeOfType [hashtable]
                $URIComponents.Keys.Count | Should -BeExactly 2
                $URIComponents.Keys | Should -Contain "Segments"
                $URIComponents.Keys | Should -Contain "Parameters"
                $URIComponents.Segments | Should -Be @("segment1", "segment2")
                $URIComponents.Parameters.Count | Should -BeExactly 1
                $URIComponents.Parameters | Should -BeOfType [hashtable]
                $URIComponents.Parameters['param1'] | Should -Be 1
                $URIComponents.Parameters['param2'] | Should -BeNullOrEmpty
            }
        }

        It "Should add a query (q) parameter" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIComponents = BuildURIComponents -URISegments @('segment1', 'segment2') -ParametersDictionary @{'query' = 'mytestquery' }

                $URIComponents | Should -BeOfType [hashtable]
                $URIComponents.Keys.Count | Should -BeExactly 2
                $URIComponents.Keys | Should -Contain "Segments"
                $URIComponents.Keys | Should -Contain "Parameters"
                $URIComponents.Segments | Should -Be @("segment1", "segment2")
                $URIComponents.Parameters.Count | Should -BeExactly 1
                $URIComponents.Parameters | Should -BeOfType [hashtable]
                $URIComponents.Parameters['q'] | Should -Be 'mytestquery'
            }
        }

        It "Should generate custom field parameters" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIComponents = BuildURIComponents -URISegments @('segment1', 'segment2') -ParametersDictionary @{
                    'CustomFields' = @{
                        'PRTG_Id'     = 1234
                        'Customer_Id' = 'abc'
                    }
                }

                $URIComponents | Should -BeOfType [hashtable]
                $URIComponents.Keys.Count | Should -BeExactly 2
                $URIComponents.Keys | Should -Contain "Segments"
                $URIComponents.Keys | Should -Contain "Parameters"
                $URIComponents.Segments | Should -Be @("segment1", "segment2")
                $URIComponents.Parameters.Count | Should -BeExactly 2
                $URIComponents.Parameters | Should -BeOfType [hashtable]
                $URIComponents.Parameters['cf_prtg_id'] | Should -Be '1234'
                $URIComponents.Parameters['cf_customer_id'] | Should -Be 'abc'
            }
        }
    }

    Context "Invoking request tests" {
        BeforeAll {
            Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
            Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 5 }
            Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }
            Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
                return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
            }
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                return [pscustomobject]@{
                    'Method'      = $Method
                    'Uri'         = $Uri
                    'Headers'     = $Headers
                    'Timeout'     = $Timeout
                    'ContentType' = $ContentType
                    'Body'        = $Body
                    'results'     = 'Only results'
                }
            }

            # Configure NetboxConfig for BuildNewURI
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.Hostname = 'netbox.domain.com'
                $script:NetboxConfig.HostScheme = 'https'
                $script:NetboxConfig.HostPort = 443
            }
        }

        It "Should return direct results instead of the raw request" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIBuilder = BuildNewURI -Segments 'seg1', 'seg2' -SkipConnectedCheck
                $Result = InvokeNetboxRequest -URI $URIBuilder
                $Result | Should -BeOfType [string]
                $Result | Should -BeExactly "Only results"
            }
        }

        It "Should generate a basic request" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIBuilder = BuildNewURI -Segments 'seg1', 'seg2' -SkipConnectedCheck
                $Result = InvokeNetboxRequest -URI $URIBuilder -Raw
                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Be $URIBuilder.Uri.AbsoluteUri
                $Result.Headers | Should -BeOfType [System.Collections.HashTable]
                $Result.Headers.Authorization | Should -Be "Token faketoken"
                $Result.ContentType | Should -Be 'application/json'
                $Result.Body | Should -Be $null
            }
        }

        It "Should generate a POST request with body" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIBuilder = BuildNewURI -Segments 'seg1', 'seg2' -SkipConnectedCheck
                $Result = InvokeNetboxRequest -URI $URIBuilder -Method POST -Body @{
                    'bodyparam1' = 'val1'
                } -Raw
                $Result.Method | Should -Be 'POST'
                $Result.Body | Should -Be '{"bodyparam1":"val1"}'
            }
        }

        It "Should generate a POST request with an extra header" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $Headers = @{
                    'Connection' = 'keep-alive'
                }
                $Body = @{
                    'bodyparam1' = 'val1'
                }
                $URIBuilder = BuildNewURI -Segments 'seg1', 'seg2' -SkipConnectedCheck
                $Result = InvokeNetboxRequest -URI $URIBuilder -Method POST -Body $Body -Headers $Headers -Raw
                $Result.Method | Should -Be 'POST'
                $Result.Body | Should -Be '{"bodyparam1":"val1"}'
                $Result.Headers.Count | Should -BeExactly 2
                $Result.Headers.Authorization | Should -Be "Token faketoken"
                $Result.Headers.Connection | Should -Be "keep-alive"
            }
        }

        It "Should throw because of an invalid method" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URI = BuildNewURI -Segments 'seg1', 'seg2' -SkipConnectedCheck
                { InvokeNetboxRequest -URI $URI -Method 'Fake' } | Should -Throw
            }
        }

        # NOTE: Timeout validation test removed - InvokeNetboxRequest no longer validates timeout range
    }

    # NOTE: ValidateChoice tests removed - function no longer exists in the module
    # The module now passes values directly to the API without client-side validation

    Context "BuildNewURI Edge Cases" {
        BeforeAll {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.Hostname = 'netbox.domain.com'
                $script:NetboxConfig.HostScheme = 'https'
                $script:NetboxConfig.HostPort = 443
            }
        }

        It "Should handle empty segments array" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIBuilder = BuildNewURI -Segments @() -SkipConnectedCheck
                $URIBuilder.Path | Should -BeExactly 'api//'
            }
        }

        It "Should handle null parameters" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIBuilder = BuildNewURI -Segments @('dcim', 'devices') -Parameters $null -SkipConnectedCheck
                $URIBuilder.Path | Should -BeExactly 'api/dcim/devices/'
                $URIBuilder.Query | Should -BeNullOrEmpty
            }
        }

        It "Should URL-encode special characters in parameter values" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIBuilder = BuildNewURI -Segments @('dcim', 'devices') -Parameters @{name='test&value'} -SkipConnectedCheck
                $URIBuilder.Query | Should -Match 'name=test%26value'
            }
        }

        It "Should URL-encode spaces in parameter values" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIBuilder = BuildNewURI -Segments @('dcim', 'devices') -Parameters @{name='my device'} -SkipConnectedCheck
                $URIBuilder.Query | Should -Match 'name=my%20device'
            }
        }

        It "Should handle multiple query parameters" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIBuilder = BuildNewURI -Segments @('dcim', 'devices') -Parameters @{limit=10; offset=20} -SkipConnectedCheck
                $URIBuilder.Query | Should -Match 'limit=10'
                $URIBuilder.Query | Should -Match 'offset=20'
            }
        }

        It "Should handle segments with leading/trailing slashes" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIBuilder = BuildNewURI -Segments @('/dcim/', '/devices/') -SkipConnectedCheck
                $URIBuilder.Path | Should -BeExactly 'api/dcim/devices/'
            }
        }

        It "Should handle numeric segments (IDs)" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIBuilder = BuildNewURI -Segments @('dcim', 'devices', 123) -SkipConnectedCheck
                $URIBuilder.Path | Should -BeExactly 'api/dcim/devices/123/'
            }
        }

        It "Should preserve case in segments" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIBuilder = BuildNewURI -Segments @('DCIM', 'Devices') -SkipConnectedCheck
                $URIBuilder.Path | Should -BeExactly 'api/DCIM/Devices/'
            }
        }
    }

    Context "BuildURIComponents Edge Cases" {
        It "Should handle minimal URISegments" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIComponents = BuildURIComponents -URISegments ([System.Collections.ArrayList]@('api')) -ParametersDictionary @{name='test'}
                $URIComponents.Segments.Count | Should -Be 1
                $URIComponents.Parameters['name'] | Should -Be 'test'
            }
        }

        It "Should handle empty ParametersDictionary" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIComponents = BuildURIComponents -URISegments ([System.Collections.ArrayList]@('dcim', 'devices')) -ParametersDictionary @{}
                $URIComponents.Segments | Should -Be @('dcim', 'devices')
                $URIComponents.Parameters.Count | Should -Be 0
            }
        }

        It "Should handle scalar ID (add to segments)" {
            InModuleScope -ModuleName 'PowerNetbox' {
                # This mimics actual PowerShell parameter binding: -Id 123 binds as scalar
                $URIComponents = BuildURIComponents -URISegments ([System.Collections.ArrayList]@('dcim', 'devices')) -ParametersDictionary @{id=123}
                $URIComponents.Segments | Should -Contain 123
                $URIComponents.Parameters.ContainsKey('id__in') | Should -BeFalse
            }
        }

        It "Should handle three or more IDs" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIComponents = BuildURIComponents -URISegments ([System.Collections.ArrayList]@('dcim', 'devices')) -ParametersDictionary @{id=@(1,2,3)}
                $URIComponents.Parameters['id__in'] | Should -Be '1,2,3'
            }
        }

        It "Should lowercase parameter keys but preserve values" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIComponents = BuildURIComponents -URISegments ([System.Collections.ArrayList]@('dcim')) -ParametersDictionary @{DeviceType='Server'}
                $URIComponents.Parameters.ContainsKey('devicetype') | Should -BeTrue
                $URIComponents.Parameters['devicetype'] | Should -Be 'Server'
            }
        }

        It "Should handle CustomFields with various key casings" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIComponents = BuildURIComponents -URISegments ([System.Collections.ArrayList]@('dcim')) -ParametersDictionary @{
                    CustomFields = @{
                        'PRTG_ID' = 123
                        'customer_Name' = 'Acme'
                    }
                }
                $URIComponents.Parameters['cf_prtg_id'] | Should -Be '123'
                $URIComponents.Parameters['cf_customer_name'] | Should -Be 'Acme'
            }
        }

        It "Should skip multiple parameters by name" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIComponents = BuildURIComponents -URISegments ([System.Collections.ArrayList]@('dcim')) `
                    -ParametersDictionary @{param1=1; param2=2; param3=3} `
                    -SkipParameterByName @('param1', 'param3')
                $URIComponents.Parameters.Count | Should -Be 1
                $URIComponents.Parameters['param2'] | Should -Be 2
            }
        }

        It "Should handle mixed numeric and string IDs" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIComponents = BuildURIComponents -URISegments ([System.Collections.ArrayList]@('dcim', 'devices')) -ParametersDictionary @{id=@(1, '2', 3)}
                $URIComponents.Parameters['id__in'] | Should -Be '1,2,3'
            }
        }

        It "Should add brief=True parameter when Brief switch is set" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIComponents = BuildURIComponents -URISegments ([System.Collections.ArrayList]@('dcim', 'devices')) -ParametersDictionary @{Brief=$true}
                $URIComponents.Parameters['brief'] | Should -Be 'True'
            }
        }

        It "Should not add brief parameter when Brief is false" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIComponents = BuildURIComponents -URISegments ([System.Collections.ArrayList]@('dcim', 'devices')) -ParametersDictionary @{Brief=$false}
                $URIComponents.Parameters.ContainsKey('brief') | Should -BeFalse
            }
        }

        It "Should add fields parameter as comma-separated list" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIComponents = BuildURIComponents -URISegments ([System.Collections.ArrayList]@('dcim', 'devices')) -ParametersDictionary @{Fields=@('id','name','status','site.name')}
                $URIComponents.Parameters['fields'] | Should -Be 'id,name,status,site.name'
            }
        }

        It "Should handle single field in Fields parameter" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIComponents = BuildURIComponents -URISegments ([System.Collections.ArrayList]@('dcim', 'devices')) -ParametersDictionary @{Fields=@('name')}
                $URIComponents.Parameters['fields'] | Should -Be 'name'
            }
        }

        It "Should add omit parameter as comma-separated list" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIComponents = BuildURIComponents -URISegments ([System.Collections.ArrayList]@('dcim', 'devices')) -ParametersDictionary @{Omit=@('config_context','comments')}
                $URIComponents.Parameters['omit'] | Should -Be 'config_context,comments'
            }
        }

        It "Should handle single value in Omit parameter" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $URIComponents = BuildURIComponents -URISegments ([System.Collections.ArrayList]@('dcim', 'devices')) -ParametersDictionary @{Omit=@('config_context')}
                $URIComponents.Parameters['omit'] | Should -Be 'config_context'
            }
        }

        It "Should emit warning when Query parameter is used" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $warnings = $null
                $URIComponents = BuildURIComponents -URISegments ([System.Collections.ArrayList]@('dcim', 'devices')) -ParametersDictionary @{Query='test'} -WarningVariable warnings
                $warnings | Should -Not -BeNullOrEmpty
                $warnings | Should -Match 'slow on large datasets'
            }
        }
    }

    Context "InvokeNetboxRequest Pagination" {
        BeforeAll {
            Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
            Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 5 }
            Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }
            Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
                return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
            }

            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.Hostname = 'netbox.domain.com'
                $script:NetboxConfig.HostScheme = 'https'
                $script:NetboxConfig.HostPort = 443
                $script:NetboxConfig.BranchStack = $null
            }
        }

        It "Should fetch all pages when using -All" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:pageCount = 0
                Mock -CommandName 'Invoke-RestMethod' -MockWith {
                    $script:pageCount++
                    if ($script:pageCount -eq 1) {
                        return @{
                            count = 3
                            next = 'https://netbox.domain.com/api/dcim/devices/?limit=1&offset=1'
                            previous = $null
                            results = @(@{id=1; name='device1'})
                        }
                    } elseif ($script:pageCount -eq 2) {
                        return @{
                            count = 3
                            next = 'https://netbox.domain.com/api/dcim/devices/?limit=1&offset=2'
                            previous = 'https://netbox.domain.com/api/dcim/devices/?limit=1'
                            results = @(@{id=2; name='device2'})
                        }
                    } else {
                        return @{
                            count = 3
                            next = $null
                            previous = 'https://netbox.domain.com/api/dcim/devices/?limit=1&offset=1'
                            results = @(@{id=3; name='device3'})
                        }
                    }
                }

                $URI = BuildNewURI -Segments 'dcim', 'devices' -SkipConnectedCheck
                $results = InvokeNetboxRequest -URI $URI -All -PageSize 1

                $results.Count | Should -Be 3
                $results[0].name | Should -Be 'device1'
                $results[1].name | Should -Be 'device2'
                $results[2].name | Should -Be 'device3'
            }
        }

        It "Should return empty array when no results" {
            InModuleScope -ModuleName 'PowerNetbox' {
                Mock -CommandName 'Invoke-RestMethod' -MockWith {
                    return @{
                        count = 0
                        next = $null
                        previous = $null
                        results = @()
                    }
                }

                $URI = BuildNewURI -Segments 'dcim', 'devices' -SkipConnectedCheck
                $results = InvokeNetboxRequest -URI $URI

                $results | Should -BeNullOrEmpty
            }
        }

        It "Should return Raw response with -All -Raw" {
            InModuleScope -ModuleName 'PowerNetbox' {
                Mock -CommandName 'Invoke-RestMethod' -MockWith {
                    return @{
                        count = 1
                        next = $null
                        previous = $null
                        results = @(@{id=1; name='device1'})
                    }
                }

                $URI = BuildNewURI -Segments 'dcim', 'devices' -SkipConnectedCheck
                $result = InvokeNetboxRequest -URI $URI -All -Raw

                $result.count | Should -Be 1
                $result.next | Should -BeNullOrEmpty
                $result.results | Should -Not -BeNullOrEmpty
            }
        }

        Context "Pagination next-URL origin validation (Tier 2 security review - TM-1/IV-1)" {
            It "Should throw when 'next' points to a different host" {
                InModuleScope -ModuleName 'PowerNetbox' {
                    Mock -CommandName 'Invoke-RestMethod' -MockWith {
                        return @{
                            count = 2
                            next = 'https://attacker.example.com/api/dcim/devices/?limit=1&offset=1'
                            previous = $null
                            results = @(@{id=1; name='device1'})
                        }
                    }

                    $URI = BuildNewURI -Segments 'dcim', 'devices' -SkipConnectedCheck
                    { InvokeNetboxRequest -URI $URI -All -PageSize 1 } |
                        Should -Throw -ExpectedMessage '*Refusing to follow pagination*different origin*attacker.example.com*'
                }
            }

            It "Should throw when 'next' downgrades scheme from https to http" {
                InModuleScope -ModuleName 'PowerNetbox' {
                    Mock -CommandName 'Invoke-RestMethod' -MockWith {
                        return @{
                            count = 2
                            next = 'http://netbox.domain.com/api/dcim/devices/?limit=1&offset=1'
                            previous = $null
                            results = @(@{id=1; name='device1'})
                        }
                    }

                    $URI = BuildNewURI -Segments 'dcim', 'devices' -SkipConnectedCheck
                    { InvokeNetboxRequest -URI $URI -All -PageSize 1 } |
                        Should -Throw -ExpectedMessage '*Refusing to follow pagination*'
                }
            }

            It "Should throw when 'next' changes the port" {
                InModuleScope -ModuleName 'PowerNetbox' {
                    Mock -CommandName 'Invoke-RestMethod' -MockWith {
                        return @{
                            count = 2
                            next = 'https://netbox.domain.com:8443/api/dcim/devices/?limit=1&offset=1'
                            previous = $null
                            results = @(@{id=1; name='device1'})
                        }
                    }

                    $URI = BuildNewURI -Segments 'dcim', 'devices' -SkipConnectedCheck
                    { InvokeNetboxRequest -URI $URI -All -PageSize 1 } |
                        Should -Throw -ExpectedMessage '*Refusing to follow pagination*'
                }
            }

            It "Should allow 'next' with matching scheme, host, and port" {
                InModuleScope -ModuleName 'PowerNetbox' {
                    $script:sameOriginPages = 0
                    Mock -CommandName 'Invoke-RestMethod' -MockWith {
                        $script:sameOriginPages++
                        if ($script:sameOriginPages -eq 1) {
                            return @{
                                count = 2
                                next = 'https://netbox.domain.com/api/dcim/devices/?limit=1&offset=1'
                                previous = $null
                                results = @(@{id=1; name='device1'})
                            }
                        }
                        return @{
                            count = 2
                            next = $null
                            previous = $null
                            results = @(@{id=2; name='device2'})
                        }
                    }

                    $URI = BuildNewURI -Segments 'dcim', 'devices' -SkipConnectedCheck
                    $results = InvokeNetboxRequest -URI $URI -All -PageSize 1
                    $results.Count | Should -Be 2
                }
            }

            It "Should allow 'next' when original URI has explicit default port but 'next' omits it" {
                # Edge case (Gemini review round 1): URI constructed with
                # explicit port 443, server returns 'next' without the port.
                # Both should normalise to the same origin via GetLeftPart.
                InModuleScope -ModuleName 'PowerNetbox' {
                    $script:edgeCasePages = 0
                    Mock -CommandName 'Invoke-RestMethod' -MockWith {
                        $script:edgeCasePages++
                        if ($script:edgeCasePages -eq 1) {
                            return @{
                                count = 2
                                # No explicit port - UriBuilder fills 443 but GetLeftPart omits it
                                next = 'https://netbox.domain.com/api/dcim/devices/?limit=1&offset=1'
                                previous = $null
                                results = @(@{id=1; name='device1'})
                            }
                        }
                        return @{
                            count = 2
                            next = $null
                            previous = $null
                            results = @(@{id=2; name='device2'})
                        }
                    }

                    # Construct URI with explicit port 443 to exercise the edge case
                    $URI = [System.UriBuilder]::new('https', 'netbox.domain.com', 443, '/api/dcim/devices/')
                    $results = InvokeNetboxRequest -URI $URI -All -PageSize 1
                    $results.Count | Should -Be 2
                }
            }
        }
    }

    Context "InvokeNetboxRequest Error Handling" {
        BeforeAll {
            Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
            Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 5 }
            Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }
            Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
                return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
            }

            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.Hostname = 'netbox.domain.com'
                $script:NetboxConfig.HostScheme = 'https'
                $script:NetboxConfig.HostPort = 443
            }
        }

        It "Should include Authorization header with Token" {
            InModuleScope -ModuleName 'PowerNetbox' {
                Mock -CommandName 'Invoke-RestMethod' -MockWith {
                    return @{ results = @() }
                } -Verifiable

                $URI = BuildNewURI -Segments 'dcim', 'devices' -SkipConnectedCheck
                InvokeNetboxRequest -URI $URI

                Should -Invoke Invoke-RestMethod -ModuleName 'PowerNetbox' -ParameterFilter {
                    $Headers.Authorization -eq 'Token faketoken'
                }
            }
        }

        It "Should serialize body with correct depth" {
            InModuleScope -ModuleName 'PowerNetbox' {
                Mock -CommandName 'Invoke-RestMethod' -MockWith {
                    return @{ id = 1 }
                }

                $nestedBody = @{
                    level1 = @{
                        level2 = @{
                            level3 = @{
                                value = 'deep'
                            }
                        }
                    }
                }

                $URI = BuildNewURI -Segments 'dcim', 'devices' -SkipConnectedCheck
                $result = InvokeNetboxRequest -URI $URI -Method POST -Body $nestedBody

                Should -Invoke Invoke-RestMethod -ModuleName 'PowerNetbox' -ParameterFilter {
                    $Body -match 'deep'
                }
            }
        }

        It "Should parse JSON error body from ErrorDetails.Message (PowerShell Core fix)" {
            # Issue #164: In PowerShell Core 7.x, the response body is available in ErrorDetails.Message
            # because HttpResponseMessage is disposed before we can read it from Exception.Response
            InModuleScope -ModuleName 'PowerNetbox' {
                # Create an error that simulates PowerShell Core behavior with ErrorDetails populated
                Mock -CommandName 'Invoke-RestMethod' -MockWith {
                    # PowerShell way to create error with ErrorDetails
                    $errorMsg = '{"address": ["Duplicate IP address found in global table"]}'
                    Write-Error -Message "Bad Request" -ErrorId "WebCmdletWebResponseException" -Category InvalidOperation -ErrorAction Stop -TargetObject $errorMsg
                }

                $URI = BuildNewURI -Segments 'ipam', 'ip-addresses' -SkipConnectedCheck
                $body = @{ address = '10.0.0.1/24' }

                $thrownError = $null
                try {
                    InvokeNetboxRequest -URI $URI -Method POST -Body $body
                } catch {
                    $thrownError = $_
                }

                # Verify an error was thrown
                $thrownError | Should -Not -BeNullOrEmpty
            }
        }

        It "Should parse JSON error with detail field" {
            # Test that 'detail' field is correctly extracted from JSON errors
            InModuleScope -ModuleName 'PowerNetbox' {
                Mock -CommandName 'Invoke-RestMethod' -MockWith {
                    throw [System.Exception]::new('{"detail": "Authentication credentials were not provided."}')
                }

                $URI = BuildNewURI -Segments 'dcim', 'devices' -SkipConnectedCheck

                $thrownError = $null
                try {
                    InvokeNetboxRequest -URI $URI
                } catch {
                    $thrownError = $_
                }

                $thrownError | Should -Not -BeNullOrEmpty
                # The message should contain the parsed detail
                $thrownError.Exception.Message | Should -Match "Authentication credentials"
            }
        }
    }

    Context "InvokeNetboxRequest Branch Context" {
        BeforeAll {
            Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
            Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 5 }
            Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }
            Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
                return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
            }

            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.Hostname = 'netbox.domain.com'
                $script:NetboxConfig.HostScheme = 'https'
                $script:NetboxConfig.HostPort = 443
            }
        }

        It "Should add X-NetBox-Branch header when Branch is specified" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.BranchStack = $null
                Mock -CommandName 'Invoke-RestMethod' -MockWith {
                    return @{ results = @() }
                }

                $URI = BuildNewURI -Segments 'dcim', 'devices' -SkipConnectedCheck
                InvokeNetboxRequest -URI $URI -Branch 'my-branch'

                Should -Invoke Invoke-RestMethod -ModuleName 'PowerNetbox' -ParameterFilter {
                    $Headers['X-NetBox-Branch'] -eq 'my-branch'
                }
            }
        }

        It "Should use BranchStack when no explicit Branch" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.BranchStack = [System.Collections.Generic.Stack[string]]::new()
                $script:NetboxConfig.BranchStack.Push('stack-branch')

                Mock -CommandName 'Invoke-RestMethod' -MockWith {
                    return @{ results = @() }
                }

                $URI = BuildNewURI -Segments 'dcim', 'devices' -SkipConnectedCheck
                InvokeNetboxRequest -URI $URI

                Should -Invoke Invoke-RestMethod -ModuleName 'PowerNetbox' -ParameterFilter {
                    $Headers['X-NetBox-Branch'] -eq 'stack-branch'
                }

                # Cleanup
                $script:NetboxConfig.BranchStack = $null
            }
        }

        It "Should not add X-NetBox-Branch when no branch context" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.BranchStack = $null
                Mock -CommandName 'Invoke-RestMethod' -MockWith {
                    return @{ results = @() }
                }

                $URI = BuildNewURI -Segments 'dcim', 'devices' -SkipConnectedCheck
                InvokeNetboxRequest -URI $URI

                Should -Invoke Invoke-RestMethod -ModuleName 'PowerNetbox' -ParameterFilter {
                    -not $Headers.ContainsKey('X-NetBox-Branch')
                }
            }
        }
    }

    Context "ConvertTo-NetboxVersion" {
        It "Should parse standard three-part version" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = ConvertTo-NetboxVersion -VersionString "4.4.8"
                $result | Should -BeOfType [System.Version]
                $result | Should -Be ([version]"4.4.8")
            }
        }

        It "Should parse Docker-suffixed version" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = ConvertTo-NetboxVersion -VersionString "4.2.9-Docker-3.2.1"
                $result | Should -Be ([version]"4.2.9")
            }
        }

        It "Should parse two-part version" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = ConvertTo-NetboxVersion -VersionString "4.4"
                $result | Should -Be ([version]"4.4")
            }
        }

        It "Should parse version with v prefix" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = ConvertTo-NetboxVersion -VersionString "v4.4.9-dev"
                $result | Should -Be ([version]"4.4.9")
            }
        }

        It "Should return null for null input" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = ConvertTo-NetboxVersion -VersionString $null
                $result | Should -BeNullOrEmpty
            }
        }

        It "Should return null for empty string" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = ConvertTo-NetboxVersion -VersionString ""
                $result | Should -BeNullOrEmpty
            }
        }

        It "Should return null for whitespace" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = ConvertTo-NetboxVersion -VersionString "   "
                $result | Should -BeNullOrEmpty
            }
        }

        It "Should return null for invalid format" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = ConvertTo-NetboxVersion -VersionString "invalid"
                $result | Should -BeNullOrEmpty
            }
        }

        It "Should return null for single number" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = ConvertTo-NetboxVersion -VersionString "4"
                $result | Should -BeNullOrEmpty
            }
        }

        It "Should support pipeline input" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = "4.4.8" | ConvertTo-NetboxVersion
                $result | Should -Be ([version]"4.4.8")
            }
        }

        It "Should handle version with build metadata" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = ConvertTo-NetboxVersion -VersionString "4.4.9+build.123"
                $result | Should -Be ([version]"4.4.9")
            }
        }
    }

    Context "Parameter Set Validation" {
        # Test that parameter sets are properly mutually exclusive
        # Functions with ById and Query parameter sets should not allow both simultaneously

        It "Get-NBIPAMAddress should not allow both Id and Query parameters" {
            # When a function has ById and Query parameter sets,
            # using both should cause PowerShell to error due to ambiguous parameter set
            { Get-NBIPAMAddress -Id 10 -Query 'test' } | Should -Throw -Because "Id (ByID set) and Query (Query set) are mutually exclusive"
        }

        It "Get-NBIPAMAddress should not allow both Id and Address parameters" {
            # Id is in ByID parameter set, Address is in Query parameter set
            { Get-NBIPAMAddress -Id 10 -Address '192.168.1.1' } | Should -Throw -Because "Id (ByID set) and Address (Query set) are mutually exclusive"
        }

        It "Get-NBIPAMAddress should allow Id parameter alone" {
            # Should not throw - Id alone is valid (ByID parameter set)
            InModuleScope -ModuleName 'PowerNetbox' {
                $command = Get-Command Get-NBIPAMAddress
                $parameterSets = $command.ParameterSets
                $byIdSet = $parameterSets | Where-Object { $_.Name -eq 'ByID' }
                $byIdSet | Should -Not -BeNullOrEmpty -Because "ByID parameter set should exist"
                $byIdSet.Parameters.Name | Should -Contain 'Id'
            }
        }

        It "Get-NBIPAMAddress should allow Query parameter alone" {
            # Should not throw - Query alone is valid (Query parameter set)
            InModuleScope -ModuleName 'PowerNetbox' {
                $command = Get-Command Get-NBIPAMAddress
                $parameterSets = $command.ParameterSets
                $querySet = $parameterSets | Where-Object { $_.Name -eq 'Query' }
                $querySet | Should -Not -BeNullOrEmpty -Because "Query parameter set should exist"
                $querySet.Parameters.Name | Should -Contain 'Query'
            }
        }

        It "Get-NBIPAMAddress should have correct default parameter set" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $command = Get-Command Get-NBIPAMAddress
                $command.DefaultParameterSet | Should -Be 'Query'
            }
        }
    }

    Context "AssertNBMutualExclusiveParam" {
        It "Does not throw when zero parameters from the list are bound" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $bound = @{}
                { AssertNBMutualExclusiveParam -BoundParameters $bound -Parameters 'Brief', 'Fields', 'Omit' } |
                    Should -Not -Throw
            }
        }

        It "Does not throw when exactly one parameter from the list is bound" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $bound = @{ Brief = $true }
                { AssertNBMutualExclusiveParam -BoundParameters $bound -Parameters 'Brief', 'Fields', 'Omit' } |
                    Should -Not -Throw
            }
        }

        It "Throws ParameterBindingException when two parameters are bound" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $bound = @{ Brief = $true; Fields = @('id', 'name') }
                { AssertNBMutualExclusiveParam -BoundParameters $bound -Parameters 'Brief', 'Fields', 'Omit' } |
                    Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
            }
        }

        It "Throws with a message naming all conflicting parameters when three are bound" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $bound = @{ Brief = $true; Fields = @('id'); Omit = @('x') }
                try {
                    AssertNBMutualExclusiveParam -BoundParameters $bound -Parameters 'Brief', 'Fields', 'Omit'
                    throw "Expected an exception but none was thrown"
                } catch [System.Management.Automation.ParameterBindingException] {
                    $_.Exception.Message | Should -Match '-Brief'
                    $_.Exception.Message | Should -Match '-Fields'
                    $_.Exception.Message | Should -Match '-Omit'
                    $_.Exception.Message | Should -Match 'mutually exclusive'
                }
            }
        }

        It "Appends HelpHint to the exception message when supplied" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $bound = @{ Brief = $true; Fields = @('id') }
                try {
                    AssertNBMutualExclusiveParam -BoundParameters $bound -Parameters 'Brief', 'Fields', 'Omit' -HelpHint 'See Get-Help for alternatives.'
                    throw "Expected an exception but none was thrown"
                } catch [System.Management.Automation.ParameterBindingException] {
                    $_.Exception.Message | Should -Match 'See Get-Help for alternatives\.'
                }
            }
        }

        It "Rejects calls with fewer than 2 parameter names via ValidateCount" {
            InModuleScope -ModuleName 'PowerNetbox' {
                { AssertNBMutualExclusiveParam -BoundParameters @{} -Parameters 'Brief' } |
                    Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
            }
        }

        It "Works with lowercase parameter names when Parameters list also uses lowercase" {
            # PSBoundParameters (and plain Hashtable) use OrdinalIgnoreCase comparisons,
            # so key lookup is case-insensitive regardless of the dictionary-key casing.
            # The helper delegates case behavior to the dictionary; when caller and
            # dictionary agree on casing the comparison trivially succeeds.
            InModuleScope -ModuleName 'PowerNetbox' {
                $bound = @{ brief = $true; fields = @('id') }
                { AssertNBMutualExclusiveParam -BoundParameters $bound -Parameters 'brief', 'fields' } |
                    Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
            }
        }

        It "Accepts a generic Dictionary as BoundParameters" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $bound = [System.Collections.Generic.Dictionary[string, object]]::new()
                $bound['Brief'] = $true
                $bound['Fields'] = @('id')
                { AssertNBMutualExclusiveParam -BoundParameters $bound -Parameters 'Brief', 'Fields', 'Omit' } |
                    Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
            }
        }

        It "Does not throw for empty or null BoundParameters" {
            InModuleScope -ModuleName 'PowerNetbox' {
                { AssertNBMutualExclusiveParam -BoundParameters @{} -Parameters 'Brief', 'Fields', 'Omit' } |
                    Should -Not -Throw
            }
        }

        It "Ignores parameters outside the checked list" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $bound = @{ Brief = $true; Limit = 10; Offset = 100 }
                { AssertNBMutualExclusiveParam -BoundParameters $bound -Parameters 'Brief', 'Fields', 'Omit' } |
                    Should -Not -Throw
            }
        }
    }

    Context "Register-NBArgumentCompleters does not trigger the module auto-loader (#418)" {
        It "Loads exactly one PowerNetbox module after import" {
            # The regression: Get-Command -Module PowerNetbox inside
            # Register-NBArgumentCompleters side-loaded a second copy.
            (Get-Module PowerNetbox).Count | Should -Be 1
        }

        It "Resolves exported names from the manifest, never via Get-Command -Module" {
            InModuleScope -ModuleName 'PowerNetbox' {
                Mock Register-ArgumentCompleter -MockWith { }
                Mock Get-Command -MockWith { throw 'Get-Command must not be used to enumerate the module (auto-load risk, #418)' }

                { Register-NBArgumentCompleters } | Should -Not -Throw
                Should -Not -Invoke Get-Command
                Should -Invoke Register-ArgumentCompleter -Scope It
            }
        }
    }
}
