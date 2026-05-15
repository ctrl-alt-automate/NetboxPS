param()

BeforeAll {
    Import-Module Pester
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -ErrorAction Stop
    }

    # Store PSScriptRoot for use in InModuleScope
    $script:TestPath = $PSScriptRoot
}

Describe "DCIM Devices Tests" -Tag 'DCIM', 'Devices' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith {
            return $true
        }

        Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
            return [ordered]@{
                'Method' = if ($Method) { $Method } else { 'GET' }
                'Uri'    = $URI.Uri.AbsoluteUri
                'Body'   = if ($Body) { $Body | ConvertTo-Json -Compress } else { $null }
            }
        }

        # Set up module internal state and load choices data
        InModuleScope -ModuleName 'PowerNetbox' -ArgumentList $script:TestPath -ScriptBlock {
            param($TestPath)
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }
    }

    Context "Get-NBDCIMDevice" {
        It "Should request the default number of devices" {
            $Result = Get-NBDCIMDevice

            $Result.Method | Should -Be 'GET'
            # By default, config_context is excluded for performance
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/?omit=config_context'
        }

        It "Should request with a limit and offset" {
            $Result = Get-NBDCIMDevice -Limit 10 -Offset 100

            $Result.Method | Should -Be 'GET'
            # Parameter order in hashtables is not guaranteed, so check all are present
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=100'
            $Result.Uri | Should -Match 'omit=config_context'
        }

        It "Should request with a query" {
            $Result = Get-NBDCIMDevice -Query 'testdevice'

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Match 'q=testdevice'
            $Result.Uri | Should -Match 'omit=config_context'
        }

        It "Should request with an escaped query" {
            $Result = Get-NBDCIMDevice -Query 'test device'

            $Result.Method | Should -Be 'GET'
            # UriBuilder encodes spaces as %20 in the URI
            $Result.Uri | Should -Match 'q=test%20device'
            $Result.Uri | Should -Match 'omit=config_context'
        }

        It "Should request with a name" {
            $Result = Get-NBDCIMDevice -Name 'testdevice'

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Match 'name=testdevice'
            $Result.Uri | Should -Match 'omit=config_context'
        }

        It "Should request with a single ID" {
            $Result = Get-NBDCIMDevice -Id 10

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Match 'dcim/devices/10/'
            $Result.Uri | Should -Match 'omit=config_context'
        }

        It "Should request a device by ID from the pipeline" {
            $Result = [pscustomobject]@{ 'id' = 10 } | Get-NBDCIMDevice

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Match 'dcim/devices/10/'
            $Result.Uri | Should -Match 'omit=config_context'
        }

        It "Should request with multiple IDs" {
            $Result = Get-NBDCIMDevice -Id 10, 12, 15

            $Result | Should -HaveCount 3
            $Result[0].Method | Should -Be 'GET'
            $Result[0].Uri | Should -Match 'dcim/devices/10/'
            $Result[1].Uri | Should -Match 'dcim/devices/12/'
            $Result[2].Uri | Should -Match 'dcim/devices/15/'
            $Result | ForEach-Object { $_.Uri | Should -Match 'omit=config_context' }
        }

        It "Should request a status" {
            $Result = Get-NBDCIMDevice -Status 'Active'

            $Result.Method | Should -Be 'GET'
            # Status value is passed through to API as-is (no client-side validation)
            $Result.Uri | Should -Match 'status=Active'
            $Result.Uri | Should -Match 'omit=config_context'
        }

        It "Should have ValidateSet for Status parameter" {
            # Status parameter now uses ValidateSet for type safety
            $cmd = Get-Command Get-NBDCIMDevice
            $statusParam = $cmd.Parameters['Status']
            $validateSet = $statusParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.ValidValues | Should -Contain 'active'
        }

        It "Should request devices that are a PDU" {
            $Result = Get-NBDCIMDevice -Is_PDU $True

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Match 'is_pdu=True'
            $Result.Uri | Should -Match 'omit=config_context'
        }

        It "Should exclude config_context by default" {
            $Result = Get-NBDCIMDevice

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Match 'omit=config_context'
        }

        It "Should not exclude config_context when IncludeConfigContext is specified" {
            $Result = Get-NBDCIMDevice -IncludeConfigContext

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Not -Match 'omit=config_context'
        }

        It "Should request with Brief mode" {
            $Result = Get-NBDCIMDevice -Brief

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Match 'brief=True'
        }

        It "Should request with specific fields" {
            $Result = Get-NBDCIMDevice -Fields 'id','name','status','site.name'

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Match 'fields=id(%2C|,)name(%2C|,)status(%2C|,)site.name'
        }

        Context "Brief/Fields/Omit mutual exclusion" {
            It "Throws when -Brief and -Fields are both specified" {
                { Get-NBDCIMDevice -Brief -Fields 'id' } |
                    Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
            }

            It "Throws when -Brief and -Omit are both specified" {
                { Get-NBDCIMDevice -Brief -Omit 'comments' } |
                    Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
            }

            It "Throws when -Fields and -Omit are both specified" {
                { Get-NBDCIMDevice -Fields 'id' -Omit 'comments' } |
                    Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
            }

            It "Does not throw when -Brief is specified alone (control)" {
                $Result = Get-NBDCIMDevice -Brief
                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Match 'brief=True'
            }
        }

        Context "Brief/Fields/Omit interaction with IncludeConfigContext" {
            It "With -Brief: URI contains brief=True and no config_context omit" {
                $Result = Get-NBDCIMDevice -Brief
                $Result.Uri | Should -Match 'brief=True'
                $Result.Uri | Should -Not -Match 'omit=config_context'
            }

            It "With -Fields: URI contains the fields parameter and no config_context omit" {
                $Result = Get-NBDCIMDevice -Fields 'id', 'name'
                # Lookahead anchors confirm both field names appear after fields=
                # regardless of order and regardless of whether the comma between
                # values is URL-encoded as %2C on some platforms.
                $Result.Uri | Should -Match 'fields=(?=.*id)(?=.*name)'
                $Result.Uri | Should -Not -Match 'omit=config_context'
            }

            It "With -Omit: URI contains the user's omit value merged with config_context" {
                $Result = Get-NBDCIMDevice -Omit 'comments'
                $Result.Uri | Should -Match 'omit='
                $Result.Uri | Should -Match 'comments'
                $Result.Uri | Should -Match 'config_context'
            }

            It "With -IncludeConfigContext -Brief: URI contains brief=True only (IncludeConfigContext silently ignored)" {
                $Result = Get-NBDCIMDevice -IncludeConfigContext -Brief
                $Result.Uri | Should -Match 'brief=True'
                $Result.Uri | Should -Not -Match 'config_context'
            }

            It "With no projection flags: URI contains the default config_context auto-omit" {
                $Result = Get-NBDCIMDevice
                $Result.Uri | Should -Match 'omit=config_context'
            }
        }
    }

    Context "Get-NBDCIMDeviceType" {
        It "Should request the default number of device types" {
            $Result = Get-NBDCIMDeviceType

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-types/'
        }

        It "Should request with a limit and offset" {
            $Result = Get-NBDCIMDeviceType -Limit 10 -Offset 100

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=100'
        }

        It "Should request with a slug" {
            $Result = Get-NBDCIMDeviceType -Slug 'testdevice'

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-types/?slug=testdevice'
        }

        It "Should request with a single ID" {
            $Result = Get-NBDCIMDeviceType -Id 10

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-types/10/'
        }

        It "Should request a device type that is PDU" {
            $Result = Get-NBDCIMDeviceType -Is_PDU $true

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-types/?is_pdu=True'
        }
    }

    Context "Get-NBDCIMDeviceRole" {
        It "Should request the default number of device roles" {
            $Result = Get-NBDCIMDeviceRole

            Should -Invoke -CommandName "InvokeNetboxRequest" -Times 1 -Scope 'It' -Exactly -ModuleName 'PowerNetbox'

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-roles/'
        }

        It "Should request a device role by Id" {
            $Result = Get-NBDCIMDeviceRole -Id 10

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-roles/10/'
        }

        It "Should request with a slug" {
            $Result = Get-NBDCIMDeviceRole -Slug 'testdevice'

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-roles/?slug=testdevice'
        }

        It "Should request with a name" {
            $Result = Get-NBDCIMDeviceRole -Name 'TestRole'

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-roles/?name=TestRole'
        }

        It "Should request those that are VM role" {
            $Result = Get-NBDCIMDeviceRole -VM_Role $true

            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-roles/?vm_role=True'
        }
    }

    Context "New-NBDCIMDevice" {
        It "Should create a new device" {
            $Result = New-NBDCIMDevice -Name "newdevice" -Device_Role 4 -Device_Type 10 -Site 1 -Face 'front'

            Should -Invoke -CommandName 'InvokeNetboxRequest' -Times 1 -Scope 'It' -Exactly -ModuleName 'PowerNetbox'

            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/'
            # Compare as objects since JSON key order is not guaranteed
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'newdevice'
            $bodyObj.role | Should -Be 4
            $bodyObj.device_type | Should -Be 10
            $bodyObj.site | Should -Be 1
            $bodyObj.face | Should -Be 'front'
        }

        Context "Fractional rack position (#412)" {
            It "Should preserve a half-U position (1.5, not rounded to 2)" {
                $Result = New-NBDCIMDevice -Name 'half-u' -Device_Role 4 -Device_Type 10 -Site 1 -Position 1.5
                ($Result.Body | ConvertFrom-Json).position | Should -Be 1.5
            }
            It "Should accept a whole-number position as a double" {
                $Result = New-NBDCIMDevice -Name 'whole-u' -Device_Role 4 -Device_Type 10 -Site 1 -Position 42
                ($Result.Body | ConvertFrom-Json).position | Should -Be 42
            }
            It "Should reject a position below the 0.5 U floor" {
                { New-NBDCIMDevice -Name 'bad' -Device_Role 4 -Device_Type 10 -Site 1 -Position 0.25 } |
                    Should -Throw
            }
            It "Should type Position as double, not uint16" {
                (Get-Command New-NBDCIMDevice).Parameters['Position'].ParameterType |
                    Should -Be ([double])
            }
        }

        It "Should have ValidateSet for Status parameter" {
            # Status parameter now uses ValidateSet for type safety
            $cmd = Get-Command New-NBDCIMDevice
            $statusParam = $cmd.Parameters['Status']
            $validateSet = $statusParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.ValidValues | Should -Contain 'active'
        }

        It "Should have Single and Bulk parameter sets" {
            $cmd = Get-Command New-NBDCIMDevice
            $cmd.ParameterSets.Name | Should -Contain 'Single'
            $cmd.ParameterSets.Name | Should -Contain 'Bulk'
        }

        It "Should have InputObject parameter for bulk mode" {
            $cmd = Get-Command New-NBDCIMDevice
            $cmd.Parameters.Keys | Should -Contain 'InputObject'
            $inputObjParam = $cmd.Parameters['InputObject']
            $inputObjParam.ParameterSets.Keys | Should -Contain 'Bulk'
        }

        It "Should have BatchSize parameter with validation" {
            $cmd = Get-Command New-NBDCIMDevice
            $cmd.Parameters.Keys | Should -Contain 'BatchSize'
            $batchSizeParam = $cmd.Parameters['BatchSize']
            $validateRange = $batchSizeParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }
            $validateRange | Should -Not -BeNullOrEmpty
            $validateRange.MinRange | Should -Be 1
            $validateRange.MaxRange | Should -Be 1000
        }

        It "Should have Force parameter for bulk mode" {
            $cmd = Get-Command New-NBDCIMDevice
            $cmd.Parameters.Keys | Should -Contain 'Force'
        }

        It "Should use Role alias Device_Role for backwards compatibility" {
            $cmd = Get-Command New-NBDCIMDevice
            $roleParam = $cmd.Parameters['Role']
            $roleParam.Aliases | Should -Contain 'Device_Role'
        }

        It "Should pass -Description through in POST body (#409)" {
            $Result = New-NBDCIMDevice -Name 'srv-desc' -Role 1 -Device_Type 1 -Site 1 -Description 'Edge gateway'
            ($Result.Body | ConvertFrom-Json).description | Should -Be 'Edge gateway'
        }
    }

    Context "Set-NBDCIMDevice" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMDevice" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{
                    'Id'   = $Id
                    'Name' = $Name
                }
            }
        }

        It "Should set a device to a new name" {
            $Result = Set-NBDCIMDevice -Id 1234 -Name 'newtestname' -Confirm:$false

            # Uses Id directly without fetching device first (performance optimization #177)
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/devices/1234/'
            $Result.Body | Should -Be '{"name":"newtestname"}'
        }

        It "Should set a device with new properties" {
            $Result = Set-NBDCIMDevice -Id 1234 -Name 'newtestname' -Cluster 10 -Platform 20 -Site 15 -Confirm:$false

            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/devices/1234/'
            # Compare as objects since JSON key order is not guaranteed
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'newtestname'
            $bodyObj.cluster | Should -Be 10
            $bodyObj.platform | Should -Be 20
            $bodyObj.site | Should -Be 15
        }

        It "Should pass -Description through in PATCH body (#409)" {
            $Result = Set-NBDCIMDevice -Id 1234 -Description 'Primary core switch' -Confirm:$false
            ($Result.Body | ConvertFrom-Json).description | Should -Be 'Primary core switch'
        }

        It "Should clear -Description with empty string (#409)" {
            $Result = Set-NBDCIMDevice -Id 1234 -Description '' -Confirm:$false
            # Empty string is the NetBox convention for clearing a non-nullable string field
            $Result.Body | Should -Match '"description"\s*:\s*""'
        }

        # Note: Array Id parameters are not supported for Set- functions
        # For bulk operations via pipeline, see BulkOperations.Tests.ps1
    }

    Context "Set-NBDCIMDevice null-clearing (#409)" {
        # mkarel requested null-clearing for every uint16/uint64 FK/position
        # param so scripts can unassign Cluster, Platform, Rack, etc. via PATCH.
        # Pattern: [Nullable[T]] lets PowerShell bind $null without throwing,
        # BuildURIComponents passes the key through to $Body, and
        # ConvertTo-Json emits literal null. NetBox then clears the FK.
        It "Should send null when -Platform is explicitly null" {
            $Result = Set-NBDCIMDevice -Id 1234 -Platform $null -Confirm:$false
            $Result.Body | Should -Match '"platform"\s*:\s*null'
        }

        It "Should send null when -Tenant is explicitly null" {
            $Result = Set-NBDCIMDevice -Id 1234 -Tenant $null -Confirm:$false
            $Result.Body | Should -Match '"tenant"\s*:\s*null'
        }

        It "Should send null when -Cluster is explicitly null" {
            $Result = Set-NBDCIMDevice -Id 1234 -Cluster $null -Confirm:$false
            $Result.Body | Should -Match '"cluster"\s*:\s*null'
        }

        It "Should send null when -Rack is explicitly null" {
            $Result = Set-NBDCIMDevice -Id 1234 -Rack $null -Confirm:$false
            $Result.Body | Should -Match '"rack"\s*:\s*null'
        }

        It "Should send null when -Position is explicitly null" {
            $Result = Set-NBDCIMDevice -Id 1234 -Position $null -Confirm:$false
            $Result.Body | Should -Match '"position"\s*:\s*null'
        }

        It "Should send null when -Virtual_Chassis is explicitly null" {
            $Result = Set-NBDCIMDevice -Id 1234 -Virtual_Chassis $null -Confirm:$false
            $Result.Body | Should -Match '"virtual_chassis"\s*:\s*null'
        }

        It "Should send null when -VC_Priority is explicitly null" {
            $Result = Set-NBDCIMDevice -Id 1234 -VC_Priority $null -Confirm:$false
            $Result.Body | Should -Match '"vc_priority"\s*:\s*null'
        }

        It "Should send null when -VC_Position is explicitly null" {
            $Result = Set-NBDCIMDevice -Id 1234 -VC_Position $null -Confirm:$false
            $Result.Body | Should -Match '"vc_position"\s*:\s*null'
        }

        It "Should send null when -Primary_IP4 is explicitly null" {
            $Result = Set-NBDCIMDevice -Id 1234 -Primary_IP4 $null -Confirm:$false
            $Result.Body | Should -Match '"primary_ip4"\s*:\s*null'
        }

        It "Should send null when -Primary_IP6 is explicitly null" {
            $Result = Set-NBDCIMDevice -Id 1234 -Primary_IP6 $null -Confirm:$false
            $Result.Body | Should -Match '"primary_ip6"\s*:\s*null'
        }

        It "Should send null when -Owner is explicitly null" {
            $Result = Set-NBDCIMDevice -Id 1234 -Owner $null -Confirm:$false
            $Result.Body | Should -Match '"owner"\s*:\s*null'
        }

        It "Should still accept a numeric Cluster value (not broken by Nullable)" {
            $Result = Set-NBDCIMDevice -Id 1234 -Cluster 42 -Confirm:$false
            ($Result.Body | ConvertFrom-Json).cluster | Should -Be 42
        }

        It "Should still accept a numeric Position value (not broken by Nullable)" {
            $Result = Set-NBDCIMDevice -Id 1234 -Position 7 -Confirm:$false
            ($Result.Body | ConvertFrom-Json).position | Should -Be 7
        }

        It "Should preserve a fractional Position (2.5, not rounded) (#412)" {
            $Result = Set-NBDCIMDevice -Id 1234 -Position 2.5 -Confirm:$false
            ($Result.Body | ConvertFrom-Json).position | Should -Be 2.5
        }

        It "Should type Position as Nullable[double] (#412)" {
            (Get-Command Set-NBDCIMDevice).Parameters['Position'].ParameterType |
                Should -Be ([System.Nullable[double]])
        }
    }

    Context "Remove-NBDCIMDevice" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMDevice" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{
                    'Id'   = $Id
                    'Name' = $Name
                }
            }
        }

        It "Should remove a device" {
            $Result = Remove-NBDCIMDevice -Id 10 -Confirm:$false

            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/devices/10/'
        }

        # Note: Array Id parameters are not supported for Remove- functions
        # For bulk operations via pipeline, see BulkOperations.Tests.ps1

        It "Should remove devices via bulk mode pipeline" {
            # Pipeline triggers bulk mode - Send-NBBulkRequest handles the DELETE
            # Mock InvokeNetboxRequest to return null (DELETE returns no body)
            Mock -CommandName "InvokeNetboxRequest" -ModuleName PowerNetbox -MockWith {
                return $null
            }

            $items = @(
                [pscustomobject]@{ 'Id' = 30 },
                [pscustomobject]@{ 'Id' = 31 }
            )
            $items | Remove-NBDCIMDevice -Confirm:$false

            # Verify InvokeNetboxRequest was called with DELETE and the bulk endpoint
            Should -Invoke -CommandName "InvokeNetboxRequest" -ModuleName PowerNetbox -ParameterFilter {
                $Method -eq 'DELETE' -and $URI.ToString() -like '*dcim/devices/*' -and $null -ne $Body
            }
        }
    }

    Context "Set-NBDCIMDeviceRole" {
        It "Should update a device role" {
            $Result = Set-NBDCIMDeviceRole -Id 1 -Name 'UpdatedRole' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/device-roles/1/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'UpdatedRole'
        }

        It "Should update a device role with multiple properties" {
            $Result = Set-NBDCIMDeviceRole -Id 2 -Name 'ServerRole' -Color 'ff0000' -VM_Role $true -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/device-roles/2/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'ServerRole'
            $bodyObj.color | Should -Be 'ff0000'
            $bodyObj.vm_role | Should -Be $true
        }
    }

    Context "Set-NBDCIMDeviceType" {
        It "Should update a device type" {
            $Result = Set-NBDCIMDeviceType -Id 1 -Model 'UpdatedModel' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/device-types/1/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.model | Should -Be 'UpdatedModel'
        }

        It "Should update a device type with multiple properties" {
            $Result = Set-NBDCIMDeviceType -Id 3 -Manufacturer 5 -U_Height 2 -Is_Full_Depth $true -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/device-types/3/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.manufacturer | Should -Be 5
            $bodyObj.u_height | Should -Be 2
            $bodyObj.is_full_depth | Should -Be $true
        }
    }

    #region Parameter Validation Tests
    Context "Parameter Validation" {
        It "Should reject invalid Status value for Get-NBDCIMDevice" {
            { Get-NBDCIMDevice -Status 'invalid_status' } | Should -Throw
        }

        It "Should reject invalid Face value for New-NBDCIMDevice" {
            { New-NBDCIMDevice -Name 'test' -Role 1 -Device_Type 1 -Site 1 -Face 'top' -Confirm:$false } | Should -Throw
        }

        It "Should reject PageSize below minimum (0)" {
            { Get-NBDCIMDevice -PageSize 0 } | Should -Throw
        }

        It "Should reject PageSize above maximum (1001)" {
            { Get-NBDCIMDevice -PageSize 1001 } | Should -Throw
        }

        It "Should reject Limit below minimum (0)" {
            { Get-NBDCIMDevice -Limit 0 } | Should -Throw
        }

        It "Should require mandatory Name for New-NBDCIMDevice" {
            { New-NBDCIMDevice -Role 1 -Device_Type 1 -Site 1 -Confirm:$false } | Should -Throw
        }

        It "Should require mandatory Role for New-NBDCIMDevice" {
            { New-NBDCIMDevice -Name 'test' -Device_Type 1 -Site 1 -Confirm:$false } | Should -Throw
        }
    }
    #endregion

    #region WhatIf Tests
    Context "WhatIf Support" {
        $whatIfTestCases = @(
            @{ Command = 'New-NBDCIMDevice'; Parameters = @{ Name = 'whatif-test'; Role = 1; Device_Type = 1; Site = 1 } }
            @{ Command = 'New-NBDCIMDeviceRole'; Parameters = @{ Name = 'whatif-test' } }
            @{ Command = 'New-NBDCIMDeviceType'; Parameters = @{ Manufacturer = 1; Model = 'whatif-test' } }
            @{ Command = 'Set-NBDCIMDevice'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMDeviceRole'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMDeviceType'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMDevice'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMDeviceRole'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMDeviceType'; Parameters = @{ Id = 1 } }
        )

        It 'Should support -WhatIf for <Command>' -TestCases $whatIfTestCases {
            param($Command, $Parameters)
            $splat = $Parameters.Clone()
            $splat.Add('WhatIf', $true)
            $Result = & $Command @splat
            $Result | Should -BeNullOrEmpty
        }
    }
    #endregion

    #region All/PageSize Passthrough Tests
    Context "All/PageSize Passthrough" {
        $allPageSizeTestCases = @(
            @{ Command = 'Get-NBDCIMDevice' }
            @{ Command = 'Get-NBDCIMDeviceRole' }
            @{ Command = 'Get-NBDCIMDeviceType' }
        )

        It 'Should pass -All to InvokeNetboxRequest for <Command>' -TestCases $allPageSizeTestCases {
            param($Command, $Parameters)
            $splat = @{ All = $true }
            if ($Parameters) { $splat += $Parameters }
            & $Command @splat
            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -ParameterFilter {
                $All -eq $true
            }
        }

        It 'Should pass -PageSize to InvokeNetboxRequest for <Command>' -TestCases $allPageSizeTestCases {
            param($Command, $Parameters)
            $splat = @{ All = $true; PageSize = 500 }
            if ($Parameters) { $splat += $Parameters }
            & $Command @splat
            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -ParameterFilter {
                $PageSize -eq 500
            }
        }
    }
    #endregion

    #region Omit Parameter Tests
    Context "Omit Parameter" {
        $omitTestCases = @(
            @{ Command = 'Get-NBDCIMDevice' }
            @{ Command = 'Get-NBDCIMDeviceRole' }
            @{ Command = 'Get-NBDCIMDeviceType' }
        )

        It 'Should pass -Omit to query string for <Command>' -TestCases $omitTestCases {
            param($Command)
            $Result = & $Command -Omit @('comments', 'description')
            $Result.Uri | Should -Match 'omit=comments%2Cdescription'
        }
    }
    #endregion
}
