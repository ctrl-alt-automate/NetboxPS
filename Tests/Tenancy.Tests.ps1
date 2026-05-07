<#
.SYNOPSIS
    Unit tests for Tenancy module functions.

.DESCRIPTION
    Tests for Tenant, TenantGroup, Contact, ContactRole, and ContactAssignment functions.
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

Describe "Tenancy Module Tests" -Tag 'Tenancy' {
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

    #region Tenant Tests
    Context "Get-NBTenant" {
        It "Should request tenants" {
            $Result = Get-NBTenant
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/tenants/'
        }

        It "Should request a tenant by ID" {
            $Result = Get-NBTenant -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/tenants/5/'
        }

        It "Should request a tenant by name" {
            $Result = Get-NBTenant -Name 'Acme Corp'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/tenants/?name=Acme%20Corp'
        }

        It "Should request a tenant by slug" {
            $Result = Get-NBTenant -Slug 'acme-corp'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/tenants/?slug=acme-corp'
        }

        It "Should request with limit and offset" {
            $Result = Get-NBTenant -Limit 10 -Offset 20
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=20'
        }
    }

    Context "New-NBTenant" {
        It "Should create a tenant" {
            $Result = New-NBTenant -Name 'NewTenant' -Slug 'new-tenant'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/tenants/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'NewTenant'
            $bodyObj.slug | Should -Be 'new-tenant'
        }

        It "Should create a tenant with description" {
            $Result = New-NBTenant -Name 'NewTenant' -Slug 'new-tenant' -Description 'Test description'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.description | Should -Be 'Test description'
        }
    }

    Context "Set-NBTenant" {
        BeforeAll {
            Mock -CommandName "Get-NBTenant" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestTenant' }
            }
        }

        It "Should update a tenant" {
            $Result = Set-NBTenant -Id 1 -Name 'UpdatedTenant' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/tenancy/tenants/1/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'UpdatedTenant'
        }

        It "Should update a tenant description" {
            $Result = Set-NBTenant -Id 1 -Description 'New description' -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.description | Should -Be 'New description'
        }
    }

    Context "Remove-NBTenant" {
        BeforeAll {
            Mock -CommandName "Get-NBTenant" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestTenant' }
            }
        }

        It "Should remove a tenant" {
            $Result = Remove-NBTenant -Id 10 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/tenancy/tenants/10/'
        }

        It "Should remove multiple tenants via pipeline" {
            # Remove- functions only accept single Id; use pipeline for bulk operations
            $Result = @(
                [pscustomobject]@{ 'Id' = 10 },
                [pscustomobject]@{ 'Id' = 11 }
            ) | Remove-NBTenant -Confirm:$false
            $Result.Method | Should -Be 'DELETE', 'DELETE'
        }
    }
    #endregion

    #region TenantGroup Tests
    Context "Get-NBTenantGroup" {
        It "Should request tenant groups" {
            $Result = Get-NBTenantGroup
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/tenant-groups/'
        }

        It "Should request a tenant group by ID" {
            $Result = Get-NBTenantGroup -Id 3
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/tenant-groups/3/'
        }

        It "Should request a tenant group by name" {
            $Result = Get-NBTenantGroup -Name 'Corporate'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/tenant-groups/?name=Corporate'
        }

        It "Should request a tenant group by slug" {
            $Result = Get-NBTenantGroup -Slug 'corporate'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/tenant-groups/?slug=corporate'
        }
    }

    Context "New-NBTenantGroup" {
        It "Should create a tenant group" {
            $Result = New-NBTenantGroup -Name 'NewGroup' -Slug 'new-group'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/tenant-groups/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'NewGroup'
            $bodyObj.slug | Should -Be 'new-group'
        }

        It "Should create a tenant group with parent" {
            $Result = New-NBTenantGroup -Name 'NewGroup' -Slug 'new-group' -Parent 1
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.parent | Should -Be 1
        }
    }

    Context "Set-NBTenantGroup" {
        BeforeAll {
            Mock -CommandName "Get-NBTenantGroup" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestGroup' }
            }
        }

        It "Should update a tenant group" {
            $Result = Set-NBTenantGroup -Id 1 -Name 'UpdatedGroup' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/tenancy/tenant-groups/1/'
        }
    }

    Context "Remove-NBTenantGroup" {
        BeforeAll {
            Mock -CommandName "Get-NBTenantGroup" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestGroup' }
            }
        }

        It "Should remove a tenant group" {
            $Result = Remove-NBTenantGroup -Id 5 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/tenancy/tenant-groups/5/'
        }
    }
    #endregion

    #region Contact Tests
    Context "Get-NBContact" {
        It "Should request contacts" {
            $Result = Get-NBContact
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/contacts/'
        }

        It "Should request a contact by ID" {
            $Result = Get-NBContact -Id 7
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/contacts/7/'
        }

        It "Should request a contact by name" {
            $Result = Get-NBContact -Name 'John Doe'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/contacts/?name=John%20Doe'
        }
    }

    Context "New-NBContact" {
        It "Should create a contact" {
            $Result = New-NBContact -Name 'Jane Doe' -Email 'jane@example.com'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/contacts/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'Jane Doe'
            $bodyObj.email | Should -Be 'jane@example.com'
        }

        It "Should create a contact with phone" {
            $Result = New-NBContact -Name 'Jane Doe' -Email 'jane@example.com' -Phone '+1-555-1234'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.phone | Should -Be '+1-555-1234'
        }
    }

    Context "Set-NBContact" {
        It "Should update a contact" {
            $Result = Set-NBContact -Id 1 -Name 'Updated Name' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/tenancy/contacts/1/'
        }

        It "Should update contact email" {
            $Result = Set-NBContact -Id 1 -Email 'new@example.com' -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.email | Should -Be 'new@example.com'
        }
    }

    Context "Remove-NBContact" {
        BeforeAll {
            Mock -CommandName "Get-NBContact" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestContact' }
            }
        }

        It "Should remove a contact" {
            $Result = Remove-NBContact -Id 8 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/tenancy/contacts/8/'
        }
    }
    #endregion

    #region ContactRole Tests
    Context "Get-NBContactRole" {
        It "Should request contact roles" {
            $Result = Get-NBContactRole
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/contact-roles/'
        }

        It "Should request a contact role by ID" {
            $Result = Get-NBContactRole -Id 2
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/contact-roles/2/'
        }

        It "Should request a contact role by name" {
            $Result = Get-NBContactRole -Name 'Administrator'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/contact-roles/?name=Administrator'
        }
    }

    Context "New-NBContactRole" {
        It "Should create a contact role" {
            $Result = New-NBContactRole -Name 'Manager' -Slug 'manager'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/contact-roles/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'Manager'
            $bodyObj.slug | Should -Be 'manager'
        }
    }

    Context "Set-NBContactRole" {
        BeforeAll {
            Mock -CommandName "Get-NBContactRole" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestRole' }
            }
        }

        It "Should update a contact role" {
            $Result = Set-NBContactRole -Id 1 -Name 'Updated Role' -Confirm:$false
            # Performance optimization: no longer fetches the object before updating
            Should -Invoke -CommandName 'Get-NBContactRole' -Times 0 -Exactly -Scope 'It' -ModuleName 'PowerNetbox'
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/tenancy/contact-roles/1/'
        }
    }

    Context "Remove-NBContactRole" {
        BeforeAll {
            Mock -CommandName "Get-NBContactRole" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestRole' }
            }
        }

        It "Should remove a contact role" {
            $Result = Remove-NBContactRole -Id 3 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/tenancy/contact-roles/3/'
        }
    }
    #endregion

    #region ContactAssignment Tests
    Context "Get-NBContactAssignment" {
        It "Should request contact assignments" {
            $Result = Get-NBContactAssignment
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/contact-assignments/'
        }

        It "Should request a contact assignment by ID" {
            $Result = Get-NBContactAssignment -Id 4
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/contact-assignments/4/'
        }
    }

    Context "New-NBContactAssignment" {
        It "Should create a contact assignment" {
            $Result = New-NBContactAssignment -Object_Type 'dcim.site' -Object_Id 1 -Contact 5 -Role 2
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/tenancy/contact-assignments/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.object_type | Should -Be 'dcim.site'
            $bodyObj.object_id | Should -Be 1
            $bodyObj.contact | Should -Be 5
            $bodyObj.role | Should -Be 2
        }
    }

    Context "Set-NBContactAssignment" {
        BeforeAll {
            Mock -CommandName "Get-NBContactAssignment" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id }
            }
        }

        It "Should update a contact assignment" {
            $Result = Set-NBContactAssignment -Id 1 -Priority 'primary' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/tenancy/contact-assignments/1/'
        }
    }

    Context "Remove-NBContactAssignment" {
        BeforeAll {
            Mock -CommandName "Get-NBContactAssignment" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id }
            }
        }

        It "Should remove a contact assignment" {
            $Result = Remove-NBContactAssignment -Id 6 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/tenancy/contact-assignments/6/'
        }
    }
    #endregion

    #region WhatIf Tests
    Context "WhatIf Support" {
        $whatIfTestCases = @(
            @{ Command = 'New-NBContact'; Parameters = @{ Name = 'whatif-test' } }
            @{ Command = 'New-NBContactAssignment'; Parameters = @{ Object_Type = 'dcim.device'; Object_Id = 1; Contact = 1; Role = 1 } }
            @{ Command = 'New-NBContactRole'; Parameters = @{ Name = 'whatif-test'; Slug = 'whatif-test' } }
            @{ Command = 'New-NBTenant'; Parameters = @{ Name = 'whatif-test'; Slug = 'whatif-test' } }
            @{ Command = 'New-NBTenantGroup'; Parameters = @{ Name = 'whatif-test' } }
            @{ Command = 'Set-NBContact'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBContactAssignment'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBContactRole'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBTenant'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBTenantGroup'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBContact'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBContactAssignment'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBContactRole'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBTenant'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBTenantGroup'; Parameters = @{ Id = 1 } }
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
            @{ Command = 'Get-NBContact' }
            @{ Command = 'Get-NBContactAssignment' }
            @{ Command = 'Get-NBContactRole' }
            @{ Command = 'Get-NBTenant' }
            @{ Command = 'Get-NBTenantGroup' }
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
            @{ Command = 'Get-NBContact' }
            @{ Command = 'Get-NBContactAssignment' }
            @{ Command = 'Get-NBContactRole' }
            @{ Command = 'Get-NBTenant' }
            @{ Command = 'Get-NBTenantGroup' }
        )

        It 'Should pass -Omit to query string for <Command>' -TestCases $omitTestCases {
            param($Command)
            $Result = & $Command -Omit @('comments', 'description')
            $Result.Uri | Should -Match 'omit=comments%2Cdescription'
        }
    }
    #endregion

    #region Pipeline Input Tests
    Context "Pipeline Input" {
        $pipelineTestCases = @(
            @{ Command = 'Get-NBTenant' }
        )

        It 'Should accept pipeline input by property name for <Command>' -TestCases $pipelineTestCases {
            param($Command)
            $Result = [pscustomobject]@{ 'Id' = 10 } | & $Command
            $Result.Uri | Should -Match '/10/'
        }
    }
    #endregion
}
