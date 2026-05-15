param()

BeforeAll {
    Import-Module Pester
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -ErrorAction Stop
    }
}

Describe "DCIM Racks Tests" -Tag 'DCIM', 'Racks' {
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

    Context "Get-NBDCIMRack" {
        It "Should request racks" {
            $Result = Get-NBDCIMRack
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/racks/'
        }

        It "Should request racks by site" {
            $Result = Get-NBDCIMRack -Site_Id 1
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/racks/?site_id=1'
        }

        Context "Status drift fix (#392 item 5)" {
            It "Should accept -Status 'available'" {
                $Result = Get-NBDCIMRack -Status 'available'
                $Result.Uri | Should -Match 'status=available'
            }
        }
    }

    Context "New-NBDCIMRack" {
        It "Should create a new rack" {
            $Result = New-NBDCIMRack -Name "Rack01" -Site 1
            Should -Invoke -CommandName 'InvokeNetboxRequest' -Times 1 -Exactly -Scope 'It' -ModuleName 'PowerNetbox'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/dcim/racks/'
            $Result.Body | Should -Match '"name":"Rack01"'
            $Result.Body | Should -Match '"site":1'
        }

        Context "Status drift fix (#392 item 5)" {
            It "Should accept -Status 'available'" {
                $Result = New-NBDCIMRack -Name 'rack' -Site 1 -Status 'available'
                ($Result.Body | ConvertFrom-Json).status | Should -Be 'available'
            }
        }

        Context "NetBox 4.6 airflow / form_factor (#395 Phase 1)" {
            It "Should send airflow" {
                $Result = New-NBDCIMRack -Name 'rack' -Site 1 -Airflow 'front-to-rear'
                ($Result.Body | ConvertFrom-Json).airflow | Should -Be 'front-to-rear'
            }
            It "Should send form_factor" {
                $Result = New-NBDCIMRack -Name 'rack' -Site 1 -Form_Factor '4-post-cabinet'
                ($Result.Body | ConvertFrom-Json).form_factor | Should -Be '4-post-cabinet'
            }
            It "Should reject an invalid form_factor" {
                { New-NBDCIMRack -Name 'rack' -Site 1 -Form_Factor 'bogus' } | Should -Throw
            }
        }
    }

    Context "Set-NBDCIMRack" {
        It "Should update a rack" {
            $Result = Set-NBDCIMRack -Id 1 -Name 'UpdatedRack' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/racks/1/'
        }

        Context "Status drift fix (#392 item 5)" {
            It "Should accept -Status 'available'" {
                $Result = Set-NBDCIMRack -Id 1 -Status 'available' -Confirm:$false
                ($Result.Body | ConvertFrom-Json).status | Should -Be 'available'
            }
        }

        Context "NetBox 4.6 airflow / form_factor null-clearing (#395 Phase 1)" {
            It "Should set airflow" {
                $Result = Set-NBDCIMRack -Id 1 -Airflow 'rear-to-front' -Confirm:$false
                ($Result.Body | ConvertFrom-Json).airflow | Should -Be 'rear-to-front'
            }
            It "Should clear airflow with '' sentinel (JSON null)" {
                $Result = Set-NBDCIMRack -Id 1 -Airflow '' -Confirm:$false
                $bodyObj = $Result.Body | ConvertFrom-Json
                # property present and explicitly null
                $bodyObj.PSObject.Properties.Name | Should -Contain 'airflow'
                $bodyObj.airflow | Should -BeNullOrEmpty
            }
            It "Should clear form_factor with '' sentinel" {
                $Result = Set-NBDCIMRack -Id 1 -Form_Factor '' -Confirm:$false
                ($Result.Body | ConvertFrom-Json).form_factor | Should -BeNullOrEmpty
            }
        }
    }

    Context "Remove-NBDCIMRack" {
        It "Should remove a rack" {
            $Result = Remove-NBDCIMRack -Id 10 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/dcim/racks/10/'
        }
    }

    #region Parameter Validation Tests
    Context "Parameter Validation" {
        It "Should reject invalid Status for New-NBDCIMRack" {
            { New-NBDCIMRack -Name 'test' -Site 1 -Status 'invalid' -Confirm:$false } | Should -Throw
        }

        It "Should reject invalid Width for New-NBDCIMRack" {
            { New-NBDCIMRack -Name 'test' -Site 1 -Width 15 -Confirm:$false } | Should -Throw
        }

        It "Should accept valid Width (19) for New-NBDCIMRack" {
            { New-NBDCIMRack -Name 'test' -Site 1 -Width 19 -Confirm:$false } | Should -Not -Throw
        }

        It "Should reject U_Height below minimum (0) for New-NBDCIMRack" {
            { New-NBDCIMRack -Name 'test' -Site 1 -U_Height 0 -Confirm:$false } | Should -Throw
        }

        It "Should reject U_Height above maximum (101) for New-NBDCIMRack" {
            { New-NBDCIMRack -Name 'test' -Site 1 -U_Height 101 -Confirm:$false } | Should -Throw
        }

        It "Should reject invalid Weight_Unit for New-NBDCIMRack" {
            { New-NBDCIMRack -Name 'test' -Site 1 -Weight_Unit 'ton' -Confirm:$false } | Should -Throw
        }

        It "Should reject invalid Face for Get-NBDCIMRackElevation" {
            { Get-NBDCIMRackElevation -Id 1 -Face 'invalid' } | Should -Throw
        }

        It "Should reject invalid Render for Get-NBDCIMRackElevation" {
            { Get-NBDCIMRackElevation -Id 1 -Render 'invalid' } | Should -Throw
        }

        It "Should reject invalid Status for Get-NBDCIMRack" {
            { Get-NBDCIMRack -Status 'invalid' } | Should -Throw
        }

        It "Should require mandatory Name for New-NBDCIMRack" {
            { New-NBDCIMRack -Site 1 -Confirm:$false } | Should -Throw
        }

        It "Should require mandatory Site for New-NBDCIMRack" {
            { New-NBDCIMRack -Name 'test' -Confirm:$false } | Should -Throw
        }
    }
    #endregion

    #region WhatIf Tests
    Context "WhatIf Support" {
        $whatIfTestCases = @(
            @{ Command = 'New-NBDCIMRack'; Parameters = @{ Name = 'whatif-test'; Site = 1 } }
            @{ Command = 'Set-NBDCIMRack'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBDCIMRack'; Parameters = @{ Id = 1 } }
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
            @{ Command = 'Get-NBDCIMRack' }
            @{ Command = 'Get-NBDCIMRackElevation'; Parameters = @{ Id = 1 } }
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
            @{ Command = 'Get-NBDCIMRack' }
        )

        It 'Should pass -Omit to query string for <Command>' -TestCases $omitTestCases {
            param($Command)
            $Result = & $Command -Omit @('comments', 'description')
            $Result.Uri | Should -Match 'omit=comments%2Cdescription'
        }
    }
    #endregion
}
