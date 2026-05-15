<#
.SYNOPSIS
    Unit tests for additional DCIM module functions.

.DESCRIPTION
    Tests for DCIM endpoints not covered in other DCIM test files:
    Cables, Locations, Regions, SiteGroups, Manufacturers, Racks (extended),
    RackTypes, RackRoles, RackReservations, ConsolePorts, ConsoleServerPorts,
    PowerPorts, PowerOutlets, PowerPanels, PowerFeeds, DeviceBays, Modules,
    ModuleTypes, ModuleBays, ModuleTypeProfiles, InventoryItems, InventoryItemRoles,
    FrontPorts, RearPorts, InterfaceTemplates, MACAddresses, VirtualChassis, VirtualDeviceContexts
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

Describe "DCIM Additional Tests" -Tag 'DCIM' {
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

    #region Cables
    Context "Get-NBDCIMCable" {
        It "Should request cables" {
            $Result = Get-NBDCIMCable
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cables/'
        }

        It "Should request a cable by ID" {
            $Result = Get-NBDCIMCable -Id 5
            $Result.Uri | Should -Match '/api/dcim/cables/5/'
        }
    }

    Context "New-NBDCIMCable" {
        It "Should create a cable with termination objects" {
            $aTerm = @(@{object_type="dcim.interface"; object_id=1})
            $bTerm = @(@{object_type="dcim.interface"; object_id=2})
            $Result = New-NBDCIMCable -A_Terminations $aTerm -B_Terminations $bTerm -Confirm:$false
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cables/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.a_terminations[0].object_type | Should -Be 'dcim.interface'
            $bodyObj.a_terminations[0].object_id | Should -Be 1
            $bodyObj.b_terminations[0].object_type | Should -Be 'dcim.interface'
            $bodyObj.b_terminations[0].object_id | Should -Be 2
        }
    }

    Context "Set-NBDCIMCable" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMCable" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id }
            }
        }

        It "Should update a cable" {
            $Result = Set-NBDCIMCable -Id 1 -Label 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/dcim/cables/1/'
        }
    }

    Context "Remove-NBDCIMCable" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMCable" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id }
            }
        }

        It "Should remove a cable" {
            $Result = Remove-NBDCIMCable -Id 3 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/dcim/cables/3/'
        }
    }

    Context "Cable Profile Support (4.5+)" {
        # The 26 real CableProfileChoices values from netbox/dcim/choices.py
        # as of v4.5.7. Kept as script-scope so tests can iterate.
        BeforeAll {
            $script:ValidCableProfiles = @(
                # Single (1 connector)
                'single-1c1p', 'single-1c2p', 'single-1c4p', 'single-1c6p',
                'single-1c8p', 'single-1c12p', 'single-1c16p',
                # Trunks (multi-connector)
                'trunk-2c1p', 'trunk-2c2p', 'trunk-2c4p', 'trunk-2c4p-shuffle',
                'trunk-2c6p', 'trunk-2c8p', 'trunk-2c12p',
                'trunk-4c1p', 'trunk-4c2p', 'trunk-4c4p', 'trunk-4c4p-shuffle',
                'trunk-4c6p', 'trunk-4c8p', 'trunk-8c4p',
                # Breakouts
                'breakout-1c2p-2c1p',       # added in 4.5.7 (#21760)
                'breakout-1c4p-4c1p',
                'breakout-1c6p-6c1p',
                'breakout-2c4p-8c1p-shuffle'
            )
        }

        It "Should include Profile in New-NBDCIMCable body on Netbox 4.5+" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.ParsedVersion = [version]'4.5.0'
            }
            $aTerm = @(@{object_type="dcim.interface"; object_id=1})
            $bTerm = @(@{object_type="dcim.interface"; object_id=2})
            $Result = New-NBDCIMCable -A_Terminations $aTerm -B_Terminations $bTerm -Profile 'breakout-1c4p-4c1p' -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.profile | Should -Be 'breakout-1c4p-4c1p'
        }

        It "Should exclude Profile from New-NBDCIMCable body on Netbox 4.4.x" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.ParsedVersion = [version]'4.4.9'
            }
            $aTerm = @(@{object_type="dcim.interface"; object_id=1})
            $bTerm = @(@{object_type="dcim.interface"; object_id=2})
            $Result = New-NBDCIMCable -A_Terminations $aTerm -B_Terminations $bTerm -Profile 'breakout-1c4p-4c1p' -Confirm:$false -WarningAction SilentlyContinue
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.PSObject.Properties.Name | Should -Not -Contain 'profile'
        }

        It "Should include Profile in Set-NBDCIMCable body on Netbox 4.5+" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.ParsedVersion = [version]'4.5.0'
            }
            $Result = Set-NBDCIMCable -Id 1 -Profile 'trunk-2c4p' -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.profile | Should -Be 'trunk-2c4p'
        }

        It "Should exclude Profile from Set-NBDCIMCable body on Netbox 4.4.x" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.ParsedVersion = [version]'4.4.9'
            }
            $Result = Set-NBDCIMCable -Id 1 -Profile 'trunk-2c4p' -Confirm:$false -WarningAction SilentlyContinue
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.PSObject.Properties.Name | Should -Not -Contain 'profile'
        }

        It "Should include Profile filter in Get-NBDCIMCable on Netbox 4.5+" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.ParsedVersion = [version]'4.5.0'
            }
            $Result = Get-NBDCIMCable -Profile 'breakout-1c4p-4c1p'
            $Result.Uri | Should -Match 'profile=breakout-1c4p-4c1p'
        }

        It "Should exclude Profile filter from Get-NBDCIMCable on Netbox 4.4.x" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.ParsedVersion = [version]'4.4.9'
            }
            $Result = Get-NBDCIMCable -Profile 'breakout-1c4p-4c1p' -WarningAction SilentlyContinue
            $Result.Uri | Should -Not -Match 'profile='
        }

        It "Should accept all 25 real CableProfileChoices values on New-NBDCIMCable (#389)" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.ParsedVersion = [version]'4.5.7'
            }
            $aTerm = @(@{object_type="dcim.interface"; object_id=1})
            $bTerm = @(@{object_type="dcim.interface"; object_id=2})
            foreach ($profile in $script:ValidCableProfiles) {
                $Result = New-NBDCIMCable -A_Terminations $aTerm -B_Terminations $bTerm -Profile $profile -Confirm:$false
                $bodyObj = $Result.Body | ConvertFrom-Json
                $bodyObj.profile | Should -Be $profile -Because "$profile is a real plugin value"
            }
        }

        It "Should accept all 25 real CableProfileChoices values on Get-NBDCIMCable (#389)" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.ParsedVersion = [version]'4.5.7'
            }
            foreach ($profile in $script:ValidCableProfiles) {
                $Result = Get-NBDCIMCable -Profile $profile
                $Result.Uri | Should -Match "profile=$([regex]::Escape($profile))" -Because "$profile is a real plugin value"
            }
        }

        It "Should accept all 25 real CableProfileChoices values on Set-NBDCIMCable (#389)" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.ParsedVersion = [version]'4.5.7'
            }
            foreach ($profile in $script:ValidCableProfiles) {
                $Result = Set-NBDCIMCable -Id 1 -Profile $profile -Confirm:$false
                $bodyObj = $Result.Body | ConvertFrom-Json
                $bodyObj.profile | Should -Be $profile -Because "$profile is a real plugin value"
            }
        }

        It "Should reject the old prefix-stripped values on New-NBDCIMCable (#389)" {
            # Before the fix these broken values passed validation and produced
            # garbage API requests. They must now be rejected at binding time.
            $aTerm = @(@{object_type="dcim.interface"; object_id=1})
            $bTerm = @(@{object_type="dcim.interface"; object_id=2})
            foreach ($broken in @('1c1p', '2c4p', '1c4p-4c1p', '4c4p-shuffle')) {
                { New-NBDCIMCable -A_Terminations $aTerm -B_Terminations $bTerm -Profile $broken -Confirm:$false } |
                    Should -Throw -Because "'$broken' is not a real plugin value and must be rejected"
            }
        }

        It "Should reject the old prefix-stripped values on Get-NBDCIMCable (#389)" {
            foreach ($broken in @('1c1p', '2c4p', '1c4p-4c1p', '4c4p-shuffle')) {
                { Get-NBDCIMCable -Profile $broken } |
                    Should -Throw -Because "'$broken' is not a real plugin value and must be rejected"
            }
        }

        It "Should reject the old prefix-stripped values on Set-NBDCIMCable (#389)" {
            foreach ($broken in @('1c1p', '2c4p', '1c4p-4c1p', '4c4p-shuffle')) {
                { Set-NBDCIMCable -Id 1 -Profile $broken -Confirm:$false } |
                    Should -Throw -Because "'$broken' is not a real plugin value and must be rejected"
            }
        }

        It "Should accept the new 'breakout-1c2p-2c1p' profile from Netbox 4.5.7 (#389, #21760)" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.ParsedVersion = [version]'4.5.7'
            }
            $aTerm = @(@{object_type="dcim.interface"; object_id=1})
            $bTerm = @(@{object_type="dcim.interface"; object_id=2})
            $Result = New-NBDCIMCable -A_Terminations $aTerm -B_Terminations $bTerm -Profile 'breakout-1c2p-2c1p' -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.profile | Should -Be 'breakout-1c2p-2c1p'
        }
    }
    #endregion

    #region Locations
    Context "Get-NBDCIMLocation" {
        It "Should request locations" {
            $Result = Get-NBDCIMLocation
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/locations/'
        }

        It "Should request a location by ID" {
            $Result = Get-NBDCIMLocation -Id 5
            $Result.Uri | Should -Match '/api/dcim/locations/5/'
        }

        It "Should request a location by name" {
            $Result = Get-NBDCIMLocation -Name 'Floor1'
            $Result.Uri | Should -Match 'name=Floor1'
        }
    }

    Context "New-NBDCIMLocation" {
        It "Should create a location" {
            $Result = New-NBDCIMLocation -Name 'TestLoc' -Slug 'test-loc' -Site 1
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/locations/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'TestLoc'
            $bodyObj.slug | Should -Be 'test-loc'
            $bodyObj.site | Should -Be 1
        }
    }

    Context "Set-NBDCIMLocation" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMLocation" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestLoc' }
            }
        }

        It "Should update a location" {
            $Result = Set-NBDCIMLocation -Id 1 -Name 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/dcim/locations/1/'
        }
    }

    Context "Remove-NBDCIMLocation" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMLocation" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestLoc' }
            }
        }

        It "Should remove a location" {
            $Result = Remove-NBDCIMLocation -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/dcim/locations/2/'
        }
    }
    #endregion

    #region Regions
    Context "Get-NBDCIMRegion" {
        It "Should request regions" {
            $Result = Get-NBDCIMRegion
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/regions/'
        }

        It "Should request a region by ID" {
            $Result = Get-NBDCIMRegion -Id 3
            $Result.Uri | Should -Match '/api/dcim/regions/3/'
        }
    }

    Context "New-NBDCIMRegion" {
        It "Should create a region" {
            $Result = New-NBDCIMRegion -Name 'Europe' -Slug 'europe'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/regions/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'Europe'
            $bodyObj.slug | Should -Be 'europe'
        }
    }

    Context "Set-NBDCIMRegion" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMRegion" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestRegion' }
            }
        }

        It "Should update a region" {
            $Result = Set-NBDCIMRegion -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/dcim/regions/1/'
        }
    }

    Context "Remove-NBDCIMRegion" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMRegion" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestRegion' }
            }
        }

        It "Should remove a region" {
            $Result = Remove-NBDCIMRegion -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/dcim/regions/2/'
        }
    }
    #endregion

    #region SiteGroups
    Context "Get-NBDCIMSiteGroup" {
        It "Should request site groups" {
            $Result = Get-NBDCIMSiteGroup
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/site-groups/'
        }

        It "Should request a site group by ID" {
            $Result = Get-NBDCIMSiteGroup -Id 4
            $Result.Uri | Should -Match '/api/dcim/site-groups/4/'
        }
    }

    Context "New-NBDCIMSiteGroup" {
        It "Should create a site group" {
            $Result = New-NBDCIMSiteGroup -Name 'DataCenters' -Slug 'datacenters'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/site-groups/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'DataCenters'
        }
    }

    Context "Set-NBDCIMSiteGroup" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMSiteGroup" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestGroup' }
            }
        }

        It "Should update a site group" {
            $Result = Set-NBDCIMSiteGroup -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/dcim/site-groups/1/'
        }
    }

    Context "Remove-NBDCIMSiteGroup" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMSiteGroup" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestGroup' }
            }
        }

        It "Should remove a site group" {
            $Result = Remove-NBDCIMSiteGroup -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/dcim/site-groups/2/'
        }
    }
    #endregion

    #region Manufacturers
    Context "Get-NBDCIMManufacturer" {
        It "Should request manufacturers" {
            $Result = Get-NBDCIMManufacturer
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/manufacturers/'
        }

        It "Should request a manufacturer by ID" {
            $Result = Get-NBDCIMManufacturer -Id 5
            $Result.Uri | Should -Match '/api/dcim/manufacturers/5/'
        }

        It "Should request a manufacturer by name" {
            $Result = Get-NBDCIMManufacturer -Name 'Cisco'
            $Result.Uri | Should -Match 'name=Cisco'
        }
    }

    Context "New-NBDCIMManufacturer" {
        It "Should create a manufacturer" {
            $Result = New-NBDCIMManufacturer -Name 'Juniper' -Slug 'juniper'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/manufacturers/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'Juniper'
            $bodyObj.slug | Should -Be 'juniper'
        }
    }

    Context "Set-NBDCIMManufacturer" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMManufacturer" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestMfr' }
            }
        }

        It "Should update a manufacturer" {
            $Result = Set-NBDCIMManufacturer -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/dcim/manufacturers/1/'
        }
    }

    Context "Remove-NBDCIMManufacturer" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMManufacturer" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestMfr' }
            }
        }

        It "Should remove a manufacturer" {
            $Result = Remove-NBDCIMManufacturer -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/dcim/manufacturers/2/'
        }
    }
    #endregion

    #region RackTypes
    Context "Get-NBDCIMRackType" {
        It "Should request rack types" {
            $Result = Get-NBDCIMRackType
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/rack-types/'
        }

        It "Should request a rack type by ID" {
            $Result = Get-NBDCIMRackType -Id 3
            $Result.Uri | Should -Match '/api/dcim/rack-types/3/'
        }
    }

    Context "New-NBDCIMRackType" {
        It "Should create a rack type" {
            $Result = New-NBDCIMRackType -Manufacturer 1 -Model 'Standard42U' -Form_Factor '2-post-frame'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/rack-types/'
        }
    }

    Context "Set-NBDCIMRackType" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMRackType" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Model' = 'TestType' }
            }
        }

        It "Should update a rack type" {
            $Result = Set-NBDCIMRackType -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/dcim/rack-types/1/'
        }
    }

    Context "Remove-NBDCIMRackType" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMRackType" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Model' = 'TestType' }
            }
        }

        It "Should remove a rack type" {
            $Result = Remove-NBDCIMRackType -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/dcim/rack-types/2/'
        }
    }
    #endregion

    #region RackRoles
    Context "Get-NBDCIMRackRole" {
        It "Should request rack roles" {
            $Result = Get-NBDCIMRackRole
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/rack-roles/'
        }

        It "Should request a rack role by ID" {
            $Result = Get-NBDCIMRackRole -Id 2
            $Result.Uri | Should -Match '/api/dcim/rack-roles/2/'
        }
    }

    Context "New-NBDCIMRackRole" {
        It "Should create a rack role" {
            $Result = New-NBDCIMRackRole -Name 'Network' -Slug 'network'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/rack-roles/'
        }
    }

    Context "Set-NBDCIMRackRole" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMRackRole" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestRole' }
            }
        }

        It "Should update a rack role" {
            $Result = Set-NBDCIMRackRole -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/dcim/rack-roles/1/'
        }
    }

    Context "Remove-NBDCIMRackRole" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMRackRole" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestRole' }
            }
        }

        It "Should remove a rack role" {
            $Result = Remove-NBDCIMRackRole -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/dcim/rack-roles/2/'
        }
    }
    #endregion

    #region RackReservations
    Context "Get-NBDCIMRackReservation" {
        It "Should request rack reservations" {
            $Result = Get-NBDCIMRackReservation
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/rack-reservations/'
        }

        It "Should request a rack reservation by ID" {
            $Result = Get-NBDCIMRackReservation -Id 5
            $Result.Uri | Should -Match '/api/dcim/rack-reservations/5/'
        }
    }

    Context "New-NBDCIMRackReservation" {
        It "Should create a rack reservation" {
            $Result = New-NBDCIMRackReservation -Rack 1 -Units @(1,2,3) -User 1 -Description 'Test'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/rack-reservations/'
        }
    }

    Context "Set-NBDCIMRackReservation" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMRackReservation" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id }
            }
        }

        It "Should update a rack reservation" {
            $Result = Set-NBDCIMRackReservation -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/dcim/rack-reservations/1/'
        }
    }

    Context "Remove-NBDCIMRackReservation" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMRackReservation" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id }
            }
        }

        It "Should remove a rack reservation" {
            $Result = Remove-NBDCIMRackReservation -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/dcim/rack-reservations/2/'
        }
    }
    #endregion

    #region ConsolePorts
    Context "Get-NBDCIMConsolePort" {
        It "Should request console ports" {
            $Result = Get-NBDCIMConsolePort
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/console-ports/'
        }

        It "Should request a console port by ID" {
            $Result = Get-NBDCIMConsolePort -Id 5
            $Result.Uri | Should -Match '/api/dcim/console-ports/5/'
        }
    }

    Context "New-NBDCIMConsolePort" {
        It "Should create a console port" {
            $Result = New-NBDCIMConsolePort -Device 1 -Name 'con0'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/console-ports/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.device | Should -Be 1
            $bodyObj.name | Should -Be 'con0'
        }
    }

    Context "Set-NBDCIMConsolePort" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMConsolePort" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'con0' }
            }
        }

        It "Should update a console port" {
            $Result = Set-NBDCIMConsolePort -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/dcim/console-ports/1/'
        }
    }

    Context "Remove-NBDCIMConsolePort" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMConsolePort" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'con0' }
            }
        }

        It "Should remove a console port" {
            $Result = Remove-NBDCIMConsolePort -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/dcim/console-ports/2/'
        }
    }
    #endregion

    #region ConsoleServerPorts
    Context "Get-NBDCIMConsoleServerPort" {
        It "Should request console server ports" {
            $Result = Get-NBDCIMConsoleServerPort
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/console-server-ports/'
        }

        It "Should request a console server port by ID" {
            $Result = Get-NBDCIMConsoleServerPort -Id 5
            $Result.Uri | Should -Match '/api/dcim/console-server-ports/5/'
        }
    }

    Context "New-NBDCIMConsoleServerPort" {
        It "Should create a console server port" {
            $Result = New-NBDCIMConsoleServerPort -Device 1 -Name 'port1'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/console-server-ports/'
        }
    }

    Context "Set-NBDCIMConsoleServerPort" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMConsoleServerPort" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'port1' }
            }
        }

        It "Should update a console server port" {
            $Result = Set-NBDCIMConsoleServerPort -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/dcim/console-server-ports/1/'
        }
    }

    Context "Remove-NBDCIMConsoleServerPort" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMConsoleServerPort" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'port1' }
            }
        }

        It "Should remove a console server port" {
            $Result = Remove-NBDCIMConsoleServerPort -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/dcim/console-server-ports/2/'
        }
    }
    #endregion

    #region PowerPorts
    Context "Get-NBDCIMPowerPort" {
        It "Should request power ports" {
            $Result = Get-NBDCIMPowerPort
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/power-ports/'
        }

        It "Should request a power port by ID" {
            $Result = Get-NBDCIMPowerPort -Id 5
            $Result.Uri | Should -Match '/api/dcim/power-ports/5/'
        }
    }

    Context "New-NBDCIMPowerPort" {
        It "Should create a power port" {
            $Result = New-NBDCIMPowerPort -Device 1 -Name 'PSU1'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/power-ports/'
        }
    }

    Context "Set-NBDCIMPowerPort" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMPowerPort" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'PSU1' }
            }
        }

        It "Should update a power port" {
            $Result = Set-NBDCIMPowerPort -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/dcim/power-ports/1/'
        }
    }

    Context "Remove-NBDCIMPowerPort" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMPowerPort" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'PSU1' }
            }
        }

        It "Should remove a power port" {
            $Result = Remove-NBDCIMPowerPort -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/dcim/power-ports/2/'
        }
    }
    #endregion

    #region PowerOutlets
    Context "Get-NBDCIMPowerOutlet" {
        It "Should request power outlets" {
            $Result = Get-NBDCIMPowerOutlet
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/power-outlets/'
        }

        It "Should request a power outlet by ID" {
            $Result = Get-NBDCIMPowerOutlet -Id 5
            $Result.Uri | Should -Match '/api/dcim/power-outlets/5/'
        }
    }

    Context "New-NBDCIMPowerOutlet" {
        It "Should create a power outlet" {
            $Result = New-NBDCIMPowerOutlet -Device 1 -Name 'Outlet1'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/power-outlets/'
        }
    }

    Context "Set-NBDCIMPowerOutlet" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMPowerOutlet" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'Outlet1' }
            }
        }

        It "Should update a power outlet" {
            $Result = Set-NBDCIMPowerOutlet -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/dcim/power-outlets/1/'
        }
    }

    Context "Remove-NBDCIMPowerOutlet" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMPowerOutlet" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'Outlet1' }
            }
        }

        It "Should remove a power outlet" {
            $Result = Remove-NBDCIMPowerOutlet -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/dcim/power-outlets/2/'
        }
    }
    #endregion

    #region PowerPanels
    Context "Get-NBDCIMPowerPanel" {
        It "Should request power panels" {
            $Result = Get-NBDCIMPowerPanel
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/power-panels/'
        }

        It "Should request a power panel by ID" {
            $Result = Get-NBDCIMPowerPanel -Id 5
            $Result.Uri | Should -Match '/api/dcim/power-panels/5/'
        }
    }

    Context "New-NBDCIMPowerPanel" {
        It "Should create a power panel" {
            $Result = New-NBDCIMPowerPanel -Site 1 -Name 'Panel-A'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/power-panels/'
        }
    }

    Context "Set-NBDCIMPowerPanel" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMPowerPanel" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'Panel-A' }
            }
        }

        It "Should update a power panel" {
            $Result = Set-NBDCIMPowerPanel -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/dcim/power-panels/1/'
        }
    }

    Context "Remove-NBDCIMPowerPanel" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMPowerPanel" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'Panel-A' }
            }
        }

        It "Should remove a power panel" {
            $Result = Remove-NBDCIMPowerPanel -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/dcim/power-panels/2/'
        }
    }
    #endregion

    #region PowerFeeds
    Context "Get-NBDCIMPowerFeed" {
        It "Should request power feeds" {
            $Result = Get-NBDCIMPowerFeed
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/power-feeds/'
        }

        It "Should request a power feed by ID" {
            $Result = Get-NBDCIMPowerFeed -Id 5
            $Result.Uri | Should -Match '/api/dcim/power-feeds/5/'
        }
    }

    Context "New-NBDCIMPowerFeed" {
        It "Should create a power feed" {
            $Result = New-NBDCIMPowerFeed -Power_Panel 1 -Name 'Feed-A'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/power-feeds/'
        }
    }

    Context "Set-NBDCIMPowerFeed" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMPowerFeed" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'Feed-A' }
            }
        }

        It "Should update a power feed" {
            $Result = Set-NBDCIMPowerFeed -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/dcim/power-feeds/1/'
        }
    }

    Context "Remove-NBDCIMPowerFeed" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMPowerFeed" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'Feed-A' }
            }
        }

        It "Should remove a power feed" {
            $Result = Remove-NBDCIMPowerFeed -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/dcim/power-feeds/2/'
        }
    }
    #endregion

    #region DeviceBays
    Context "Get-NBDCIMDeviceBay" {
        It "Should request device bays" {
            $Result = Get-NBDCIMDeviceBay
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-bays/'
        }

        It "Should request a device bay by ID" {
            $Result = Get-NBDCIMDeviceBay -Id 5
            $Result.Uri | Should -Match '/api/dcim/device-bays/5/'
        }
    }

    Context "New-NBDCIMDeviceBay" {
        It "Should create a device bay" {
            $Result = New-NBDCIMDeviceBay -Device 1 -Name 'Bay1'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/device-bays/'
        }
    }

    Context "Set-NBDCIMDeviceBay" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMDeviceBay" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'Bay1' }
            }
        }

        It "Should update a device bay" {
            $Result = Set-NBDCIMDeviceBay -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/dcim/device-bays/1/'
        }

        It "Should accept null Installed_Device to depopulate bay" {
            $Result = Set-NBDCIMDeviceBay -Id 1 -Installed_Device $null -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/dcim/device-bays/1/'
            $body = $Result.Body | ConvertFrom-Json
            $body.installed_device | Should -BeNullOrEmpty
        }

        It "Should send null in JSON body when Installed_Device is null" {
            $Result = Set-NBDCIMDeviceBay -Id 1 -Installed_Device $null -Confirm:$false
            $Result.Body | Should -Match '"installed_device":\s*null'
        }

        It "Should accept uint64 Installed_Device to populate bay" {
            $Result = Set-NBDCIMDeviceBay -Id 1 -Installed_Device 42 -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $body = $Result.Body | ConvertFrom-Json
            $body.installed_device | Should -Be 42
        }
    }

    Context "Remove-NBDCIMDeviceBay" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMDeviceBay" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'Bay1' }
            }
        }

        It "Should remove a device bay" {
            $Result = Remove-NBDCIMDeviceBay -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/dcim/device-bays/2/'
        }
    }
    #endregion

    #region Modules
    Context "Get-NBDCIMModule" {
        It "Should request modules" {
            $Result = Get-NBDCIMModule
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/modules/'
        }

        It "Should request a module by ID" {
            $Result = Get-NBDCIMModule -Id 5
            $Result.Uri | Should -Match '/api/dcim/modules/5/'
        }
    }

    Context "New-NBDCIMModule" {
        It "Should create a module" {
            $Result = New-NBDCIMModule -Device 1 -Module_Bay 1 -Module_Type 1
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/modules/'
        }
    }

    Context "Set-NBDCIMModule" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMModule" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id }
            }
        }

        It "Should update a module" {
            $Result = Set-NBDCIMModule -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/dcim/modules/1/'
        }
    }

    Context "Remove-NBDCIMModule" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMModule" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id }
            }
        }

        It "Should remove a module" {
            $Result = Remove-NBDCIMModule -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/dcim/modules/2/'
        }
    }
    #endregion

    #region ModuleTypes
    Context "Get-NBDCIMModuleType" {
        It "Should request module types" {
            $Result = Get-NBDCIMModuleType
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/module-types/'
        }

        It "Should request a module type by ID" {
            $Result = Get-NBDCIMModuleType -Id 5
            $Result.Uri | Should -Match '/api/dcim/module-types/5/'
        }
    }

    Context "New-NBDCIMModuleType" {
        It "Should create a module type" {
            $Result = New-NBDCIMModuleType -Manufacturer 1 -Model 'SFP-Module'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/module-types/'
        }
    }

    Context "Set-NBDCIMModuleType" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMModuleType" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Model' = 'SFP' }
            }
        }

        It "Should update a module type" {
            $Result = Set-NBDCIMModuleType -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/dcim/module-types/1/'
        }
    }

    Context "Remove-NBDCIMModuleType" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMModuleType" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Model' = 'SFP' }
            }
        }

        It "Should remove a module type" {
            $Result = Remove-NBDCIMModuleType -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/dcim/module-types/2/'
        }
    }
    #endregion

    #region ModuleBays
    Context "Get-NBDCIMModuleBay" {
        It "Should request module bays" {
            $Result = Get-NBDCIMModuleBay
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/module-bays/'
        }

        It "Should request a module bay by ID" {
            $Result = Get-NBDCIMModuleBay -Id 5
            $Result.Uri | Should -Match '/api/dcim/module-bays/5/'
        }
    }

    Context "New-NBDCIMModuleBay" {
        It "Should create a module bay" {
            $Result = New-NBDCIMModuleBay -Device 1 -Name 'ModBay1'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/module-bays/'
        }

        It "Should send enabled (NetBox 4.6+, #395 Phase 1)" {
            $Result = New-NBDCIMModuleBay -Device 1 -Name 'ModBay1' -Enabled $false
            ($Result.Body | ConvertFrom-Json).enabled | Should -Be $false
        }
    }

    Context "Set-NBDCIMModuleBay" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMModuleBay" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'ModBay1' }
            }
        }

        It "Should update a module bay" {
            $Result = Set-NBDCIMModuleBay -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/dcim/module-bays/1/'
        }

        It "Should set enabled (NetBox 4.6+, #395 Phase 1)" {
            $Result = Set-NBDCIMModuleBay -Id 1 -Enabled $false -Confirm:$false
            ($Result.Body | ConvertFrom-Json).enabled | Should -Be $false
        }
    }

    Context "Remove-NBDCIMModuleBay" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMModuleBay" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'ModBay1' }
            }
        }

        It "Should remove a module bay" {
            $Result = Remove-NBDCIMModuleBay -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/dcim/module-bays/2/'
        }
    }
    #endregion

    #region ModuleTypeProfiles
    Context "Get-NBDCIMModuleTypeProfile" {
        It "Should request module type profiles" {
            $Result = Get-NBDCIMModuleTypeProfile
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/module-type-profiles/'
        }

        It "Should request a module type profile by ID" {
            $Result = Get-NBDCIMModuleTypeProfile -Id 5
            $Result.Uri | Should -Match '/api/dcim/module-type-profiles/5/'
        }
    }

    Context "New-NBDCIMModuleTypeProfile" {
        It "Should create a module type profile" {
            $Result = New-NBDCIMModuleTypeProfile -Name 'Profile1'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/module-type-profiles/'
        }
    }

    Context "Set-NBDCIMModuleTypeProfile" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMModuleTypeProfile" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'Profile1' }
            }
        }

        It "Should update a module type profile" {
            $Result = Set-NBDCIMModuleTypeProfile -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/dcim/module-type-profiles/1/'
        }
    }

    Context "Remove-NBDCIMModuleTypeProfile" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMModuleTypeProfile" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'Profile1' }
            }
        }

        It "Should remove a module type profile" {
            $Result = Remove-NBDCIMModuleTypeProfile -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/dcim/module-type-profiles/2/'
        }
    }
    #endregion

    #region InventoryItems
    Context "Get-NBDCIMInventoryItem" {
        It "Should request inventory items" {
            $Result = Get-NBDCIMInventoryItem
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/inventory-items/'
        }

        It "Should request an inventory item by ID" {
            $Result = Get-NBDCIMInventoryItem -Id 5
            $Result.Uri | Should -Match '/api/dcim/inventory-items/5/'
        }
    }

    Context "New-NBDCIMInventoryItem" {
        It "Should create an inventory item" {
            $Result = New-NBDCIMInventoryItem -Device 1 -Name 'SFP-1'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/inventory-items/'
        }
    }

    Context "Set-NBDCIMInventoryItem" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMInventoryItem" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'SFP-1' }
            }
        }

        It "Should update an inventory item" {
            $Result = Set-NBDCIMInventoryItem -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/dcim/inventory-items/1/'
        }
    }

    Context "Remove-NBDCIMInventoryItem" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMInventoryItem" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'SFP-1' }
            }
        }

        It "Should remove an inventory item" {
            $Result = Remove-NBDCIMInventoryItem -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/dcim/inventory-items/2/'
        }
    }
    #endregion

    #region InventoryItemRoles
    Context "Get-NBDCIMInventoryItemRole" {
        It "Should request inventory item roles" {
            $Result = Get-NBDCIMInventoryItemRole
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/inventory-item-roles/'
        }

        It "Should request an inventory item role by ID" {
            $Result = Get-NBDCIMInventoryItemRole -Id 5
            $Result.Uri | Should -Match '/api/dcim/inventory-item-roles/5/'
        }
    }

    Context "New-NBDCIMInventoryItemRole" {
        It "Should create an inventory item role" {
            $Result = New-NBDCIMInventoryItemRole -Name 'Optic' -Slug 'optic'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/inventory-item-roles/'
        }
    }

    Context "Set-NBDCIMInventoryItemRole" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMInventoryItemRole" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'Optic' }
            }
        }

        It "Should update an inventory item role" {
            $Result = Set-NBDCIMInventoryItemRole -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/dcim/inventory-item-roles/1/'
        }
    }

    Context "Remove-NBDCIMInventoryItemRole" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMInventoryItemRole" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'Optic' }
            }
        }

        It "Should remove an inventory item role" {
            $Result = Remove-NBDCIMInventoryItemRole -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/dcim/inventory-item-roles/2/'
        }
    }
    #endregion

    #region FrontPorts
    Context "Get-NBDCIMFrontPort" {
        It "Should request front ports" {
            $Result = Get-NBDCIMFrontPort
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/front-ports/'
        }

        It "Should request a front port by ID" {
            $Result = Get-NBDCIMFrontPort -Id 5
            $Result.Uri | Should -Match '/api/dcim/front-ports/5/'
        }
    }

    Context "Add-NBDCIMFrontPort" {
        It "Should create a front port with legacy parameters" {
            $Result = Add-NBDCIMFrontPort -Device 1 -Name 'FP1' -Type '8p8c' -Rear_Port 1 -Rear_Port_Position 1
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/front-ports/'
        }

        It "Should create a front port with Rear_Ports array (4.5+ format)" {
            # Mock version detection to return 4.5
            Mock -CommandName "Get-NBVersion" -ModuleName PowerNetbox -MockWith {
                return @{ 'netbox-version' = '4.5.0' }
            }
            $rearPorts = @(
                @{ rear_port = 100; rear_port_position = 1; position = 1 }
            )
            $Result = Add-NBDCIMFrontPort -Device 1 -Name 'FP2' -Type 'lc' -Rear_Ports $rearPorts
            $Result.Method | Should -Be 'POST'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.rear_ports | Should -Not -BeNullOrEmpty
            $bodyObj.rear_ports[0].rear_port | Should -Be 100
        }
    }

    Context "Set-NBDCIMFrontPort" {
        It "Should update a front port" {
            $Result = Set-NBDCIMFrontPort -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/dcim/front-ports/1/'
        }

        It "Should update a front port with Rear_Ports array (4.5+ format)" {
            Mock -CommandName "Get-NBVersion" -ModuleName PowerNetbox -MockWith {
                return @{ 'netbox-version' = '4.5.0' }
            }
            $rearPorts = @(
                @{ rear_port = 200; rear_port_position = 2; position = 1 }
            )
            $Result = Set-NBDCIMFrontPort -Id 1 -Rear_Ports $rearPorts -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.rear_ports | Should -Not -BeNullOrEmpty
            $bodyObj.rear_ports[0].rear_port | Should -Be 200
        }
    }

    Context "Remove-NBDCIMFrontPort" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMFrontPort" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'FP1' }
            }
        }

        It "Should remove a front port" {
            $Result = Remove-NBDCIMFrontPort -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/dcim/front-ports/2/'
        }
    }
    #endregion

    #region RearPorts
    Context "Get-NBDCIMRearPort" {
        It "Should request rear ports" {
            $Result = Get-NBDCIMRearPort
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/rear-ports/'
        }

        It "Should request a rear port by ID" {
            $Result = Get-NBDCIMRearPort -Id 5
            $Result.Uri | Should -Match '/api/dcim/rear-ports/5/'
        }
    }

    Context "Add-NBDCIMRearPort" {
        It "Should create a rear port" {
            $Result = Add-NBDCIMRearPort -Device 1 -Name 'RP1' -Type '8p8c'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/rear-ports/'
        }

        It "Should create a rear port with Front_Ports array (4.5+ bidirectional)" {
            # Set cached version to simulate Netbox 4.5+ (preserve other config values)
            InModuleScope PowerNetbox {
                if (-not $script:NetboxConfig) { $script:NetboxConfig = @{} }
                $script:NetboxConfig['ParsedVersion'] = [version]'4.5.0'
            }
            $frontPorts = @(
                @{ front_port = 50; front_port_position = 1; position = 1 }
            )
            $Result = Add-NBDCIMRearPort -Device 1 -Name 'RP2' -Type 'lc' -Front_Ports $frontPorts
            $Result.Method | Should -Be 'POST'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.front_ports | Should -Not -BeNullOrEmpty
            $bodyObj.front_ports[0].front_port | Should -Be 50
        }
    }

    Context "Set-NBDCIMRearPort" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMRearPort" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'RP1' }
            }
        }

        It "Should update a rear port" {
            $Result = Set-NBDCIMRearPort -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/dcim/rear-ports/1/'
        }

        It "Should update a rear port with Front_Ports array (4.5+ bidirectional)" {
            # Set cached version to simulate Netbox 4.5+ (preserve other config values)
            InModuleScope PowerNetbox {
                if (-not $script:NetboxConfig) { $script:NetboxConfig = @{} }
                $script:NetboxConfig['ParsedVersion'] = [version]'4.5.0'
            }
            $frontPorts = @(
                @{ front_port = 75; front_port_position = 2; position = 1 }
            )
            $Result = Set-NBDCIMRearPort -Id 1 -Front_Ports $frontPorts -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.front_ports | Should -Not -BeNullOrEmpty
            $bodyObj.front_ports[0].front_port | Should -Be 75
        }
    }

    Context "Remove-NBDCIMRearPort" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMRearPort" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'RP1' }
            }
        }

        It "Should remove a rear port" {
            $Result = Remove-NBDCIMRearPort -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/dcim/rear-ports/2/'
        }
    }
    #endregion

    #region MACAddresses
    Context "Get-NBDCIMMACAddress" {
        It "Should request MAC addresses" {
            $Result = Get-NBDCIMMACAddress
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/mac-addresses/'
        }

        It "Should request a MAC address by ID" {
            $Result = Get-NBDCIMMACAddress -Id 5
            $Result.Uri | Should -Match '/api/dcim/mac-addresses/5/'
        }
    }

    Context "New-NBDCIMMACAddress" {
        It "Should create a MAC address" {
            $Result = New-NBDCIMMACAddress -Mac_Address '00:11:22:33:44:55'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/mac-addresses/'
        }
    }

    Context "Set-NBDCIMMACAddress" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMMACAddress" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Mac_Address' = '00:11:22:33:44:55' }
            }
        }

        It "Should update a MAC address" {
            $Result = Set-NBDCIMMACAddress -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/dcim/mac-addresses/1/'
        }
    }

    Context "Remove-NBDCIMMACAddress" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMMACAddress" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Mac_Address' = '00:11:22:33:44:55' }
            }
        }

        It "Should remove a MAC address" {
            $Result = Remove-NBDCIMMACAddress -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/dcim/mac-addresses/2/'
        }
    }
    #endregion

    #region VirtualChassis
    Context "Get-NBDCIMVirtualChassis" {
        It "Should request virtual chassis" {
            $Result = Get-NBDCIMVirtualChassis
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/virtual-chassis/'
        }

        It "Should request a virtual chassis by ID" {
            $Result = Get-NBDCIMVirtualChassis -Id 5
            $Result.Uri | Should -Match '/api/dcim/virtual-chassis/5/'
        }
    }

    Context "New-NBDCIMVirtualChassis" {
        It "Should create a virtual chassis" {
            $Result = New-NBDCIMVirtualChassis -Name 'VC1'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/virtual-chassis/'
        }
    }

    Context "Set-NBDCIMVirtualChassis" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMVirtualChassis" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'VC1' }
            }
        }

        It "Should update a virtual chassis" {
            $Result = Set-NBDCIMVirtualChassis -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/dcim/virtual-chassis/1/'
        }
    }

    Context "Remove-NBDCIMVirtualChassis" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMVirtualChassis" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'VC1' }
            }
        }

        It "Should remove a virtual chassis" {
            $Result = Remove-NBDCIMVirtualChassis -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/dcim/virtual-chassis/2/'
        }
    }
    #endregion

    #region VirtualDeviceContexts
    Context "Get-NBDCIMVirtualDeviceContext" {
        It "Should request virtual device contexts" {
            $Result = Get-NBDCIMVirtualDeviceContext
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/virtual-device-contexts/'
        }

        It "Should request a virtual device context by ID" {
            $Result = Get-NBDCIMVirtualDeviceContext -Id 5
            $Result.Uri | Should -Match '/api/dcim/virtual-device-contexts/5/'
        }
    }

    Context "New-NBDCIMVirtualDeviceContext" {
        It "Should create a virtual device context" {
            $Result = New-NBDCIMVirtualDeviceContext -Name 'VDC1' -Device 1
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/virtual-device-contexts/'
        }
    }

    Context "Set-NBDCIMVirtualDeviceContext" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMVirtualDeviceContext" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'VDC1' }
            }
        }

        It "Should update a virtual device context" {
            $Result = Set-NBDCIMVirtualDeviceContext -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/dcim/virtual-device-contexts/1/'
        }
    }

    Context "Remove-NBDCIMVirtualDeviceContext" {
        BeforeAll {
            Mock -CommandName "Get-NBDCIMVirtualDeviceContext" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'VDC1' }
            }
        }

        It "Should remove a virtual device context" {
            $Result = Remove-NBDCIMVirtualDeviceContext -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/dcim/virtual-device-contexts/2/'
        }
    }
    #endregion

    #region PowerOutletTemplates (Color field - Netbox 4.5+)
    Context "New-NBDCIMPowerOutletTemplate" {
        It "Should create a power outlet template" {
            $Result = New-NBDCIMPowerOutletTemplate -Device_Type 1 -Name 'Outlet1'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/power-outlet-templates/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.device_type | Should -Be 1
            $bodyObj.name | Should -Be 'Outlet1'
        }

        It "Should create a power outlet template with Color (Netbox 4.5+)" {
            $Result = New-NBDCIMPowerOutletTemplate -Device_Type 1 -Name 'Outlet1' -Color 'aa1409'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.color | Should -Be 'aa1409'
        }
    }

    Context "Set-NBDCIMPowerOutletTemplate" {
        It "Should update a power outlet template" {
            $Result = Set-NBDCIMPowerOutletTemplate -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/dcim/power-outlet-templates/1/'
        }

        It "Should update a power outlet template with Color (Netbox 4.5+)" {
            $Result = Set-NBDCIMPowerOutletTemplate -Id 1 -Color 'f44336' -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.color | Should -Be 'f44336'
        }
    }
    #endregion

    #region Cable Terminations
    Context "Get-NBDCIMCableTermination" {
        It "Should request cable terminations" {
            $Result = Get-NBDCIMCableTermination
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/cable-terminations/'
        }

        It "Should request cable terminations by cable ID" {
            $Result = Get-NBDCIMCableTermination -Cable 10
            $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/cable-terminations/?cable=10'
        }

        It "Should request cable terminations by cable end" {
            $Result = Get-NBDCIMCableTermination -Cable_End 'A'
            $Result.Uri | Should -BeExactly 'https://netbox.domain.com/api/dcim/cable-terminations/?cable_end=A'
        }
    }
    #endregion

    #region Connected Device
    Context "Get-NBDCIMConnectedDevice" {
        It "Should request a connected device" {
            $Result = Get-NBDCIMConnectedDevice -Peer_Device 'switch01' -Peer_Interface 'eth0'
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Match 'peer_device=switch01'
            $Result.Uri | Should -Match 'peer_interface=eth0'
        }

        It "Should have mandatory Peer_Device and Peer_Interface parameters" {
            $cmd = Get-Command Get-NBDCIMConnectedDevice
            $cmd.Parameters['Peer_Device'].Attributes.Mandatory | Should -Contain $true
            $cmd.Parameters['Peer_Interface'].Attributes.Mandatory | Should -Contain $true
        }
    }
    #endregion

    #region WhatIf Tests
    Context "WhatIf Support" {
        $whatIfTestCases = @(
            @{ Command = 'New-NBDCIMCable'; Parameters = @{ A_Terminations = @(@{object_id=1;object_type='dcim.interface'}); B_Terminations = @(@{object_id=1;object_type='dcim.interface'}) } }
            @{ Command = 'New-NBDCIMConsolePort'; Parameters = @{ Device = 1; Name = 'whatif-test' } }
            @{ Command = 'New-NBDCIMConsoleServerPort'; Parameters = @{ Device = 1; Name = 'whatif-test' } }
            @{ Command = 'New-NBDCIMDeviceBay'; Parameters = @{ Device = 1; Name = 'whatif-test' } }
            @{ Command = 'New-NBDCIMFrontPort'; Parameters = @{ Device = 1; Name = 'whatif-test'; Type = '8p8c' } }
            @{ Command = 'New-NBDCIMInventoryItem'; Parameters = @{ Device = 1; Name = 'whatif-test' } }
            @{ Command = 'New-NBDCIMInventoryItemRole'; Parameters = @{ Name = 'whatif-test'; Slug = 'whatif-test' } }
            @{ Command = 'New-NBDCIMLocation'; Parameters = @{ Name = 'whatif-test'; Slug = 'whatif-test'; Site = 1 } }
            @{ Command = 'New-NBDCIMMACAddress'; Parameters = @{ Mac_Address = 'whatif-test' } }
            @{ Command = 'New-NBDCIMManufacturer'; Parameters = @{ Name = 'whatif-test'; Slug = 'whatif-test' } }
            @{ Command = 'New-NBDCIMModule'; Parameters = @{ Device = 1; Module_Bay = 1; Module_Type = 1 } }
            @{ Command = 'New-NBDCIMModuleBay'; Parameters = @{ Device = 1; Name = 'whatif-test' } }
            @{ Command = 'New-NBDCIMModuleType'; Parameters = @{ Manufacturer = 1; Model = 'whatif-test' } }
            @{ Command = 'New-NBDCIMModuleTypeProfile'; Parameters = @{ Name = 'whatif-test' } }
            @{ Command = 'New-NBDCIMPowerFeed'; Parameters = @{ Power_Panel = 1; Name = 'whatif-test' } }
            @{ Command = 'New-NBDCIMPowerOutlet'; Parameters = @{ Device = 1; Name = 'whatif-test' } }
            @{ Command = 'New-NBDCIMPowerPanel'; Parameters = @{ Site = 1; Name = 'whatif-test' } }
            @{ Command = 'New-NBDCIMPowerPort'; Parameters = @{ Device = 1; Name = 'whatif-test' } }
            @{ Command = 'New-NBDCIMRackReservation'; Parameters = @{ Rack = 1; Units = 1; User = 1 } }
            @{ Command = 'New-NBDCIMRackRole'; Parameters = @{ Name = 'whatif-test' } }
            @{ Command = 'New-NBDCIMRackType'; Parameters = @{ Manufacturer = 1; Model = 'whatif-test'; Form_Factor = 'whatif-test' } }
            @{ Command = 'New-NBDCIMRearPort'; Parameters = @{ Device = 1; Name = 'whatif-test'; Type = '8p8c' } }
            @{ Command = 'New-NBDCIMRegion'; Parameters = @{ Name = 'whatif-test'; Slug = 'whatif-test' } }
            @{ Command = 'New-NBDCIMSiteGroup'; Parameters = @{ Name = 'whatif-test'; Slug = 'whatif-test' } }
            @{ Command = 'New-NBDCIMVirtualChassis'; Parameters = @{ Name = 'whatif-test' } }
            @{ Command = 'New-NBDCIMVirtualDeviceContext'; Parameters = @{ Name = 'whatif-test'; Device = 1 } }
            @{ Command = 'Set-NBDCIMCable'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMConsolePort'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMConsoleServerPort'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMDeviceBay'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMFrontPort'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMInventoryItem'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMInventoryItemRole'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMLocation'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMMACAddress'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMManufacturer'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMModule'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMModuleBay'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMModuleType'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMModuleTypeProfile'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMPowerFeed'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMPowerOutlet'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMPowerPanel'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMPowerPort'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMRackReservation'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMRackRole'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMRackType'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMRearPort'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMRegion'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMSiteGroup'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMVirtualChassis'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBDCIMVirtualDeviceContext'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMCable'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMConsolePort'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMConsoleServerPort'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMDeviceBay'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMFrontPort'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMInventoryItem'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMInventoryItemRole'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMLocation'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMMACAddress'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMManufacturer'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMModule'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMModuleBay'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMModuleType'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMModuleTypeProfile'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMPowerFeed'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMPowerOutlet'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMPowerPanel'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMPowerPort'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMRackReservation'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMRackRole'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMRackType'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMRearPort'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMRegion'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMSiteGroup'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMVirtualChassis'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMVirtualDeviceContext'; Parameters = @{ Id = 1 } }
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
            @{ Command = 'Get-NBDCIMCable' }
            @{ Command = 'Get-NBDCIMCableTermination' }
            @{ Command = 'Get-NBDCIMConsolePort' }
            @{ Command = 'Get-NBDCIMConsoleServerPort' }
            @{ Command = 'Get-NBDCIMDeviceBay' }
            @{ Command = 'Get-NBDCIMFrontPort' }
            @{ Command = 'Get-NBDCIMInventoryItem' }
            @{ Command = 'Get-NBDCIMInventoryItemRole' }
            @{ Command = 'Get-NBDCIMLocation' }
            @{ Command = 'Get-NBDCIMMACAddress' }
            @{ Command = 'Get-NBDCIMManufacturer' }
            @{ Command = 'Get-NBDCIMModule' }
            @{ Command = 'Get-NBDCIMModuleBay' }
            @{ Command = 'Get-NBDCIMModuleType' }
            @{ Command = 'Get-NBDCIMModuleTypeProfile' }
            @{ Command = 'Get-NBDCIMPowerFeed' }
            @{ Command = 'Get-NBDCIMPowerOutlet' }
            @{ Command = 'Get-NBDCIMPowerPanel' }
            @{ Command = 'Get-NBDCIMPowerPort' }
            @{ Command = 'Get-NBDCIMRackReservation' }
            @{ Command = 'Get-NBDCIMRackRole' }
            @{ Command = 'Get-NBDCIMRackType' }
            @{ Command = 'Get-NBDCIMRearPort' }
            @{ Command = 'Get-NBDCIMRegion' }
            @{ Command = 'Get-NBDCIMSiteGroup' }
            @{ Command = 'Get-NBDCIMVirtualChassis' }
            @{ Command = 'Get-NBDCIMVirtualDeviceContext' }
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
            @{ Command = 'Get-NBDCIMCable' }
            @{ Command = 'Get-NBDCIMCableTermination' }
            @{ Command = 'Get-NBDCIMConsolePort' }
            @{ Command = 'Get-NBDCIMConsoleServerPort' }
            @{ Command = 'Get-NBDCIMDeviceBay' }
            @{ Command = 'Get-NBDCIMFrontPort' }
            @{ Command = 'Get-NBDCIMInventoryItem' }
            @{ Command = 'Get-NBDCIMInventoryItemRole' }
            @{ Command = 'Get-NBDCIMLocation' }
            @{ Command = 'Get-NBDCIMMACAddress' }
            @{ Command = 'Get-NBDCIMManufacturer' }
            @{ Command = 'Get-NBDCIMModule' }
            @{ Command = 'Get-NBDCIMModuleBay' }
            @{ Command = 'Get-NBDCIMModuleType' }
            @{ Command = 'Get-NBDCIMModuleTypeProfile' }
            @{ Command = 'Get-NBDCIMPowerFeed' }
            @{ Command = 'Get-NBDCIMPowerOutlet' }
            @{ Command = 'Get-NBDCIMPowerPanel' }
            @{ Command = 'Get-NBDCIMPowerPort' }
            @{ Command = 'Get-NBDCIMRackReservation' }
            @{ Command = 'Get-NBDCIMRackRole' }
            @{ Command = 'Get-NBDCIMRackType' }
            @{ Command = 'Get-NBDCIMRearPort' }
            @{ Command = 'Get-NBDCIMRegion' }
            @{ Command = 'Get-NBDCIMSiteGroup' }
            @{ Command = 'Get-NBDCIMVirtualChassis' }
            @{ Command = 'Get-NBDCIMVirtualDeviceContext' }
        )

        It 'Should pass -Omit to query string for <Command>' -TestCases $omitTestCases {
            param($Command, $Parameters)
            $splat = @{ Omit = @('comments', 'description') }
            if ($Parameters) { $splat += $Parameters }
            $Result = & $Command @splat
            $Result.Uri | Should -Match 'omit=comments%2Cdescription'
        }
    }
    #endregion

    #region Pipeline Input Tests
    Context "Pipeline Input" {
        $pipelineTestCases = @(
            @{ Command = 'Get-NBDCIMSite' }
            @{ Command = 'Get-NBDCIMCable' }
            @{ Command = 'Get-NBDCIMManufacturer' }
        )

        It 'Should accept pipeline input by property name for <Command>' -TestCases $pipelineTestCases {
            param($Command)
            $Result = [pscustomobject]@{ 'Id' = 10 } | & $Command
            $Result.Uri | Should -Match '/10/'
        }
    }
    #endregion

    #region RackGroups (NetBox 4.6+, #395 Phase 2)
    Context "Get-NBDCIMRackGroup" {
        It "Should request the list endpoint" {
            $Result = Get-NBDCIMRackGroup
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/rack-groups/'
        }
        It "Should request a rack group by ID" {
            $Result = Get-NBDCIMRackGroup -Id 5
            $Result.Uri | Should -Match '/api/dcim/rack-groups/5/'
        }
        It "Should filter by name" {
            $Result = Get-NBDCIMRackGroup -Name 'Row A'
            $Result.Uri | Should -Match 'name=Row(\+|%20)A'
        }
    }

    Context "New-NBDCIMRackGroup" {
        It "Should create a rack group and auto-generate the slug" {
            $Result = New-NBDCIMRackGroup -Name 'Row A'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/rack-groups/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'Row A'
            $bodyObj.slug | Should -Be 'row-a'
        }
        It "Should honour an explicit slug" {
            $Result = New-NBDCIMRackGroup -Name 'Row B' -Slug 'custom-b'
            ($Result.Body | ConvertFrom-Json).slug | Should -Be 'custom-b'
        }
    }

    Context "Set-NBDCIMRackGroup" {
        It "Should update a rack group" {
            $Result = Set-NBDCIMRackGroup -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/dcim/rack-groups/1/'
            ($Result.Body | ConvertFrom-Json).description | Should -Be 'Updated'
        }
    }

    Context "Remove-NBDCIMRackGroup" {
        It "Should delete a rack group" {
            $Result = Remove-NBDCIMRackGroup -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/dcim/rack-groups/1/'
        }
        It "Should accept pipeline input by property name" {
            $Result = [pscustomobject]@{ Id = 9 } | Remove-NBDCIMRackGroup -Confirm:$false
            $Result.Uri | Should -Match '/api/dcim/rack-groups/9/'
        }
    }
    #endregion
}
