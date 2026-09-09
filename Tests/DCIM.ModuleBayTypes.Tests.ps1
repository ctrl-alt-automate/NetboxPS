<#
.SYNOPSIS
    Unit tests for DCIM Module Bay Types (NetBox 4.7+).

.DESCRIPTION
    Covers the /api/dcim/module-bay-types/ endpoint cmdlets
    (Get/New/Set/Remove-NBDCIMModuleBayType) and the version-gated
    -Module_Bay_Types parameter on New/Set-NBDCIMModuleBay,
    New/Set-NBDCIMModuleBayTemplate and New/Set-NBDCIMModuleType.
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

Describe "DCIM Module Bay Types Tests" -Tag 'DCIM' {
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

    #region Get-NBDCIMModuleBayType
    Context "Get-NBDCIMModuleBayType" {
        It "Should request the list endpoint" {
            $Result = Get-NBDCIMModuleBayType
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/module-bay-types/'
        }

        It "Should request a module bay type by ID" {
            $Result = Get-NBDCIMModuleBayType -Id 7
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/module-bay-types/7/'
        }

        It "Should request each ID via the detail endpoint" {
            $Result = @(Get-NBDCIMModuleBayType -Id 1, 2)
            $Result.Count | Should -Be 2
            $Result[0].Uri | Should -Be 'https://netbox.domain.com/api/dcim/module-bay-types/1/'
            $Result[1].Uri | Should -Be 'https://netbox.domain.com/api/dcim/module-bay-types/2/'
        }

        It "Should pass -Brief through on the detail endpoint" {
            $Result = Get-NBDCIMModuleBayType -Id 7 -Brief
            $Result.Uri | Should -Match '/api/dcim/module-bay-types/7/\?brief=True'
        }

        It "Should filter by name (repeat-key)" {
            $Result = Get-NBDCIMModuleBayType -Name 'SFP', 'QSFP'
            $Result.Uri | Should -Match 'name=SFP'
            $Result.Uri | Should -Match 'name=QSFP'
        }

        It "Should filter by slug" {
            $Result = Get-NBDCIMModuleBayType -Slug 'sfp-cage'
            $Result.Uri | Should -Match 'slug=sfp-cage'
        }

        It "Should filter by color" {
            $Result = Get-NBDCIMModuleBayType -Color '00ff00'
            $Result.Uri | Should -Match 'color=00ff00'
        }

        It "Should filter by manufacturer_id" {
            $Result = Get-NBDCIMModuleBayType -Manufacturer_Id 3
            $Result.Uri | Should -Match 'manufacturer_id=3'
        }

        It "Should filter by manufacturer slug" {
            $Result = Get-NBDCIMModuleBayType -Manufacturer 'cisco'
            $Result.Uri | Should -Match 'manufacturer=cisco'
        }

        It "Should filter by module_bay_id" {
            $Result = Get-NBDCIMModuleBayType -Module_Bay_Id 11
            $Result.Uri | Should -Match 'module_bay_id=11'
        }

        It "Should filter by module_bay_template_id" {
            $Result = Get-NBDCIMModuleBayType -Module_Bay_Template_Id 12
            $Result.Uri | Should -Match 'module_bay_template_id=12'
        }

        It "Should filter by module_type_id (repeat-key)" {
            $Result = Get-NBDCIMModuleBayType -Module_Type_Id 13, 14
            $Result.Uri | Should -Match 'module_type_id=13'
            $Result.Uri | Should -Match 'module_type_id=14'
        }

        It "Should filter by description" {
            $Result = Get-NBDCIMModuleBayType -Description 'Hot-swap'
            $Result.Uri | Should -Match 'description=Hot-swap'
        }

        It "Should filter by owner_id" {
            $Result = Get-NBDCIMModuleBayType -Owner_Id 2
            $Result.Uri | Should -Match 'owner_id=2'
        }

        It "Should filter by tag" {
            $Result = Get-NBDCIMModuleBayType -Tag 'optics'
            $Result.Uri | Should -Match 'tag=optics'
        }

        It "Should send free-text search as q" {
            $Result = Get-NBDCIMModuleBayType -Query 'cage' -WarningAction SilentlyContinue
            $Result.Uri | Should -Match 'q=cage'
        }

        It "Should pass limit and offset" {
            $Result = Get-NBDCIMModuleBayType -Limit 50 -Offset 100
            $Result.Uri | Should -Match 'limit=50'
            $Result.Uri | Should -Match 'offset=100'
        }

        It "Should reject -Brief together with -Fields" {
            { Get-NBDCIMModuleBayType -Brief -Fields 'id' } | Should -Throw
        }

        It "Should accept Id from the pipeline by property name" {
            $Result = [PSCustomObject]@{ Id = 9 } | Get-NBDCIMModuleBayType
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/module-bay-types/9/'
        }
    }
    #endregion

    #region New-NBDCIMModuleBayType
    Context "New-NBDCIMModuleBayType" {
        It "Should POST to the list endpoint with name and derived slug" {
            $Result = New-NBDCIMModuleBayType -Name 'SFP Cage'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/module-bay-types/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'SFP Cage'
            $bodyObj.slug | Should -Be 'sfp-cage'
        }

        It "Should keep an explicit slug" {
            $Result = New-NBDCIMModuleBayType -Name 'Line Card Slot' -Slug 'lc-slot'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.slug | Should -Be 'lc-slot'
        }

        It "Should send all writable fields" {
            $Result = New-NBDCIMModuleBayType -Name 'QSFP' -Manufacturer 3 -Color '00ff00' `
                -Description 'desc' -Owner 5 -Comments 'notes' -Tags 'a', 2 -Custom_Fields @{ rack_unit = 1 }
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.manufacturer | Should -Be 3
            $bodyObj.color | Should -Be '00ff00'
            $bodyObj.description | Should -Be 'desc'
            $bodyObj.owner | Should -Be 5
            $bodyObj.comments | Should -Be 'notes'
            $bodyObj.tags.Count | Should -Be 2
            $bodyObj.custom_fields.rack_unit | Should -Be 1
        }

        It "Should lowercase the color for the API" {
            $Result = New-NBDCIMModuleBayType -Name 'X' -Color 'FF00AA'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.color | Should -Be 'ff00aa'
        }

        It "Should reject an invalid color" {
            { New-NBDCIMModuleBayType -Name 'X' -Color 'red' } | Should -Throw
            { New-NBDCIMModuleBayType -Name 'X' -Color '#00ff00' } | Should -Throw
        }

        It "Should support -WhatIf" {
            $Result = New-NBDCIMModuleBayType -Name 'X' -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }
    #endregion

    #region Set-NBDCIMModuleBayType
    Context "Set-NBDCIMModuleBayType" {
        It "Should PATCH the detail endpoint" {
            $Result = Set-NBDCIMModuleBayType -Id 7 -Name 'Renamed' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/module-bay-types/7/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'Renamed'
        }

        It "Should send all writable fields" {
            $Result = Set-NBDCIMModuleBayType -Id 7 -Slug 'new-slug' -Manufacturer 4 -Color 'ff0000' `
                -Description 'd' -Owner 6 -Comments 'c' -Tags 'x' -Custom_Fields @{ foo = 'bar' } -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.slug | Should -Be 'new-slug'
            $bodyObj.manufacturer | Should -Be 4
            $bodyObj.color | Should -Be 'ff0000'
            $bodyObj.description | Should -Be 'd'
            $bodyObj.owner | Should -Be 6
            $bodyObj.comments | Should -Be 'c'
            $bodyObj.tags[0].name | Should -Be 'x'
            $bodyObj.custom_fields.foo | Should -Be 'bar'
        }

        It "Should clear manufacturer with null" {
            $Result = Set-NBDCIMModuleBayType -Id 7 -Manufacturer $null -Confirm:$false
            $Result.Body | Should -Match '"manufacturer":null'
        }

        It "Should clear color with an empty string" {
            $Result = Set-NBDCIMModuleBayType -Id 7 -Color '' -Confirm:$false
            $Result.Body | Should -Match '"color":""'
        }

        It "Should reject an invalid color" {
            { Set-NBDCIMModuleBayType -Id 7 -Color 'zzzzzz' -Confirm:$false } | Should -Throw
        }

        It "Should accept Id from the pipeline by property name" {
            $Result = [PSCustomObject]@{ Id = 8 } | Set-NBDCIMModuleBayType -Description 'p' -Confirm:$false
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/module-bay-types/8/'
        }

        It "Should support -WhatIf" {
            $Result = Set-NBDCIMModuleBayType -Id 7 -Name 'X' -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }
    #endregion

    #region Remove-NBDCIMModuleBayType
    Context "Remove-NBDCIMModuleBayType" {
        It "Should DELETE the detail endpoint" {
            $Result = Remove-NBDCIMModuleBayType -Id 7 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/module-bay-types/7/'
        }

        It "Should accept Id from the pipeline by property name" {
            $Result = [PSCustomObject]@{ Id = 8 } | Remove-NBDCIMModuleBayType -Confirm:$false
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/module-bay-types/8/'
        }

        It "Should support -WhatIf" {
            $Result = Remove-NBDCIMModuleBayType -Id 7 -WhatIf
            $Result | Should -BeNullOrEmpty
        }
    }
    #endregion

    #region -Module_Bay_Types on existing cmdlets (NetBox 4.7+)
    Context "-Module_Bay_Types on module bays / templates / module types (Netbox 4.7+)" {
        BeforeAll {
            $script:parsedVersionBefore = InModuleScope -ModuleName 'PowerNetbox' { $script:NetboxConfig.ParsedVersion }
            InModuleScope -ModuleName 'PowerNetbox' { $script:NetboxConfig.ParsedVersion = [version]'4.7.0' }
        }
        AfterAll {
            InModuleScope -ModuleName 'PowerNetbox' -Parameters @{ v = $script:parsedVersionBefore } { $script:NetboxConfig.ParsedVersion = $v }
        }

        It "New-NBDCIMModuleBay should send module_bay_types" {
            $Result = New-NBDCIMModuleBay -Device 1 -Name 'Bay 1' -Module_Bay_Types 3, 4
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.module_bay_types | Should -Be @(3, 4)
            $bodyObj.device | Should -Be 1
            $bodyObj.name | Should -Be 'Bay 1'
        }

        It "New-NBDCIMModuleBay should send a single ID as an array" {
            $Result = New-NBDCIMModuleBay -Device 1 -Name 'Bay 1' -Module_Bay_Types 3
            $Result.Body | Should -Match '"module_bay_types":\[3\]'
        }

        It "Set-NBDCIMModuleBay should send module_bay_types" {
            $Result = Set-NBDCIMModuleBay -Id 5 -Module_Bay_Types 3 -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/module-bays/5/'
            $Result.Body | Should -Match '"module_bay_types":\[3\]'
        }

        It "Set-NBDCIMModuleBay should clear module_bay_types with an empty array" {
            $Result = Set-NBDCIMModuleBay -Id 5 -Module_Bay_Types @() -Confirm:$false
            $Result.Body | Should -Match '"module_bay_types":\[\]'
        }

        It "New-NBDCIMModuleBayTemplate should send module_bay_types" {
            $Result = New-NBDCIMModuleBayTemplate -Device_Type 1 -Name 'Slot {module}' -Module_Bay_Types 3, 4
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.module_bay_types | Should -Be @(3, 4)
            $bodyObj.device_type | Should -Be 1
        }

        It "Set-NBDCIMModuleBayTemplate should send module_bay_types" {
            $Result = Set-NBDCIMModuleBayTemplate -Id 6 -Module_Bay_Types 4 -Confirm:$false
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/module-bay-templates/6/'
            $Result.Body | Should -Match '"module_bay_types":\[4\]'
        }

        It "Set-NBDCIMModuleBayTemplate should clear module_bay_types with an empty array" {
            $Result = Set-NBDCIMModuleBayTemplate -Id 6 -Module_Bay_Types @() -Confirm:$false
            $Result.Body | Should -Match '"module_bay_types":\[\]'
        }

        It "New-NBDCIMModuleType should send module_bay_types" {
            $Result = New-NBDCIMModuleType -Manufacturer 1 -Model 'MT-1' -Module_Bay_Types 3, 4
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.module_bay_types | Should -Be @(3, 4)
            $bodyObj.model | Should -Be 'MT-1'
        }

        It "Set-NBDCIMModuleType should send module_bay_types" {
            $Result = Set-NBDCIMModuleType -Id 8 -Module_Bay_Types 3 -Confirm:$false
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/module-types/8/'
            $Result.Body | Should -Match '"module_bay_types":\[3\]'
        }

        It "Set-NBDCIMModuleType should clear module_bay_types with an empty array" {
            $Result = Set-NBDCIMModuleType -Id 8 -Module_Bay_Types @() -Confirm:$false
            $Result.Body | Should -Match '"module_bay_types":\[\]'
        }

        It "Existing cmdlets should not emit a warning on 4.7.0" {
            $null = Set-NBDCIMModuleBay -Id 5 -Module_Bay_Types 3 -Confirm:$false -WarningVariable warn -WarningAction SilentlyContinue
            $warn | Should -BeNullOrEmpty
        }

        Context "Below Netbox 4.7" {
            BeforeAll { InModuleScope -ModuleName 'PowerNetbox' { $script:NetboxConfig.ParsedVersion = [version]'4.6.10' } }
            AfterAll { InModuleScope -ModuleName 'PowerNetbox' { $script:NetboxConfig.ParsedVersion = [version]'4.7.0' } }

            It "New-NBDCIMModuleBay should drop module_bay_types with a warning" {
                $Result = New-NBDCIMModuleBay -Device 1 -Name 'Bay 1' -Module_Bay_Types 3 -WarningVariable warn -WarningAction SilentlyContinue
                $warn | Should -Match 'Module bay types requires Netbox 4.7.0'
                $bodyObj = $Result.Body | ConvertFrom-Json
                $bodyObj.PSObject.Properties.Name | Should -Not -Contain 'module_bay_types'
                $bodyObj.name | Should -Be 'Bay 1'
            }

            It "Set-NBDCIMModuleBay should drop module_bay_types with a warning" {
                $Result = Set-NBDCIMModuleBay -Id 5 -Module_Bay_Types 3 -Description 'x' -Confirm:$false -WarningVariable warn -WarningAction SilentlyContinue
                $warn | Should -Match 'requires Netbox 4.7.0'
                $bodyObj = $Result.Body | ConvertFrom-Json
                $bodyObj.PSObject.Properties.Name | Should -Not -Contain 'module_bay_types'
                $bodyObj.description | Should -Be 'x'
            }

            It "New-NBDCIMModuleBayTemplate should drop module_bay_types with a warning" {
                $Result = New-NBDCIMModuleBayTemplate -Device_Type 1 -Name 'Slot' -Module_Bay_Types 3 -WarningVariable warn -WarningAction SilentlyContinue
                $warn | Should -Match 'requires Netbox 4.7.0'
                $bodyObj = $Result.Body | ConvertFrom-Json
                $bodyObj.PSObject.Properties.Name | Should -Not -Contain 'module_bay_types'
            }

            It "Set-NBDCIMModuleBayTemplate should drop module_bay_types with a warning" {
                $Result = Set-NBDCIMModuleBayTemplate -Id 6 -Module_Bay_Types 3 -Label 'L' -Confirm:$false -WarningVariable warn -WarningAction SilentlyContinue
                $warn | Should -Match 'requires Netbox 4.7.0'
                $bodyObj = $Result.Body | ConvertFrom-Json
                $bodyObj.PSObject.Properties.Name | Should -Not -Contain 'module_bay_types'
                $bodyObj.label | Should -Be 'L'
            }

            It "New-NBDCIMModuleType should drop module_bay_types with a warning" {
                $Result = New-NBDCIMModuleType -Manufacturer 1 -Model 'MT-1' -Module_Bay_Types 3 -WarningVariable warn -WarningAction SilentlyContinue
                $warn | Should -Match 'requires Netbox 4.7.0'
                $bodyObj = $Result.Body | ConvertFrom-Json
                $bodyObj.PSObject.Properties.Name | Should -Not -Contain 'module_bay_types'
            }

            It "Set-NBDCIMModuleType should drop module_bay_types with a warning" {
                $Result = Set-NBDCIMModuleType -Id 8 -Module_Bay_Types 3 -Part_Number 'PN' -Confirm:$false -WarningVariable warn -WarningAction SilentlyContinue
                $warn | Should -Match 'requires Netbox 4.7.0'
                $bodyObj = $Result.Body | ConvertFrom-Json
                $bodyObj.PSObject.Properties.Name | Should -Not -Contain 'module_bay_types'
                $bodyObj.part_number | Should -Be 'PN'
            }
        }
    }
    #endregion
}
