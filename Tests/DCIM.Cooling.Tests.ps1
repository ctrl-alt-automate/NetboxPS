<#
.SYNOPSIS
    Unit tests for DCIM cooling infrastructure functions (NetBox 4.7+).

.DESCRIPTION
    Tests for the facility-level cooling endpoints introduced in NetBox 4.7:
    CoolingSources (/api/dcim/cooling-sources/) and CoolingFeeds
    (/api/dcim/cooling-feeds/). Mocks at the InvokeNetboxRequest level.
#>

param()

BeforeAll {
    Import-Module Pester
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -ErrorAction Stop
    }
}

Describe "DCIM Cooling Tests" -Tag 'DCIM' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
        Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
            return [ordered]@{
                'Method' = if ($Method) { $Method } else { 'GET' }
                'Uri'    = $URI.Uri.AbsoluteUri
                'Body'   = if ($Body) { $Body | ConvertTo-Json -Compress -Depth 10 } else { $null }
            }
        }

        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }
    }

    #region CoolingSources
    Context "Get-NBDCIMCoolingSource" {
        It "Should request the list endpoint" {
            $Result = Get-NBDCIMCoolingSource
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-sources/'
        }

        It "Should request a cooling source by ID" {
            $Result = Get-NBDCIMCoolingSource -Id 5
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-sources/5/'
        }

        It "Should fan out multiple IDs to one detail request each" {
            $Result = @(Get-NBDCIMCoolingSource -Id 5, 6)
            $Result.Count | Should -Be 2
            $Result[0].Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-sources/5/'
            $Result[1].Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-sources/6/'
        }

        It "Should pass -Brief through on the detail endpoint" {
            $Result = Get-NBDCIMCoolingSource -Id 5 -Brief
            $Result.Uri | Should -Match '/api/dcim/cooling-sources/5/\?brief=True'
        }

        It "Should filter by name" {
            $Result = Get-NBDCIMCoolingSource -Name 'CH-01'
            $Result.Uri | Should -Match 'name=CH-01'
        }

        It "Should emit repeat-key site_id filters" {
            $Result = Get-NBDCIMCoolingSource -Site_Id 1, 2
            $Result.Uri | Should -Match 'site_id=1'
            $Result.Uri | Should -Match 'site_id=2'
        }

        It "Should filter by site slug" {
            $Result = Get-NBDCIMCoolingSource -Site 'dc-1'
            $Result.Uri | Should -Match 'site=dc-1'
        }

        It "Should filter by location_id" {
            $Result = Get-NBDCIMCoolingSource -Location_Id 3
            $Result.Uri | Should -Match 'location_id=3'
        }

        It "Should filter by location slug" {
            $Result = Get-NBDCIMCoolingSource -Location 'room-a'
            $Result.Uri | Should -Match 'location=room-a'
        }

        It "Should filter by region_id" {
            $Result = Get-NBDCIMCoolingSource -Region_Id 4
            $Result.Uri | Should -Match 'region_id=4'
        }

        It "Should filter by region slug" {
            $Result = Get-NBDCIMCoolingSource -Region 'emea'
            $Result.Uri | Should -Match 'region=emea'
        }

        It "Should filter by site_group_id" {
            $Result = Get-NBDCIMCoolingSource -Site_Group_Id 8
            $Result.Uri | Should -Match 'site_group_id=8'
        }

        It "Should filter by type" {
            $Result = Get-NBDCIMCoolingSource -Type chiller
            $Result.Uri | Should -Match 'type=chiller'
        }

        It "Should emit repeat-key type filters" {
            $Result = Get-NBDCIMCoolingSource -Type chiller, crac
            $Result.Uri | Should -Match 'type=chiller'
            $Result.Uri | Should -Match 'type=crac'
        }

        It "Should reject an unknown type" {
            { Get-NBDCIMCoolingSource -Type 'fridge' } | Should -Throw
        }

        It "Should filter by status" {
            $Result = Get-NBDCIMCoolingSource -Status active
            $Result.Uri | Should -Match 'status=active'
        }

        It "Should reject an unknown status" {
            { Get-NBDCIMCoolingSource -Status 'broken' } | Should -Throw
        }

        It "Should filter by fluid_type" {
            $Result = Get-NBDCIMCoolingSource -Fluid_Type water-glycol
            $Result.Uri | Should -Match 'fluid_type=water-glycol'
        }

        It "Should filter by cooling_capacity" {
            $Result = Get-NBDCIMCoolingSource -Cooling_Capacity 250.5
            $Result.Uri | Should -Match 'cooling_capacity=250\.5'
        }

        It "Should filter by description" {
            $Result = Get-NBDCIMCoolingSource -Description 'primary'
            $Result.Uri | Should -Match 'description=primary'
        }

        It "Should filter by owner_id" {
            $Result = Get-NBDCIMCoolingSource -Owner_Id 9
            $Result.Uri | Should -Match 'owner_id=9'
        }

        It "Should filter by tag" {
            $Result = Get-NBDCIMCoolingSource -Tag 'critical'
            $Result.Uri | Should -Match 'tag=critical'
        }

        It "Should send -Query as q" {
            $Result = Get-NBDCIMCoolingSource -Query 'chill' -WarningAction SilentlyContinue
            $Result.Uri | Should -Match 'q=chill'
        }

        It "Should pass limit and offset" {
            $Result = Get-NBDCIMCoolingSource -Limit 10 -Offset 20
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=20'
        }

        It "Should accept an offset above uint16 range" {
            $Result = Get-NBDCIMCoolingSource -Offset 70000
            $Result.Uri | Should -Match 'offset=70000'
        }

        It "Should pass fields and omit" {
            $Result = Get-NBDCIMCoolingSource -Fields 'id', 'name'
            $Result.Uri | Should -Match 'fields=id(,|%2C)name'
            $Result = Get-NBDCIMCoolingSource -Omit 'comments'
            $Result.Uri | Should -Match 'omit=comments'
        }

        It "Should reject -Brief together with -Fields" {
            { Get-NBDCIMCoolingSource -Brief -Fields 'id' } | Should -Throw
        }
    }

    Context "New-NBDCIMCoolingSource" {
        It "Should POST the required fields" {
            $Result = New-NBDCIMCoolingSource -Site 1 -Name 'CH-01' -Type chiller
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-sources/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.site | Should -Be 1
            $bodyObj.name | Should -Be 'CH-01'
            $bodyObj.type | Should -Be 'chiller'
        }

        It "Should require Site, Name and Type" {
            $cmd = Get-Command New-NBDCIMCoolingSource
            foreach ($p in 'Site', 'Name', 'Type') {
                $attr = $cmd.Parameters[$p].Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
                $attr.Mandatory | Should -BeTrue -Because "$p is required by the API"
            }
        }

        It "Should send every optional field" {
            $Result = New-NBDCIMCoolingSource -Site 1 -Name 'CH-02' -Type crah -Location 3 -Status planned `
                -Fluid_Type refrigerant -Cooling_Capacity 500.25 -Description 'desc' -Owner 7 -Comments 'notes' `
                -Tags 'a', 'b' -Custom_Fields @{ vendor = 'ACME' }
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.location | Should -Be 3
            $bodyObj.status | Should -Be 'planned'
            $bodyObj.fluid_type | Should -Be 'refrigerant'
            $bodyObj.cooling_capacity | Should -Be 500.25
            $bodyObj.description | Should -Be 'desc'
            $bodyObj.owner | Should -Be 7
            $bodyObj.comments | Should -Be 'notes'
            $bodyObj.tags | Should -Be @('a', 'b')
            $bodyObj.custom_fields.vendor | Should -Be 'ACME'
        }

        It "Should accept mixed tag IDs and names" {
            $Result = New-NBDCIMCoolingSource -Site 1 -Name 'CH-03' -Type crac -Tags 1, 'prod'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.tags.Count | Should -Be 2
        }

        It "Should reject an unknown type" {
            { New-NBDCIMCoolingSource -Site 1 -Name 'X' -Type 'fridge' } | Should -Throw
        }

        It "Should reject an unknown fluid type" {
            { New-NBDCIMCoolingSource -Site 1 -Name 'X' -Type chiller -Fluid_Type 'beer' } | Should -Throw
        }

        It "Should not call the API with -WhatIf" {
            New-NBDCIMCoolingSource -Site 1 -Name 'X' -Type chiller -WhatIf
            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -Times 0 -Exactly
        }
    }

    Context "Set-NBDCIMCoolingSource" {
        It "Should PATCH the detail endpoint" {
            $Result = Set-NBDCIMCoolingSource -Id 5 -Status offline -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-sources/5/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.status | Should -Be 'offline'
            $bodyObj.PSObject.Properties.Name | Should -Not -Contain 'id'
        }

        It "Should send updated scalar fields" {
            $Result = Set-NBDCIMCoolingSource -Id 5 -Site 2 -Location 4 -Name 'CH-01b' -Type dry-cooler `
                -Fluid_Type dielectric -Cooling_Capacity 750 -Description 'd' -Owner 3 -Comments 'c' `
                -Tags 'x' -Custom_Fields @{ k = 'v' } -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.site | Should -Be 2
            $bodyObj.location | Should -Be 4
            $bodyObj.name | Should -Be 'CH-01b'
            $bodyObj.type | Should -Be 'dry-cooler'
            $bodyObj.fluid_type | Should -Be 'dielectric'
            $bodyObj.cooling_capacity | Should -Be 750
            $bodyObj.description | Should -Be 'd'
            $bodyObj.owner | Should -Be 3
            $bodyObj.comments | Should -Be 'c'
            $bodyObj.tags | Should -Be @('x')
            $bodyObj.custom_fields.k | Should -Be 'v'
        }

        It "Should clear fluid_type with the empty-string sentinel" {
            $Result = Set-NBDCIMCoolingSource -Id 5 -Fluid_Type '' -Confirm:$false
            $Result.Body | Should -Match '"fluid_type":null'
        }

        It "Should clear location with null" {
            $Result = Set-NBDCIMCoolingSource -Id 5 -Location $null -Confirm:$false
            $Result.Body | Should -Match '"location":null'
        }

        It "Should clear cooling_capacity with null" {
            $Result = Set-NBDCIMCoolingSource -Id 5 -Cooling_Capacity $null -Confirm:$false
            $Result.Body | Should -Match '"cooling_capacity":null'
        }

        It "Should reject an unknown fluid type" {
            { Set-NBDCIMCoolingSource -Id 5 -Fluid_Type 'beer' -Confirm:$false } | Should -Throw
        }

        It "Should accept Id from the pipeline by property name" {
            $Result = [PSCustomObject]@{ Id = 11 } | Set-NBDCIMCoolingSource -Status failed -Confirm:$false
            $Result.Uri | Should -Match '/api/dcim/cooling-sources/11/'
        }

        It "Should not call the API with -WhatIf" {
            Set-NBDCIMCoolingSource -Id 5 -Status active -WhatIf
            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -Times 0 -Exactly
        }
    }

    Context "Remove-NBDCIMCoolingSource" {
        It "Should DELETE the detail endpoint" {
            $Result = Remove-NBDCIMCoolingSource -Id 5 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-sources/5/'
        }

        It "Should accept Id from the pipeline by property name" {
            $Result = [PSCustomObject]@{ Id = 12 } | Remove-NBDCIMCoolingSource -Confirm:$false
            $Result.Uri | Should -Match '/api/dcim/cooling-sources/12/'
        }

        It "Should not call the API with -WhatIf" {
            Remove-NBDCIMCoolingSource -Id 5 -WhatIf
            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -Times 0 -Exactly
        }
    }
    #endregion CoolingSources

    #region CoolingFeeds
    Context "Get-NBDCIMCoolingFeed" {
        It "Should request the list endpoint" {
            $Result = Get-NBDCIMCoolingFeed
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-feeds/'
        }

        It "Should request a cooling feed by ID" {
            $Result = Get-NBDCIMCoolingFeed -Id 7
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-feeds/7/'
        }

        It "Should pass -Brief through on the detail endpoint" {
            $Result = Get-NBDCIMCoolingFeed -Id 7 -Brief
            $Result.Uri | Should -Match '/api/dcim/cooling-feeds/7/\?brief=True'
        }

        It "Should filter by name" {
            $Result = Get-NBDCIMCoolingFeed -Name 'CF-01'
            $Result.Uri | Should -Match 'name=CF-01'
        }

        It "Should emit repeat-key cooling_source_id filters" {
            $Result = Get-NBDCIMCoolingFeed -Cooling_Source_Id 3, 4
            $Result.Uri | Should -Match 'cooling_source_id=3'
            $Result.Uri | Should -Match 'cooling_source_id=4'
        }

        It "Should filter by rack_id" {
            $Result = Get-NBDCIMCoolingFeed -Rack_Id 12
            $Result.Uri | Should -Match 'rack_id=12'
        }

        It "Should filter by site_id" {
            $Result = Get-NBDCIMCoolingFeed -Site_Id 1
            $Result.Uri | Should -Match 'site_id=1'
        }

        It "Should filter by site slug" {
            $Result = Get-NBDCIMCoolingFeed -Site 'dc-1'
            $Result.Uri | Should -Match 'site=dc-1'
        }

        It "Should filter by region_id" {
            $Result = Get-NBDCIMCoolingFeed -Region_Id 4
            $Result.Uri | Should -Match 'region_id=4'
        }

        It "Should filter by tenant_id" {
            $Result = Get-NBDCIMCoolingFeed -Tenant_Id 6
            $Result.Uri | Should -Match 'tenant_id=6'
        }

        It "Should filter by tenant slug" {
            $Result = Get-NBDCIMCoolingFeed -Tenant 'acme'
            $Result.Uri | Should -Match 'tenant=acme'
        }

        It "Should filter by status" {
            $Result = Get-NBDCIMCoolingFeed -Status planned
            $Result.Uri | Should -Match 'status=planned'
        }

        It "Should reject an unknown status" {
            { Get-NBDCIMCoolingFeed -Status 'broken' } | Should -Throw
        }

        It "Should filter by max_flow_unit" {
            $Result = Get-NBDCIMCoolingFeed -Max_Flow_Unit gpm
            $Result.Uri | Should -Match 'max_flow_unit=gpm'
        }

        It "Should reject an unknown max_flow_unit" {
            { Get-NBDCIMCoolingFeed -Max_Flow_Unit 'buckets' } | Should -Throw
        }

        It "Should filter by cooling_capacity" {
            $Result = Get-NBDCIMCoolingFeed -Cooling_Capacity 25
            $Result.Uri | Should -Match 'cooling_capacity=25'
        }

        It "Should filter by max_flow" {
            $Result = Get-NBDCIMCoolingFeed -Max_Flow 40.5
            $Result.Uri | Should -Match 'max_flow=40\.5'
        }

        It "Should filter by description" {
            $Result = Get-NBDCIMCoolingFeed -Description 'primary'
            $Result.Uri | Should -Match 'description=primary'
        }

        It "Should filter by tag" {
            $Result = Get-NBDCIMCoolingFeed -Tag 'critical'
            $Result.Uri | Should -Match 'tag=critical'
        }

        It "Should send -Query as q" {
            $Result = Get-NBDCIMCoolingFeed -Query 'feed' -WarningAction SilentlyContinue
            $Result.Uri | Should -Match 'q=feed'
        }

        It "Should pass limit and offset" {
            $Result = Get-NBDCIMCoolingFeed -Limit 10 -Offset 70000
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=70000'
        }

        It "Should reject -Brief together with -Omit" {
            { Get-NBDCIMCoolingFeed -Brief -Omit 'comments' } | Should -Throw
        }
    }

    Context "New-NBDCIMCoolingFeed" {
        It "Should POST the required fields" {
            $Result = New-NBDCIMCoolingFeed -Cooling_Source 3 -Name 'CF-01'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-feeds/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.cooling_source | Should -Be 3
            $bodyObj.name | Should -Be 'CF-01'
        }

        It "Should require Cooling_Source and Name" {
            $cmd = Get-Command New-NBDCIMCoolingFeed
            foreach ($p in 'Cooling_Source', 'Name') {
                $attr = $cmd.Parameters[$p].Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
                $attr.Mandatory | Should -BeTrue -Because "$p is required by the API"
            }
        }

        It "Should send every optional field" {
            $Result = New-NBDCIMCoolingFeed -Cooling_Source 3 -Name 'CF-02' -Rack 12 -Status planned `
                -Cooling_Capacity 25.5 -Max_Flow 40 -Max_Flow_Unit lpm -Description 'desc' -Tenant 6 -Owner 7 `
                -Comments 'notes' -Tags 'a', 'b' -Custom_Fields @{ loop = 'A' }
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.rack | Should -Be 12
            $bodyObj.status | Should -Be 'planned'
            $bodyObj.cooling_capacity | Should -Be 25.5
            $bodyObj.max_flow | Should -Be 40
            $bodyObj.max_flow_unit | Should -Be 'lpm'
            $bodyObj.description | Should -Be 'desc'
            $bodyObj.tenant | Should -Be 6
            $bodyObj.owner | Should -Be 7
            $bodyObj.comments | Should -Be 'notes'
            $bodyObj.tags | Should -Be @('a', 'b')
            $bodyObj.custom_fields.loop | Should -Be 'A'
        }

        It "Should reject an unknown max_flow_unit" {
            { New-NBDCIMCoolingFeed -Cooling_Source 3 -Name 'X' -Max_Flow_Unit 'buckets' } | Should -Throw
        }

        It "Should reject an unknown status" {
            { New-NBDCIMCoolingFeed -Cooling_Source 3 -Name 'X' -Status 'broken' } | Should -Throw
        }

        It "Should not call the API with -WhatIf" {
            New-NBDCIMCoolingFeed -Cooling_Source 3 -Name 'X' -WhatIf
            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -Times 0 -Exactly
        }
    }

    Context "Set-NBDCIMCoolingFeed" {
        It "Should PATCH the detail endpoint" {
            $Result = Set-NBDCIMCoolingFeed -Id 7 -Status offline -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-feeds/7/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.status | Should -Be 'offline'
            $bodyObj.PSObject.Properties.Name | Should -Not -Contain 'id'
        }

        It "Should send updated scalar fields" {
            $Result = Set-NBDCIMCoolingFeed -Id 7 -Cooling_Source 4 -Rack 13 -Name 'CF-01b' -Cooling_Capacity 30 `
                -Max_Flow 55.5 -Max_Flow_Unit m3ph -Description 'd' -Tenant 8 -Owner 3 -Comments 'c' `
                -Tags 'x' -Custom_Fields @{ k = 'v' } -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.cooling_source | Should -Be 4
            $bodyObj.rack | Should -Be 13
            $bodyObj.name | Should -Be 'CF-01b'
            $bodyObj.cooling_capacity | Should -Be 30
            $bodyObj.max_flow | Should -Be 55.5
            $bodyObj.max_flow_unit | Should -Be 'm3ph'
            $bodyObj.description | Should -Be 'd'
            $bodyObj.tenant | Should -Be 8
            $bodyObj.owner | Should -Be 3
            $bodyObj.comments | Should -Be 'c'
            $bodyObj.tags | Should -Be @('x')
            $bodyObj.custom_fields.k | Should -Be 'v'
        }

        It "Should clear max_flow_unit with the empty-string sentinel" {
            $Result = Set-NBDCIMCoolingFeed -Id 7 -Max_Flow_Unit '' -Confirm:$false
            $Result.Body | Should -Match '"max_flow_unit":null'
        }

        It "Should clear rack and tenant with null" {
            $Result = Set-NBDCIMCoolingFeed -Id 7 -Rack $null -Tenant $null -Confirm:$false
            $Result.Body | Should -Match '"rack":null'
            $Result.Body | Should -Match '"tenant":null'
        }

        It "Should clear cooling_capacity and max_flow with null" {
            $Result = Set-NBDCIMCoolingFeed -Id 7 -Cooling_Capacity $null -Max_Flow $null -Confirm:$false
            $Result.Body | Should -Match '"cooling_capacity":null'
            $Result.Body | Should -Match '"max_flow":null'
        }

        It "Should reject an unknown max_flow_unit" {
            { Set-NBDCIMCoolingFeed -Id 7 -Max_Flow_Unit 'buckets' -Confirm:$false } | Should -Throw
        }

        It "Should accept Id from the pipeline by property name" {
            $Result = [PSCustomObject]@{ Id = 21 } | Set-NBDCIMCoolingFeed -Status failed -Confirm:$false
            $Result.Uri | Should -Match '/api/dcim/cooling-feeds/21/'
        }

        It "Should not call the API with -WhatIf" {
            Set-NBDCIMCoolingFeed -Id 7 -Status active -WhatIf
            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -Times 0 -Exactly
        }
    }

    Context "Remove-NBDCIMCoolingFeed" {
        It "Should DELETE the detail endpoint" {
            $Result = Remove-NBDCIMCoolingFeed -Id 7 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-feeds/7/'
        }

        It "Should accept Id from the pipeline by property name" {
            $Result = [PSCustomObject]@{ Id = 22 } | Remove-NBDCIMCoolingFeed -Confirm:$false
            $Result.Uri | Should -Match '/api/dcim/cooling-feeds/22/'
        }

        It "Should not call the API with -WhatIf" {
            Remove-NBDCIMCoolingFeed -Id 7 -WhatIf
            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -Times 0 -Exactly
        }
    }
    #endregion CoolingFeeds

    Context "Cooling cmdlet conventions" {
        It "<Command> should support ShouldProcess" -TestCases @(
            @{ Command = 'New-NBDCIMCoolingSource' }
            @{ Command = 'Set-NBDCIMCoolingSource' }
            @{ Command = 'Remove-NBDCIMCoolingSource' }
            @{ Command = 'New-NBDCIMCoolingFeed' }
            @{ Command = 'Set-NBDCIMCoolingFeed' }
            @{ Command = 'Remove-NBDCIMCoolingFeed' }
        ) {
            param($Command)
            $cmd = Get-Command $Command
            $cmd.Parameters.Keys | Should -Contain 'WhatIf'
            $cmd.Parameters.Keys | Should -Contain 'Confirm'
        }

        It "<Command> should expose -Raw, -All, -PageSize, -Brief, -Fields and -Omit" -TestCases @(
            @{ Command = 'Get-NBDCIMCoolingSource' }
            @{ Command = 'Get-NBDCIMCoolingFeed' }
        ) {
            param($Command)
            $cmd = Get-Command $Command
            foreach ($p in 'Raw', 'All', 'PageSize', 'Brief', 'Fields', 'Omit') {
                $cmd.Parameters.Keys | Should -Contain $p
            }
            $cmd.Parameters['Offset'].ParameterType | Should -Be ([uint32])
        }
    }
}
