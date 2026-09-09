<#
.SYNOPSIS
    Unit tests for the NetBox 4.7 fields added to existing DCIM cmdlets.

.DESCRIPTION
    Covers the version-gated 4.7-only parameters on:
      - Interfaces / Interface templates: -Channels, -Channel_Id, -MAC_Address (writable)
      - Device / DeviceType / ModuleType: -Cooling_Method, -End_Of_Life
      - Rack / RackType: -Cooling_Capability, -Cooling_Capacity

    Every parameter is asserted twice: present on the wire when the connected
    NetBox is 4.7.0, and dropped with a warning when it is 4.6.10.
#>

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

Describe "DCIM NetBox 4.7 field tests" -Tag 'DCIM', 'Fields47' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }

        Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
            return [ordered]@{
                'Method' = if ($Method) { $Method } else { 'GET' }
                'Uri'    = $URI.Uri.AbsoluteUri
                'Body'   = if ($Body) { $Body | ConvertTo-Json -Compress } else { $null }
            }
        }

        InModuleScope -ModuleName 'PowerNetbox' -ArgumentList $script:TestPath -ScriptBlock {
            param($TestPath)
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }

        $script:parsedVersionBefore = InModuleScope -ModuleName 'PowerNetbox' { $script:NetboxConfig.ParsedVersion }
        InModuleScope -ModuleName 'PowerNetbox' { $script:NetboxConfig.ParsedVersion = [version]'4.7.0' }
    }

    AfterAll {
        InModuleScope -ModuleName 'PowerNetbox' -Parameters @{ v = $script:parsedVersionBefore } { $script:NetboxConfig.ParsedVersion = $v }
    }

    #region Interfaces
    Context "Interfaces: -Channels / -Channel_Id / -MAC_Address (NetBox 4.7+)" {
        It "New-NBDCIMInterface sends channels for a breakout parent" {
            $Result = New-NBDCIMInterface -Device 1 -Name 'et-0/0/0' -Type '400gbase-x-qsfpdd' -Channels 4
            $Result.Method | Should -Be 'POST'
            $body = $Result.Body | ConvertFrom-Json
            $body.channels | Should -Be 4
        }

        It "New-NBDCIMInterface sends channel_id + parent for a channel subinterface" {
            $Result = New-NBDCIMInterface -Device 1 -Name 'et-0/0/0:1' -Type 'channel' -Parent 10 -Channel_Id 1
            $body = $Result.Body | ConvertFrom-Json
            $body.type | Should -Be 'channel'
            $body.parent | Should -Be 10
            $body.channel_id | Should -Be 1
        }

        It "New-NBDCIMInterface sends mac_address by value" {
            $Result = New-NBDCIMInterface -Device 1 -Name 'eth0' -Type '1000base-t' -MAC_Address '00:11:22:33:44:55'
            $body = $Result.Body | ConvertFrom-Json
            $body.mac_address | Should -Be '00:11:22:33:44:55'
        }

        It "New-NBDCIMInterface rejects -Channels outside 1-1024" {
            { New-NBDCIMInterface -Device 1 -Name 'x' -Type '1000base-t' -Channels 0 } | Should -Throw
            { New-NBDCIMInterface -Device 1 -Name 'x' -Type '1000base-t' -Channels 2000 } | Should -Throw
        }

        It "Set-NBDCIMInterface sends channels and channel_id" {
            $Result = Set-NBDCIMInterface -Id 42 -Channels 8 -Channel_Id 3
            $Result.Method | Should -Be 'PATCH'
            $body = $Result.Body | ConvertFrom-Json
            $body.channels | Should -Be 8
            $body.channel_id | Should -Be 3
        }

        It "Set-NBDCIMInterface sends null when -Channels / -Channel_Id are `$null" {
            $Result = Set-NBDCIMInterface -Id 42 -Channels $null -Channel_Id $null
            $Result.Body | Should -Match '"channels":null'
            $Result.Body | Should -Match '"channel_id":null'
        }

        It "Set-NBDCIMInterface sends mac_address by value" {
            $Result = Set-NBDCIMInterface -Id 42 -MAC_Address 'AA:BB:CC:DD:EE:FF'
            $body = $Result.Body | ConvertFrom-Json
            $body.mac_address | Should -Be 'AA:BB:CC:DD:EE:FF'
        }

        It "Set-NBDCIMInterface translates -MAC_Address '' to JSON null" {
            $Result = Set-NBDCIMInterface -Id 42 -MAC_Address ''
            $Result.Body | Should -Match '"mac_address":null'
        }

        It "Set-NBDCIMInterface keeps -Primary_MAC_Address as a numeric ID alongside -MAC_Address" {
            $Result = Set-NBDCIMInterface -Id 42 -Primary_MAC_Address 7
            $body = $Result.Body | ConvertFrom-Json
            $body.primary_mac_address | Should -Be 7
            $body.PSObject.Properties.Name | Should -Not -Contain 'mac_address'
        }

        It "Get-NBDCIMInterface emits repeat-key channels / channel_id filters" {
            $Result = Get-NBDCIMInterface -Channels 4, 8 -Channel_Id 1
            $Result.Uri | Should -Match 'channels=4'
            $Result.Uri | Should -Match 'channels=8'
            $Result.Uri | Should -Match 'channel_id=1'
        }

        It "Get-NBDCIMInterface accepts multiple -MAC_Address values" {
            $Result = Get-NBDCIMInterface -MAC_Address '00:11:22:33:44:55', 'AA:BB:CC:DD:EE:FF'
            $Result.Uri | Should -Match 'mac_address=00%3A11%3A22%3A33%3A44%3A55'
            $Result.Uri | Should -Match 'mac_address=AA%3ABB%3ACC%3ADD%3AEE%3AFF'
        }
    }

    Context "Interface templates: -Channels / -Channel_Id (NetBox 4.7+)" {
        It "New-NBDCIMInterfaceTemplate sends channels and channel_id" {
            $Result = New-NBDCIMInterfaceTemplate -Device_Type 1 -Name 'et-{module}/0/0' -Type '400gbase-x-qsfpdd' -Channels 4
            $body = $Result.Body | ConvertFrom-Json
            $body.channels | Should -Be 4

            $Result = New-NBDCIMInterfaceTemplate -Device_Type 1 -Name 'et-{module}/0/0:1' -Type 'channel' -Channel_Id 1
            $body = $Result.Body | ConvertFrom-Json
            $body.channel_id | Should -Be 1
        }

        It "Set-NBDCIMInterfaceTemplate sends channels / channel_id and null to clear" {
            $Result = Set-NBDCIMInterfaceTemplate -Id 5 -Channels 2 -Channel_Id 2
            $body = $Result.Body | ConvertFrom-Json
            $body.channels | Should -Be 2
            $body.channel_id | Should -Be 2

            $Result = Set-NBDCIMInterfaceTemplate -Id 5 -Channels $null
            $Result.Body | Should -Match '"channels":null'
        }

        It "Get-NBDCIMInterfaceTemplate emits channels / channel_id filters" {
            $Result = Get-NBDCIMInterfaceTemplate -Channels 4 -Channel_Id 1, 2
            $Result.Uri | Should -Match 'channels=4'
            $Result.Uri | Should -Match 'channel_id=1'
            $Result.Uri | Should -Match 'channel_id=2'
        }
    }
    #endregion

    #region Cooling method / End of life
    Context "Cooling method on Device / DeviceType / ModuleType (NetBox 4.7+)" {
        It "New-NBDCIMDevice sends cooling_method" {
            $Result = New-NBDCIMDevice -Name 'srv1' -Role 1 -Device_Type 1 -Site 1 -Cooling_Method 'liquid'
            $body = $Result.Body | ConvertFrom-Json
            $body.cooling_method | Should -Be 'liquid'
        }

        It "Set-NBDCIMDevice sends cooling_method and translates '' to null" {
            $Result = Set-NBDCIMDevice -Id 1 -Cooling_Method 'immersion'
            ($Result.Body | ConvertFrom-Json).cooling_method | Should -Be 'immersion'

            $Result = Set-NBDCIMDevice -Id 1 -Cooling_Method ''
            $Result.Body | Should -Match '"cooling_method":null'
        }

        It "Get-NBDCIMDevice emits the (scalar) cooling_method filter" {
            $Result = Get-NBDCIMDevice -Cooling_Method 'air'
            $Result.Uri | Should -Match 'cooling_method=air'
        }

        It "New-NBDCIMDeviceType sends cooling_method" {
            $Result = New-NBDCIMDeviceType -Manufacturer 1 -Model 'X1' -Cooling_Method 'hybrid'
            ($Result.Body | ConvertFrom-Json).cooling_method | Should -Be 'hybrid'
        }

        It "New-NBDCIMDeviceType rejects an unknown cooling method" {
            { New-NBDCIMDeviceType -Manufacturer 1 -Model 'X1' -Cooling_Method 'water' } | Should -Throw
        }

        It "Set-NBDCIMDeviceType sends cooling_method and translates '' to null" {
            $Result = Set-NBDCIMDeviceType -Id 3 -Cooling_Method 'air'
            ($Result.Body | ConvertFrom-Json).cooling_method | Should -Be 'air'

            $Result = Set-NBDCIMDeviceType -Id 3 -Cooling_Method ''
            $Result.Body | Should -Match '"cooling_method":null'
        }

        It "Get-NBDCIMDeviceType emits the cooling_method filter" {
            $Result = Get-NBDCIMDeviceType -Cooling_Method 'immersion'
            $Result.Uri | Should -Match 'cooling_method=immersion'
        }

        It "New-NBDCIMModuleType sends cooling_method" {
            $Result = New-NBDCIMModuleType -Manufacturer 1 -Model 'M1' -Cooling_Method 'air'
            ($Result.Body | ConvertFrom-Json).cooling_method | Should -Be 'air'
        }

        It "Set-NBDCIMModuleType sends cooling_method and translates '' to null" {
            $Result = Set-NBDCIMModuleType -Id 3 -Cooling_Method 'liquid'
            ($Result.Body | ConvertFrom-Json).cooling_method | Should -Be 'liquid'

            $Result = Set-NBDCIMModuleType -Id 3 -Cooling_Method ''
            $Result.Body | Should -Match '"cooling_method":null'
        }

        It "Get-NBDCIMModuleType emits the cooling_method filter" {
            $Result = Get-NBDCIMModuleType -Cooling_Method 'hybrid'
            $Result.Uri | Should -Match 'cooling_method=hybrid'
        }
    }

    Context "End of life on DeviceType / ModuleType (NetBox 4.7+)" {
        It "New-NBDCIMDeviceType serializes end_of_life as yyyy-MM-dd" {
            $Result = New-NBDCIMDeviceType -Manufacturer 1 -Model 'X1' -End_Of_Life (Get-Date '2030-06-30')
            ($Result.Body | ConvertFrom-Json).end_of_life | Should -Be '2030-06-30'
        }

        It "Set-NBDCIMDeviceType serializes end_of_life and sends null to clear" {
            $Result = Set-NBDCIMDeviceType -Id 3 -End_Of_Life '2031-01-15'
            ($Result.Body | ConvertFrom-Json).end_of_life | Should -Be '2031-01-15'

            $Result = Set-NBDCIMDeviceType -Id 3 -End_Of_Life $null
            $Result.Body | Should -Match '"end_of_life":null'
        }

        It "Get-NBDCIMDeviceType emits end_of_life filter values as yyyy-MM-dd" {
            $Result = Get-NBDCIMDeviceType -End_Of_Life (Get-Date '2030-06-30'), (Get-Date '2031-01-15')
            $Result.Uri | Should -Match 'end_of_life=2030-06-30'
            $Result.Uri | Should -Match 'end_of_life=2031-01-15'
        }

        It "New-NBDCIMModuleType serializes end_of_life as yyyy-MM-dd" {
            $Result = New-NBDCIMModuleType -Manufacturer 1 -Model 'M1' -End_Of_Life '2029-12-31'
            ($Result.Body | ConvertFrom-Json).end_of_life | Should -Be '2029-12-31'
        }

        It "Set-NBDCIMModuleType serializes end_of_life and sends null to clear" {
            $Result = Set-NBDCIMModuleType -Id 3 -End_Of_Life (Get-Date '2029-12-31')
            ($Result.Body | ConvertFrom-Json).end_of_life | Should -Be '2029-12-31'

            $Result = Set-NBDCIMModuleType -Id 3 -End_Of_Life $null
            $Result.Body | Should -Match '"end_of_life":null'
        }

        It "Get-NBDCIMModuleType emits the end_of_life filter" {
            $Result = Get-NBDCIMModuleType -End_Of_Life '2029-12-31'
            $Result.Uri | Should -Match 'end_of_life=2029-12-31'
        }
    }
    #endregion

    #region Rack cooling
    Context "Rack / RackType: -Cooling_Capability / -Cooling_Capacity (NetBox 4.7+)" {
        It "New-NBDCIMRack sends cooling_capability and cooling_capacity" {
            $Result = New-NBDCIMRack -Name 'R1' -Site 1 -Cooling_Capability 'liquid-only' -Cooling_Capacity 12.5
            $body = $Result.Body | ConvertFrom-Json
            $body.cooling_capability | Should -Be 'liquid-only'
            $body.cooling_capacity | Should -Be 12.5
        }

        It "New-NBDCIMRack rejects an unknown cooling capability" {
            { New-NBDCIMRack -Name 'R1' -Site 1 -Cooling_Capability 'water' } | Should -Throw
        }

        It "New-NBDCIMRack still sends the deprecated geometry fields (verbose note only)" {
            $Result = New-NBDCIMRack -Name 'R1' -Site 1 -Width 19 -Form_Factor '4-post-cabinet' -Outer_Width 600 -WarningVariable warn -WarningAction SilentlyContinue
            $body = $Result.Body | ConvertFrom-Json
            $body.width | Should -Be 19
            $body.form_factor | Should -Be '4-post-cabinet'
            $body.outer_width | Should -Be 600
            $warn | Should -BeNullOrEmpty
        }

        It "Set-NBDCIMRack sends cooling fields, '' clears capability, `$null clears capacity" {
            $Result = Set-NBDCIMRack -Id 1 -Cooling_Capability 'hybrid' -Cooling_Capacity 7.25
            $body = $Result.Body | ConvertFrom-Json
            $body.cooling_capability | Should -Be 'hybrid'
            $body.cooling_capacity | Should -Be 7.25

            $Result = Set-NBDCIMRack -Id 1 -Cooling_Capability '' -Cooling_Capacity $null
            $Result.Body | Should -Match '"cooling_capability":null'
            $Result.Body | Should -Match '"cooling_capacity":null'
        }

        It "Get-NBDCIMRack emits repeat-key cooling filters" {
            $Result = Get-NBDCIMRack -Cooling_Capability 'air-only', 'hybrid' -Cooling_Capacity 10, 12.5
            $Result.Uri | Should -Match 'cooling_capability=air-only'
            $Result.Uri | Should -Match 'cooling_capability=hybrid'
            $Result.Uri | Should -Match 'cooling_capacity=10'
            $Result.Uri | Should -Match 'cooling_capacity=12.5'
        }

        It "New-NBDCIMRackType sends cooling_capability and cooling_capacity" {
            $Result = New-NBDCIMRackType -Manufacturer 1 -Model 'RT1' -Form_Factor '4-post-cabinet' -Cooling_Capability 'air-only' -Cooling_Capacity 5
            $body = $Result.Body | ConvertFrom-Json
            $body.cooling_capability | Should -Be 'air-only'
            $body.cooling_capacity | Should -Be 5
        }

        It "Set-NBDCIMRackType sends cooling fields and clears them" {
            $Result = Set-NBDCIMRackType -Id 2 -Cooling_Capability 'liquid-only' -Cooling_Capacity 30
            $body = $Result.Body | ConvertFrom-Json
            $body.cooling_capability | Should -Be 'liquid-only'
            $body.cooling_capacity | Should -Be 30

            $Result = Set-NBDCIMRackType -Id 2 -Cooling_Capability '' -Cooling_Capacity $null
            $Result.Body | Should -Match '"cooling_capability":null'
            $Result.Body | Should -Match '"cooling_capacity":null'
        }

        It "Get-NBDCIMRackType emits cooling filters" {
            $Result = Get-NBDCIMRackType -Cooling_Capability 'hybrid' -Cooling_Capacity 30
            $Result.Uri | Should -Match 'cooling_capability=hybrid'
            $Result.Uri | Should -Match 'cooling_capacity=30'
        }
    }
    #endregion

    #region Version gate
    Context "Below NetBox 4.7 the new parameters are dropped with a warning" {
        BeforeAll { InModuleScope -ModuleName 'PowerNetbox' { $script:NetboxConfig.ParsedVersion = [version]'4.6.10' } }
        AfterAll { InModuleScope -ModuleName 'PowerNetbox' { $script:NetboxConfig.ParsedVersion = [version]'4.7.0' } }

        # One case per (cmdlet, parameter). 'Base' carries the mandatory params
        # plus a harmless sibling field so the body is never empty.
        $writeCases = @(
            @{ Cmd = 'New-NBDCIMInterface'; Param = 'Channels';    Value = 4;                   Field = 'channels';    Base = @{ Device = 1; Name = 'eth0'; Type = '1000base-t' } }
            @{ Cmd = 'New-NBDCIMInterface'; Param = 'Channel_Id';  Value = 1;                   Field = 'channel_id';  Base = @{ Device = 1; Name = 'eth0'; Type = 'channel' } }
            @{ Cmd = 'New-NBDCIMInterface'; Param = 'MAC_Address'; Value = '00:11:22:33:44:55'; Field = 'mac_address'; Base = @{ Device = 1; Name = 'eth0'; Type = '1000base-t' } }
            @{ Cmd = 'Set-NBDCIMInterface'; Param = 'Channels';    Value = 4;                   Field = 'channels';    Base = @{ Id = 1; Description = 'x' } }
            @{ Cmd = 'Set-NBDCIMInterface'; Param = 'Channel_Id';  Value = 1;                   Field = 'channel_id';  Base = @{ Id = 1; Description = 'x' } }
            @{ Cmd = 'Set-NBDCIMInterface'; Param = 'MAC_Address'; Value = '00:11:22:33:44:55'; Field = 'mac_address'; Base = @{ Id = 1; Description = 'x' } }
            @{ Cmd = 'New-NBDCIMInterfaceTemplate'; Param = 'Channels';   Value = 4; Field = 'channels';   Base = @{ Device_Type = 1; Name = 'eth0'; Type = '1000base-t' } }
            @{ Cmd = 'New-NBDCIMInterfaceTemplate'; Param = 'Channel_Id'; Value = 1; Field = 'channel_id'; Base = @{ Device_Type = 1; Name = 'eth0'; Type = 'channel' } }
            @{ Cmd = 'Set-NBDCIMInterfaceTemplate'; Param = 'Channels';   Value = 4; Field = 'channels';   Base = @{ Id = 1; Description = 'x' } }
            @{ Cmd = 'Set-NBDCIMInterfaceTemplate'; Param = 'Channel_Id'; Value = 1; Field = 'channel_id'; Base = @{ Id = 1; Description = 'x' } }
            @{ Cmd = 'New-NBDCIMDevice';     Param = 'Cooling_Method'; Value = 'air'; Field = 'cooling_method'; Base = @{ Name = 'srv1'; Role = 1; Device_Type = 1; Site = 1 } }
            @{ Cmd = 'Set-NBDCIMDevice';     Param = 'Cooling_Method'; Value = 'air'; Field = 'cooling_method'; Base = @{ Id = 1; Description = 'x' } }
            @{ Cmd = 'New-NBDCIMDeviceType'; Param = 'Cooling_Method'; Value = 'air'; Field = 'cooling_method'; Base = @{ Manufacturer = 1; Model = 'X1' } }
            @{ Cmd = 'New-NBDCIMDeviceType'; Param = 'End_Of_Life';    Value = '2030-06-30'; Field = 'end_of_life'; Base = @{ Manufacturer = 1; Model = 'X1' } }
            @{ Cmd = 'Set-NBDCIMDeviceType'; Param = 'Cooling_Method'; Value = 'air'; Field = 'cooling_method'; Base = @{ Id = 1; Description = 'x' } }
            @{ Cmd = 'Set-NBDCIMDeviceType'; Param = 'End_Of_Life';    Value = '2030-06-30'; Field = 'end_of_life'; Base = @{ Id = 1; Description = 'x' } }
            @{ Cmd = 'New-NBDCIMModuleType'; Param = 'Cooling_Method'; Value = 'air'; Field = 'cooling_method'; Base = @{ Manufacturer = 1; Model = 'M1' } }
            @{ Cmd = 'New-NBDCIMModuleType'; Param = 'End_Of_Life';    Value = '2030-06-30'; Field = 'end_of_life'; Base = @{ Manufacturer = 1; Model = 'M1' } }
            @{ Cmd = 'Set-NBDCIMModuleType'; Param = 'Cooling_Method'; Value = 'air'; Field = 'cooling_method'; Base = @{ Id = 1; Description = 'x' } }
            @{ Cmd = 'Set-NBDCIMModuleType'; Param = 'End_Of_Life';    Value = '2030-06-30'; Field = 'end_of_life'; Base = @{ Id = 1; Description = 'x' } }
            @{ Cmd = 'New-NBDCIMRack';     Param = 'Cooling_Capability'; Value = 'hybrid'; Field = 'cooling_capability'; Base = @{ Name = 'R1'; Site = 1 } }
            @{ Cmd = 'New-NBDCIMRack';     Param = 'Cooling_Capacity';   Value = 12.5;     Field = 'cooling_capacity';   Base = @{ Name = 'R1'; Site = 1 } }
            @{ Cmd = 'Set-NBDCIMRack';     Param = 'Cooling_Capability'; Value = 'hybrid'; Field = 'cooling_capability'; Base = @{ Id = 1; Description = 'x' } }
            @{ Cmd = 'Set-NBDCIMRack';     Param = 'Cooling_Capacity';   Value = 12.5;     Field = 'cooling_capacity';   Base = @{ Id = 1; Description = 'x' } }
            @{ Cmd = 'New-NBDCIMRackType'; Param = 'Cooling_Capability'; Value = 'hybrid'; Field = 'cooling_capability'; Base = @{ Manufacturer = 1; Model = 'RT1'; Form_Factor = '4-post-cabinet' } }
            @{ Cmd = 'New-NBDCIMRackType'; Param = 'Cooling_Capacity';   Value = 12.5;     Field = 'cooling_capacity';   Base = @{ Manufacturer = 1; Model = 'RT1'; Form_Factor = '4-post-cabinet' } }
            @{ Cmd = 'Set-NBDCIMRackType'; Param = 'Cooling_Capability'; Value = 'hybrid'; Field = 'cooling_capability'; Base = @{ Id = 1; Description = 'x' } }
            @{ Cmd = 'Set-NBDCIMRackType'; Param = 'Cooling_Capacity';   Value = 12.5;     Field = 'cooling_capacity';   Base = @{ Id = 1; Description = 'x' } }
        )

        It "<Cmd> drops -<Param> from the body with a warning" -TestCases $writeCases {
            $splat = @{} + $Base
            $splat[$Param] = $Value
            $Result = & $Cmd @splat -WarningVariable warn -WarningAction SilentlyContinue
            $warn | Should -Match "requires Netbox 4.7.0"
            $Result.Body | Should -Not -BeNullOrEmpty
            $body = $Result.Body | ConvertFrom-Json
            $body.PSObject.Properties.Name | Should -Not -Contain $Field
        }

        $filterCases = @(
            @{ Cmd = 'Get-NBDCIMInterface';         Param = 'Channels';           Value = 4;            Field = 'channels' }
            @{ Cmd = 'Get-NBDCIMInterface';         Param = 'Channel_Id';         Value = 1;            Field = 'channel_id' }
            @{ Cmd = 'Get-NBDCIMInterfaceTemplate'; Param = 'Channels';           Value = 4;            Field = 'channels' }
            @{ Cmd = 'Get-NBDCIMInterfaceTemplate'; Param = 'Channel_Id';         Value = 1;            Field = 'channel_id' }
            @{ Cmd = 'Get-NBDCIMDevice';            Param = 'Cooling_Method';     Value = 'air';        Field = 'cooling_method' }
            @{ Cmd = 'Get-NBDCIMDeviceType';        Param = 'Cooling_Method';     Value = 'air';        Field = 'cooling_method' }
            @{ Cmd = 'Get-NBDCIMDeviceType';        Param = 'End_Of_Life';        Value = '2030-06-30'; Field = 'end_of_life' }
            @{ Cmd = 'Get-NBDCIMModuleType';        Param = 'Cooling_Method';     Value = 'air';        Field = 'cooling_method' }
            @{ Cmd = 'Get-NBDCIMModuleType';        Param = 'End_Of_Life';        Value = '2030-06-30'; Field = 'end_of_life' }
            @{ Cmd = 'Get-NBDCIMRack';              Param = 'Cooling_Capability'; Value = 'hybrid';     Field = 'cooling_capability' }
            @{ Cmd = 'Get-NBDCIMRack';              Param = 'Cooling_Capacity';   Value = 12.5;         Field = 'cooling_capacity' }
            @{ Cmd = 'Get-NBDCIMRackType';          Param = 'Cooling_Capability'; Value = 'hybrid';     Field = 'cooling_capability' }
            @{ Cmd = 'Get-NBDCIMRackType';          Param = 'Cooling_Capacity';   Value = 12.5;         Field = 'cooling_capacity' }
        )

        It "<Cmd> drops the -<Param> filter with a warning" -TestCases $filterCases {
            $splat = @{ $Param = $Value }
            $Result = & $Cmd @splat -WarningVariable warn -WarningAction SilentlyContinue
            $warn | Should -Match "requires Netbox 4.7.0"
            $Result.Uri | Should -Not -Match $Field
        }
    }
    #endregion
}
