<#
.SYNOPSIS
    Unit tests for the NetBox 4.7 cooling device components.

.DESCRIPTION
    Tests for the DCIM cooling component endpoints added in NetBox 4.7:
    CoolingIntakes, CoolingOutflows, CoolingIntakeTemplates and
    CoolingOutflowTemplates (Get / New / Set / Remove for each).
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

Describe "DCIM Cooling Component Functions" -Tag 'Build', 'DCIM' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
        Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
            return [ordered]@{
                'Method' = if ($Method) { $Method } else { 'GET' }
                'Uri'    = $URI.Uri.AbsoluteUri
                'Body'   = if ($Body) { $Body | ConvertTo-Json -Compress } else { $null }
            }
        }

        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }
    }

    #region CoolingIntakes
    Context "Get-NBDCIMCoolingIntake" {
        It "Should request the cooling-intakes list endpoint" {
            $Result = Get-NBDCIMCoolingIntake
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-intakes/'
        }

        It "Should request a cooling intake by ID" {
            $Result = Get-NBDCIMCoolingIntake -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-intakes/5/'
        }

        It "Should request each ID separately when given multiple IDs" {
            $Result = Get-NBDCIMCoolingIntake -Id 5, 6
            $Result.Count | Should -Be 2
            $Result[1].Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-intakes/6/'
        }

        It "Should pass -Brief through on the detail endpoint" {
            $Result = Get-NBDCIMCoolingIntake -Id 5 -Brief
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-intakes/5/?brief=True'
        }

        It "Should filter by <Param> as a repeated query key" -TestCases @(
            @{ Param = 'Name';           Values = @('in0', 'in1');   Key = 'name' }
            @{ Param = 'Label';          Values = @('A', 'B');       Key = 'label' }
            @{ Param = 'Device_Id';      Values = @(1, 2);           Key = 'device_id' }
            @{ Param = 'Device';         Values = @('sw1', 'sw2');   Key = 'device' }
            @{ Param = 'Device_Type_Id'; Values = @(3, 4);           Key = 'device_type_id' }
            @{ Param = 'Module_Id';      Values = @(5, 6);           Key = 'module_id' }
            @{ Param = 'Site_Id';        Values = @(7, 8);           Key = 'site_id' }
            @{ Param = 'Site';           Values = @('ams', 'fra');   Key = 'site' }
            @{ Param = 'Location_Id';    Values = @(9, 10);          Key = 'location_id' }
            @{ Param = 'Rack_Id';        Values = @(11, 12);         Key = 'rack_id' }
            @{ Param = 'Type';           Values = @('uqd', 'qdc');   Key = 'type' }
            @{ Param = 'Diameter';       Values = @(12.7, 25.4);     Key = 'diameter' }
            @{ Param = 'Diameter_Unit';  Values = @('mm', 'in');     Key = 'diameter_unit' }
            @{ Param = 'Max_Flow';       Values = @(8, 16.5);        Key = 'max_flow' }
            @{ Param = 'Max_Flow_Unit';  Values = @('lpm', 'gpm');   Key = 'max_flow_unit' }
            @{ Param = 'Cooling_Outflow_Id'; Values = @(13, 14);     Key = 'cooling_outflow_id' }
            @{ Param = 'Description';    Values = @('x', 'y');       Key = 'description' }
            @{ Param = 'Tag';            Values = @('t1', 't2');     Key = 'tag' }
        ) {
            $splat = @{ $Param = $Values }
            $Result = Get-NBDCIMCoolingIntake @splat
            $Result.Uri | Should -Be "https://netbox.domain.com/api/dcim/cooling-intakes/?$Key=$($Values[0])&$Key=$($Values[1])"
        }

        It "Should send -Query as q" {
            $Result = Get-NBDCIMCoolingIntake -Query 'coolant' -WarningAction SilentlyContinue
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-intakes/?q=coolant'
        }

        It "Should send -Limit and -Offset" {
            $Result = Get-NBDCIMCoolingIntake -Limit 50 -Offset 100000
            $Result.Uri | Should -Match 'limit=50'
            $Result.Uri | Should -Match 'offset=100000'
        }

        It "Should send -Fields and -Omit" {
            (Get-NBDCIMCoolingIntake -Fields 'id', 'name').Uri | Should -Match 'fields=id%2Cname'
            (Get-NBDCIMCoolingIntake -Omit 'custom_fields').Uri | Should -Match 'omit=custom_fields'
        }

        It "Should reject -Brief together with -Fields" {
            { Get-NBDCIMCoolingIntake -Brief -Fields 'id' } | Should -Throw
        }

        It "Should pass -All and -PageSize to InvokeNetboxRequest" {
            Get-NBDCIMCoolingIntake -All -PageSize 250 | Out-Null
            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -Times 1 -Exactly -ParameterFilter {
                $All -eq $true -and $PageSize -eq 250
            }
        }
    }

    Context "New-NBDCIMCoolingIntake" {
        It "Should require Device and Name" {
            $cmd = Get-Command New-NBDCIMCoolingIntake
            $cmd.Parameters['Device'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Be $true
            $cmd.Parameters['Name'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Be $true
        }

        It "Should POST a minimal cooling intake" {
            $Result = New-NBDCIMCoolingIntake -Device 12 -Name 'Coolant In' -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-intakes/'
            $body = $Result.Body | ConvertFrom-Json
            $body.device | Should -Be 12
            $body.name | Should -Be 'Coolant In'
        }

        It "Should POST every writable field" {
            $Result = New-NBDCIMCoolingIntake -Device 12 -Module 3 -Name 'Coolant In' -Label 'IN-1' -Type 'uqd' `
                -Diameter 12.7 -Diameter_Unit 'mm' -Max_Flow 8.5 -Max_Flow_Unit 'lpm' -Cooling_Outflow 44 `
                -Description 'desc' -Owner 2 -Tags 'liquid', 7 -Custom_Fields @{ loop = 'A' } -Confirm:$false
            $body = $Result.Body | ConvertFrom-Json
            $body.device | Should -Be 12
            $body.module | Should -Be 3
            $body.label | Should -Be 'IN-1'
            $body.type | Should -Be 'uqd'
            $body.diameter | Should -Be 12.7
            $body.diameter_unit | Should -Be 'mm'
            $body.max_flow | Should -Be 8.5
            $body.max_flow_unit | Should -Be 'lpm'
            $body.cooling_outflow | Should -Be 44
            $body.description | Should -Be 'desc'
            $body.owner | Should -Be 2
            $body.tags[0].name | Should -Be 'liquid'
            $body.tags[1] | Should -Be 7
            $body.custom_fields.loop | Should -Be 'A'
        }

        It "Should accept every connector type" -TestCases @(
            @{ Type = 'uqd' }, @{ Type = 'uqdb' }, @{ Type = 'qdc' }, @{ Type = 'camlock' },
            @{ Type = 'npt' }, @{ Type = 'bsp' }, @{ Type = 'proprietary' }
        ) {
            $Result = New-NBDCIMCoolingIntake -Device 1 -Name 'x' -Type $Type -Confirm:$false
            ($Result.Body | ConvertFrom-Json).type | Should -Be $Type
        }

        It "Should reject an invalid -Type" {
            { New-NBDCIMCoolingIntake -Device 1 -Name 'x' -Type 'garden-hose' -Confirm:$false } | Should -Throw
        }

        It "Should reject an invalid -Diameter_Unit" {
            { New-NBDCIMCoolingIntake -Device 1 -Name 'x' -Diameter_Unit 'ft' -Confirm:$false } | Should -Throw
        }

        It "Should reject an invalid -Max_Flow_Unit" {
            { New-NBDCIMCoolingIntake -Device 1 -Name 'x' -Max_Flow_Unit 'lps' -Confirm:$false } | Should -Throw
        }

        It "Should reject a -Diameter below 0.01" {
            { New-NBDCIMCoolingIntake -Device 1 -Name 'x' -Diameter 0 -Confirm:$false } | Should -Throw
        }

        It "Should not call the API with -WhatIf" {
            New-NBDCIMCoolingIntake -Device 1 -Name 'x' -WhatIf
            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -Times 0 -Exactly
        }
    }

    Context "Set-NBDCIMCoolingIntake" {
        It "Should PATCH the detail endpoint" {
            $Result = Set-NBDCIMCoolingIntake -Id 5 -Label 'IN-2' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-intakes/5/'
            $Result.Body | Should -Be '{"label":"IN-2"}'
        }

        It "Should PATCH every writable field" {
            $Result = Set-NBDCIMCoolingIntake -Id 5 -Device 12 -Module 3 -Name 'n' -Label 'l' -Type 'qdc' `
                -Diameter 25.4 -Diameter_Unit 'in' -Max_Flow 16 -Max_Flow_Unit 'gpm' -Cooling_Outflow 44 `
                -Description 'd' -Owner 2 -Tags 'liquid' -Custom_Fields @{ loop = 'B' } -Confirm:$false
            $body = $Result.Body | ConvertFrom-Json
            $body.device | Should -Be 12
            $body.module | Should -Be 3
            $body.name | Should -Be 'n'
            $body.label | Should -Be 'l'
            $body.type | Should -Be 'qdc'
            $body.diameter | Should -Be 25.4
            $body.diameter_unit | Should -Be 'in'
            $body.max_flow | Should -Be 16
            $body.max_flow_unit | Should -Be 'gpm'
            $body.cooling_outflow | Should -Be 44
            $body.description | Should -Be 'd'
            $body.owner | Should -Be 2
            $body.tags[0].name | Should -Be 'liquid'
            $body.custom_fields.loop | Should -Be 'B'
        }

        It "Should send JSON null when <Param> is cleared with ''" -TestCases @(
            @{ Param = 'Type';          Key = 'type' }
            @{ Param = 'Diameter_Unit'; Key = 'diameter_unit' }
            @{ Param = 'Max_Flow_Unit'; Key = 'max_flow_unit' }
        ) {
            $splat = @{ Id = 5; $Param = ''; Confirm = $false }
            $Result = Set-NBDCIMCoolingIntake @splat
            $Result.Body | Should -Be "{`"$Key`":null}"
        }

        It "Should send JSON null when <Param> is set to `$null" -TestCases @(
            @{ Param = 'Module';          Key = 'module' }
            @{ Param = 'Diameter';        Key = 'diameter' }
            @{ Param = 'Max_Flow';        Key = 'max_flow' }
            @{ Param = 'Cooling_Outflow'; Key = 'cooling_outflow' }
        ) {
            $splat = @{ Id = 5; $Param = $null; Confirm = $false }
            $Result = Set-NBDCIMCoolingIntake @splat
            $Result.Body | Should -Be "{`"$Key`":null}"
        }

        It "Should reject an invalid -Type" {
            { Set-NBDCIMCoolingIntake -Id 5 -Type 'garden-hose' -Confirm:$false } | Should -Throw
        }

        It "Should accept Id from the pipeline by property name" {
            $Result = [PSCustomObject]@{ Id = 9 } | Set-NBDCIMCoolingIntake -Label 'p' -Confirm:$false
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-intakes/9/'
        }
    }

    Context "Remove-NBDCIMCoolingIntake" {
        It "Should DELETE the detail endpoint" {
            $Result = Remove-NBDCIMCoolingIntake -Id 5 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-intakes/5/'
        }

        It "Should accept Id from the pipeline" {
            $Result = [PSCustomObject]@{ Id = 7 } | Remove-NBDCIMCoolingIntake -Confirm:$false
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-intakes/7/'
        }

        It "Should not call the API with -WhatIf" {
            Remove-NBDCIMCoolingIntake -Id 5 -WhatIf
            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -Times 0 -Exactly
        }
    }
    #endregion

    #region CoolingOutflows
    Context "Get-NBDCIMCoolingOutflow" {
        It "Should request the cooling-outflows list endpoint" {
            $Result = Get-NBDCIMCoolingOutflow
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-outflows/'
        }

        It "Should request a cooling outflow by ID" {
            $Result = Get-NBDCIMCoolingOutflow -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-outflows/5/'
        }

        It "Should filter by <Param> as a repeated query key" -TestCases @(
            @{ Param = 'Name';           Values = @('out0', 'out1'); Key = 'name' }
            @{ Param = 'Label';          Values = @('A', 'B');       Key = 'label' }
            @{ Param = 'Device_Id';      Values = @(1, 2);           Key = 'device_id' }
            @{ Param = 'Device';         Values = @('sw1', 'sw2');   Key = 'device' }
            @{ Param = 'Device_Type_Id'; Values = @(3, 4);           Key = 'device_type_id' }
            @{ Param = 'Module_Id';      Values = @(5, 6);           Key = 'module_id' }
            @{ Param = 'Site_Id';        Values = @(7, 8);           Key = 'site_id' }
            @{ Param = 'Site';           Values = @('ams', 'fra');   Key = 'site' }
            @{ Param = 'Location_Id';    Values = @(9, 10);          Key = 'location_id' }
            @{ Param = 'Rack_Id';        Values = @(11, 12);         Key = 'rack_id' }
            @{ Param = 'Type';           Values = @('uqd', 'qdc');   Key = 'type' }
            @{ Param = 'Diameter';       Values = @(12.7, 25.4);     Key = 'diameter' }
            @{ Param = 'Diameter_Unit';  Values = @('mm', 'in');     Key = 'diameter_unit' }
            @{ Param = 'Cooling_Intake_Id'; Values = @(13, 14);      Key = 'cooling_intake_id' }
            @{ Param = 'Description';    Values = @('x', 'y');       Key = 'description' }
            @{ Param = 'Tag';            Values = @('t1', 't2');     Key = 'tag' }
        ) {
            $splat = @{ $Param = $Values }
            $Result = Get-NBDCIMCoolingOutflow @splat
            $Result.Uri | Should -Be "https://netbox.domain.com/api/dcim/cooling-outflows/?$Key=$($Values[0])&$Key=$($Values[1])"
        }

        It "Should not expose intake-only filters" {
            $cmd = Get-Command Get-NBDCIMCoolingOutflow
            $cmd.Parameters.Keys | Should -Not -Contain 'Max_Flow'
            $cmd.Parameters.Keys | Should -Not -Contain 'Max_Flow_Unit'
            $cmd.Parameters.Keys | Should -Not -Contain 'Cooling_Outflow_Id'
        }

        It "Should send -Query as q" {
            $Result = Get-NBDCIMCoolingOutflow -Query 'coolant' -WarningAction SilentlyContinue
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-outflows/?q=coolant'
        }

        It "Should reject -Brief together with -Omit" {
            { Get-NBDCIMCoolingOutflow -Brief -Omit 'tags' } | Should -Throw
        }
    }

    Context "New-NBDCIMCoolingOutflow" {
        It "Should POST every writable field" {
            $Result = New-NBDCIMCoolingOutflow -Device 12 -Module 3 -Name 'Coolant Out' -Label 'OUT-1' -Type 'camlock' `
                -Diameter 19.05 -Diameter_Unit 'mm' -Cooling_Intake 55 -Description 'desc' -Owner 2 `
                -Tags 'liquid' -Custom_Fields @{ loop = 'A' } -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-outflows/'
            $body = $Result.Body | ConvertFrom-Json
            $body.device | Should -Be 12
            $body.module | Should -Be 3
            $body.name | Should -Be 'Coolant Out'
            $body.label | Should -Be 'OUT-1'
            $body.type | Should -Be 'camlock'
            $body.diameter | Should -Be 19.05
            $body.diameter_unit | Should -Be 'mm'
            $body.cooling_intake | Should -Be 55
            $body.description | Should -Be 'desc'
            $body.owner | Should -Be 2
            $body.tags[0].name | Should -Be 'liquid'
            $body.custom_fields.loop | Should -Be 'A'
        }

        It "Should not expose intake-only fields" {
            $cmd = Get-Command New-NBDCIMCoolingOutflow
            $cmd.Parameters.Keys | Should -Not -Contain 'Max_Flow'
            $cmd.Parameters.Keys | Should -Not -Contain 'Max_Flow_Unit'
            $cmd.Parameters.Keys | Should -Not -Contain 'Cooling_Outflow'
        }

        It "Should reject an invalid -Type" {
            { New-NBDCIMCoolingOutflow -Device 1 -Name 'x' -Type 'garden-hose' -Confirm:$false } | Should -Throw
        }
    }

    Context "Set-NBDCIMCoolingOutflow" {
        It "Should PATCH the detail endpoint with every writable field" {
            $Result = Set-NBDCIMCoolingOutflow -Id 5 -Device 12 -Module 3 -Name 'n' -Label 'l' -Type 'npt' `
                -Diameter 6.35 -Diameter_Unit 'cm' -Cooling_Intake 55 -Description 'd' -Owner 2 -Tags 'a' `
                -Custom_Fields @{ loop = 'C' } -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-outflows/5/'
            $body = $Result.Body | ConvertFrom-Json
            $body.device | Should -Be 12
            $body.module | Should -Be 3
            $body.name | Should -Be 'n'
            $body.label | Should -Be 'l'
            $body.type | Should -Be 'npt'
            $body.diameter | Should -Be 6.35
            $body.diameter_unit | Should -Be 'cm'
            $body.cooling_intake | Should -Be 55
            $body.description | Should -Be 'd'
            $body.owner | Should -Be 2
            $body.tags[0].name | Should -Be 'a'
            $body.custom_fields.loop | Should -Be 'C'
        }

        It "Should send JSON null when <Param> is cleared with ''" -TestCases @(
            @{ Param = 'Type';          Key = 'type' }
            @{ Param = 'Diameter_Unit'; Key = 'diameter_unit' }
        ) {
            $splat = @{ Id = 5; $Param = ''; Confirm = $false }
            (Set-NBDCIMCoolingOutflow @splat).Body | Should -Be "{`"$Key`":null}"
        }

        It "Should send JSON null when <Param> is set to `$null" -TestCases @(
            @{ Param = 'Module';         Key = 'module' }
            @{ Param = 'Diameter';       Key = 'diameter' }
            @{ Param = 'Cooling_Intake'; Key = 'cooling_intake' }
        ) {
            $splat = @{ Id = 5; $Param = $null; Confirm = $false }
            (Set-NBDCIMCoolingOutflow @splat).Body | Should -Be "{`"$Key`":null}"
        }
    }

    Context "Remove-NBDCIMCoolingOutflow" {
        It "Should DELETE the detail endpoint" {
            $Result = Remove-NBDCIMCoolingOutflow -Id 5 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-outflows/5/'
        }

        It "Should not call the API with -WhatIf" {
            Remove-NBDCIMCoolingOutflow -Id 5 -WhatIf
            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -Times 0 -Exactly
        }
    }
    #endregion

    #region CoolingIntakeTemplates
    Context "Get-NBDCIMCoolingIntakeTemplate" {
        It "Should request the cooling-intake-templates list endpoint" {
            $Result = Get-NBDCIMCoolingIntakeTemplate
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-intake-templates/'
        }

        It "Should request a cooling intake template by ID" {
            $Result = Get-NBDCIMCoolingIntakeTemplate -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-intake-templates/5/'
        }

        It "Should filter by <Param> as a repeated query key" -TestCases @(
            @{ Param = 'Name';           Values = @('in0', 'in1');   Key = 'name' }
            @{ Param = 'Label';          Values = @('A', 'B');       Key = 'label' }
            @{ Param = 'Device_Type_Id'; Values = @(3, 4);           Key = 'device_type_id' }
            @{ Param = 'Module_Type_Id'; Values = @(5, 6);           Key = 'module_type_id' }
            @{ Param = 'Type';           Values = @('uqd', 'qdc');   Key = 'type' }
            @{ Param = 'Diameter';       Values = @(12.7, 25.4);     Key = 'diameter' }
            @{ Param = 'Diameter_Unit';  Values = @('mm', 'in');     Key = 'diameter_unit' }
            @{ Param = 'Max_Flow';       Values = @(8, 16.5);        Key = 'max_flow' }
            @{ Param = 'Max_Flow_Unit';  Values = @('lpm', 'gpm');   Key = 'max_flow_unit' }
            @{ Param = 'Description';    Values = @('x', 'y');       Key = 'description' }
        ) {
            $splat = @{ $Param = $Values }
            $Result = Get-NBDCIMCoolingIntakeTemplate @splat
            $Result.Uri | Should -Be "https://netbox.domain.com/api/dcim/cooling-intake-templates/?$Key=$($Values[0])&$Key=$($Values[1])"
        }

        It "Should not expose device-level filters" {
            $cmd = Get-Command Get-NBDCIMCoolingIntakeTemplate
            $cmd.Parameters.Keys | Should -Not -Contain 'Device_Id'
            $cmd.Parameters.Keys | Should -Not -Contain 'Site_Id'
            $cmd.Parameters.Keys | Should -Not -Contain 'Tag'
        }

        It "Should send -Query as q" {
            $Result = Get-NBDCIMCoolingIntakeTemplate -Query 'coolant' -WarningAction SilentlyContinue
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-intake-templates/?q=coolant'
        }
    }

    Context "New-NBDCIMCoolingIntakeTemplate" {
        It "Should require Name only" {
            $cmd = Get-Command New-NBDCIMCoolingIntakeTemplate
            $cmd.Parameters['Name'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Be $true
            $cmd.Parameters['Device_Type'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Not -Contain $true
        }

        It "Should POST every writable field on a device type" {
            $Result = New-NBDCIMCoolingIntakeTemplate -Device_Type 4 -Name 'Coolant In' -Label 'IN-1' -Type 'uqdb' `
                -Diameter 12.7 -Diameter_Unit 'mm' -Max_Flow 8 -Max_Flow_Unit 'm3ph' -Description 'desc' -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-intake-templates/'
            $body = $Result.Body | ConvertFrom-Json
            $body.device_type | Should -Be 4
            $body.name | Should -Be 'Coolant In'
            $body.label | Should -Be 'IN-1'
            $body.type | Should -Be 'uqdb'
            $body.diameter | Should -Be 12.7
            $body.diameter_unit | Should -Be 'mm'
            $body.max_flow | Should -Be 8
            $body.max_flow_unit | Should -Be 'm3ph'
            $body.description | Should -Be 'desc'
            $body.PSObject.Properties.Name | Should -Not -Contain 'module_type'
        }

        It "Should POST a module type template" {
            $Result = New-NBDCIMCoolingIntakeTemplate -Module_Type 8 -Name 'In {module}' -Confirm:$false
            $body = $Result.Body | ConvertFrom-Json
            $body.module_type | Should -Be 8
            $body.name | Should -Be 'In {module}'
        }

        It "Should not expose component-only fields" {
            $cmd = Get-Command New-NBDCIMCoolingIntakeTemplate
            foreach ($p in 'Device', 'Module', 'Owner', 'Tags', 'Custom_Fields', 'Cooling_Outflow') {
                $cmd.Parameters.Keys | Should -Not -Contain $p
            }
        }

        It "Should reject an invalid -Max_Flow_Unit" {
            { New-NBDCIMCoolingIntakeTemplate -Name 'x' -Max_Flow_Unit 'lps' -Confirm:$false } | Should -Throw
        }
    }

    Context "Set-NBDCIMCoolingIntakeTemplate" {
        It "Should PATCH the detail endpoint with every writable field" {
            $Result = Set-NBDCIMCoolingIntakeTemplate -Id 5 -Device_Type 4 -Module_Type 8 -Name 'n' -Label 'l' -Type 'bsp' `
                -Diameter 1 -Diameter_Unit 'in' -Max_Flow 2 -Max_Flow_Unit 'gpm' -Description 'd' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-intake-templates/5/'
            $body = $Result.Body | ConvertFrom-Json
            $body.device_type | Should -Be 4
            $body.module_type | Should -Be 8
            $body.name | Should -Be 'n'
            $body.label | Should -Be 'l'
            $body.type | Should -Be 'bsp'
            $body.diameter | Should -Be 1
            $body.diameter_unit | Should -Be 'in'
            $body.max_flow | Should -Be 2
            $body.max_flow_unit | Should -Be 'gpm'
            $body.description | Should -Be 'd'
        }

        It "Should send JSON null when <Param> is cleared with ''" -TestCases @(
            @{ Param = 'Type';          Key = 'type' }
            @{ Param = 'Diameter_Unit'; Key = 'diameter_unit' }
            @{ Param = 'Max_Flow_Unit'; Key = 'max_flow_unit' }
        ) {
            $splat = @{ Id = 5; $Param = ''; Confirm = $false }
            (Set-NBDCIMCoolingIntakeTemplate @splat).Body | Should -Be "{`"$Key`":null}"
        }

        It "Should send JSON null when <Param> is set to `$null" -TestCases @(
            @{ Param = 'Device_Type'; Key = 'device_type' }
            @{ Param = 'Module_Type'; Key = 'module_type' }
            @{ Param = 'Diameter';    Key = 'diameter' }
            @{ Param = 'Max_Flow';    Key = 'max_flow' }
        ) {
            $splat = @{ Id = 5; $Param = $null; Confirm = $false }
            (Set-NBDCIMCoolingIntakeTemplate @splat).Body | Should -Be "{`"$Key`":null}"
        }
    }

    Context "Remove-NBDCIMCoolingIntakeTemplate" {
        It "Should DELETE the detail endpoint" {
            $Result = Remove-NBDCIMCoolingIntakeTemplate -Id 5 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-intake-templates/5/'
        }

        It "Should not call the API with -WhatIf" {
            Remove-NBDCIMCoolingIntakeTemplate -Id 5 -WhatIf
            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -Times 0 -Exactly
        }
    }
    #endregion

    #region CoolingOutflowTemplates
    Context "Get-NBDCIMCoolingOutflowTemplate" {
        It "Should request the cooling-outflow-templates list endpoint" {
            $Result = Get-NBDCIMCoolingOutflowTemplate
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-outflow-templates/'
        }

        It "Should request a cooling outflow template by ID" {
            $Result = Get-NBDCIMCoolingOutflowTemplate -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-outflow-templates/5/'
        }

        It "Should filter by <Param> as a repeated query key" -TestCases @(
            @{ Param = 'Name';           Values = @('out0', 'out1'); Key = 'name' }
            @{ Param = 'Label';          Values = @('A', 'B');       Key = 'label' }
            @{ Param = 'Device_Type_Id'; Values = @(3, 4);           Key = 'device_type_id' }
            @{ Param = 'Module_Type_Id'; Values = @(5, 6);           Key = 'module_type_id' }
            @{ Param = 'Type';           Values = @('uqd', 'qdc');   Key = 'type' }
            @{ Param = 'Diameter';       Values = @(12.7, 25.4);     Key = 'diameter' }
            @{ Param = 'Diameter_Unit';  Values = @('mm', 'in');     Key = 'diameter_unit' }
            @{ Param = 'Cooling_Intake_Id'; Values = @(13, 14);      Key = 'cooling_intake_id' }
            @{ Param = 'Description';    Values = @('x', 'y');       Key = 'description' }
        ) {
            $splat = @{ $Param = $Values }
            $Result = Get-NBDCIMCoolingOutflowTemplate @splat
            $Result.Uri | Should -Be "https://netbox.domain.com/api/dcim/cooling-outflow-templates/?$Key=$($Values[0])&$Key=$($Values[1])"
        }

        It "Should not expose intake-only filters" {
            $cmd = Get-Command Get-NBDCIMCoolingOutflowTemplate
            $cmd.Parameters.Keys | Should -Not -Contain 'Max_Flow'
            $cmd.Parameters.Keys | Should -Not -Contain 'Max_Flow_Unit'
        }
    }

    Context "New-NBDCIMCoolingOutflowTemplate" {
        It "Should POST every writable field" {
            $Result = New-NBDCIMCoolingOutflowTemplate -Device_Type 4 -Name 'Coolant Out' -Label 'OUT-1' -Type 'proprietary' `
                -Diameter 12.7 -Diameter_Unit 'mm' -Cooling_Intake 9 -Description 'desc' -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-outflow-templates/'
            $body = $Result.Body | ConvertFrom-Json
            $body.device_type | Should -Be 4
            $body.name | Should -Be 'Coolant Out'
            $body.label | Should -Be 'OUT-1'
            $body.type | Should -Be 'proprietary'
            $body.diameter | Should -Be 12.7
            $body.diameter_unit | Should -Be 'mm'
            $body.cooling_intake | Should -Be 9
            $body.description | Should -Be 'desc'
        }

        It "Should POST a module type template" {
            $Result = New-NBDCIMCoolingOutflowTemplate -Module_Type 8 -Name 'Out {module}' -Confirm:$false
            ($Result.Body | ConvertFrom-Json).module_type | Should -Be 8
        }

        It "Should reject an invalid -Diameter_Unit" {
            { New-NBDCIMCoolingOutflowTemplate -Name 'x' -Diameter_Unit 'ft' -Confirm:$false } | Should -Throw
        }
    }

    Context "Set-NBDCIMCoolingOutflowTemplate" {
        It "Should PATCH the detail endpoint with every writable field" {
            $Result = Set-NBDCIMCoolingOutflowTemplate -Id 5 -Device_Type 4 -Module_Type 8 -Name 'n' -Label 'l' -Type 'uqd' `
                -Diameter 3 -Diameter_Unit 'cm' -Cooling_Intake 9 -Description 'd' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-outflow-templates/5/'
            $body = $Result.Body | ConvertFrom-Json
            $body.device_type | Should -Be 4
            $body.module_type | Should -Be 8
            $body.name | Should -Be 'n'
            $body.label | Should -Be 'l'
            $body.type | Should -Be 'uqd'
            $body.diameter | Should -Be 3
            $body.diameter_unit | Should -Be 'cm'
            $body.cooling_intake | Should -Be 9
            $body.description | Should -Be 'd'
        }

        It "Should send JSON null when <Param> is cleared with ''" -TestCases @(
            @{ Param = 'Type';          Key = 'type' }
            @{ Param = 'Diameter_Unit'; Key = 'diameter_unit' }
        ) {
            $splat = @{ Id = 5; $Param = ''; Confirm = $false }
            (Set-NBDCIMCoolingOutflowTemplate @splat).Body | Should -Be "{`"$Key`":null}"
        }

        It "Should send JSON null when <Param> is set to `$null" -TestCases @(
            @{ Param = 'Device_Type';    Key = 'device_type' }
            @{ Param = 'Module_Type';    Key = 'module_type' }
            @{ Param = 'Diameter';       Key = 'diameter' }
            @{ Param = 'Cooling_Intake'; Key = 'cooling_intake' }
        ) {
            $splat = @{ Id = 5; $Param = $null; Confirm = $false }
            (Set-NBDCIMCoolingOutflowTemplate @splat).Body | Should -Be "{`"$Key`":null}"
        }
    }

    Context "Remove-NBDCIMCoolingOutflowTemplate" {
        It "Should DELETE the detail endpoint" {
            $Result = Remove-NBDCIMCoolingOutflowTemplate -Id 5 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cooling-outflow-templates/5/'
        }

        It "Should not call the API with -WhatIf" {
            Remove-NBDCIMCoolingOutflowTemplate -Id 5 -WhatIf
            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -Times 0 -Exactly
        }
    }
    #endregion

    Context "Cmdlet metadata" {
        It "<Name> should declare ConfirmImpact <Impact> and support ShouldProcess" -TestCases @(
            @{ Name = 'New-NBDCIMCoolingIntake';            Impact = 'Low' }
            @{ Name = 'Set-NBDCIMCoolingIntake';            Impact = 'Medium' }
            @{ Name = 'Remove-NBDCIMCoolingIntake';         Impact = 'High' }
            @{ Name = 'New-NBDCIMCoolingOutflow';           Impact = 'Low' }
            @{ Name = 'Set-NBDCIMCoolingOutflow';           Impact = 'Medium' }
            @{ Name = 'Remove-NBDCIMCoolingOutflow';        Impact = 'High' }
            @{ Name = 'New-NBDCIMCoolingIntakeTemplate';    Impact = 'Low' }
            @{ Name = 'Set-NBDCIMCoolingIntakeTemplate';    Impact = 'Medium' }
            @{ Name = 'Remove-NBDCIMCoolingIntakeTemplate'; Impact = 'High' }
            @{ Name = 'New-NBDCIMCoolingOutflowTemplate';   Impact = 'Low' }
            @{ Name = 'Set-NBDCIMCoolingOutflowTemplate';   Impact = 'Medium' }
            @{ Name = 'Remove-NBDCIMCoolingOutflowTemplate'; Impact = 'High' }
        ) {
            $cmd = Get-Command $Name
            $cmd.Parameters.Keys | Should -Contain 'WhatIf'
            $attr = $cmd.ScriptBlock.Attributes.Where({ $_ -is [System.Management.Automation.CmdletBindingAttribute] })
            $attr.ConfirmImpact | Should -Be $Impact
        }

        It "<Name> should type -Offset as uint32" -TestCases @(
            @{ Name = 'Get-NBDCIMCoolingIntake' }
            @{ Name = 'Get-NBDCIMCoolingOutflow' }
            @{ Name = 'Get-NBDCIMCoolingIntakeTemplate' }
            @{ Name = 'Get-NBDCIMCoolingOutflowTemplate' }
        ) {
            (Get-Command $Name).Parameters['Offset'].ParameterType | Should -Be ([uint32])
        }
    }
}
