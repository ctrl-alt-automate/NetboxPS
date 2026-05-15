<#
.SYNOPSIS
    Unit tests for IPAM module functions.

.DESCRIPTION
    Comprehensive tests for all IPAM module functions including Address, Prefix, VLAN, VRF,
    ASN, RIR, Role, Aggregate, FHRPGroup, Service, RouteTarget, and more.
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

Describe "IPAM tests" -Tag 'Ipam' {
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
    }

    #region Address Tests
    Context "Get-NBIPAMAddress" {
        It "Should request addresses" {
            $Result = Get-NBIPAMAddress
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/'
        }

        It "Should request with limit and offset" {
            $Result = Get-NBIPAMAddress -Limit 10 -Offset 12
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=12'
        }

        It "Should request with a query" {
            $Result = Get-NBIPAMAddress -Query '10.10.10.10'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/?q=10.10.10.10'
        }

        It "Should request with a single ID" {
            $Result = Get-NBIPAMAddress -Id 10
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/10/'
        }

        It "Should request with a family number" {
            $Result = Get-NBIPAMAddress -Family 4
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/?family=4'
        }

        Context "Brief/Fields/Omit mutual exclusion" {
            It "Throws when -Brief and -Fields are both specified" {
                { Get-NBIPAMAddress -Brief -Fields 'id' } |
                    Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
            }

            It "Throws when -Brief and -Omit are both specified" {
                { Get-NBIPAMAddress -Brief -Omit 'comments' } |
                    Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
            }

            It "Throws when -Fields and -Omit are both specified" {
                { Get-NBIPAMAddress -Fields 'id' -Omit 'comments' } |
                    Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
            }

            It "Does not throw when -Brief is specified alone (control)" {
                $Result = Get-NBIPAMAddress -Brief
                $Result.Method | Should -Be 'GET'
                $Result.Uri | Should -Match 'brief=True'
            }
        }
    }

    Context "New-NBIPAMAddress" {
        It "Should create an IP address" {
            $Result = New-NBIPAMAddress -Address '10.0.0.1/24'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.address | Should -Be '10.0.0.1/24'
        }

        It "Should create an IP with status and role" {
            $Result = New-NBIPAMAddress -Address '10.0.0.1/24' -Status 'Reserved' -Role 'Anycast'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.status | Should -Be 'Reserved'
            $bodyObj.role | Should -Be 'Anycast'
        }
    }

    Context "Set-NBIPAMAddress" {
        BeforeAll {
            Mock -CommandName "Get-NBIPAMAddress" -ModuleName PowerNetbox -MockWith {
                return @{ 'address' = '10.1.1.1/24'; 'id' = $id }
            }
        }

        It "Should update an IP address" {
            $Result = Set-NBIPAMAddress -Id 4109 -Status 'reserved' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/4109/'
        }

        It "Should update IP with VRF and Tenant" {
            $Result = Set-NBIPAMAddress -Id 4110 -VRF 10 -Tenant 14 -Description 'Test' -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.vrf | Should -Be 10
            $bodyObj.tenant | Should -Be 14
        }
    }

    Context "Remove-NBIPAMAddress" {
        BeforeAll {
            Mock -CommandName "Get-NBIPAMAddress" -ModuleName PowerNetbox -MockWith {
                return @{ 'address' = "10.1.1.1/$Id"; 'id' = $id }
            }
        }

        It "Should remove an IP address" {
            $Result = Remove-NBIPAMAddress -Id 4109 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-addresses/4109/'
        }
    }

    Context "Get-NBIPAMAvailableIP" {
        It "Should request available IPs" {
            $Result = Get-NBIPAMAvailableIP -Prefix_Id 10
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/10/available-ips/'
        }

        It "Should request 10 available IPs" {
            $Result = Get-NBIPAMAvailableIP -Prefix_Id 1504 -NumberOfIPs 10
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/1504/available-ips/?limit=10'
        }
    }
    #endregion

    #region Prefix Tests
    Context "Get-NBIPAMPrefix" {
        It "Should request prefixes" {
            $Result = Get-NBIPAMPrefix
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/'
        }

        It "Should request with a single ID" {
            $Result = Get-NBIPAMPrefix -Id 10
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/10/'
        }

        It "Should request with VLAN vID" {
            $Result = Get-NBIPAMPrefix -VLAN_VID 10
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/?vlan_vid=10'
        }

        It "Should request with mask length 24" {
            $Result = Get-NBIPAMPrefix -Mask_length 24
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/?mask_length=24'
        }

        It "Should throw for invalid mask length" {
            { Get-NBIPAMPrefix -Mask_length 128 } | Should -Throw
        }

        It "Should filter by scope_type" {
            $Result = Get-NBIPAMPrefix -Scope_Type 'dcim.site'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/?scope_type=dcim.site'
        }

        It "Should filter by scope_type and scope_id" {
            $Result = Get-NBIPAMPrefix -Scope_Type 'dcim.site' -Scope_Id 5
            $Result.Uri | Should -Match 'scope_type=dcim.site'
            $Result.Uri | Should -Match 'scope_id=5'
        }

        It "Should filter by scope_type dcim.region" {
            $Result = Get-NBIPAMPrefix -Scope_Type 'dcim.region' -Scope_Id 3
            $Result.Uri | Should -Match 'scope_type=dcim.region'
            $Result.Uri | Should -Match 'scope_id=3'
        }

        It "Should reject invalid scope_type" {
            { Get-NBIPAMPrefix -Scope_Type 'invalid.type' } | Should -Throw
        }

        It "Should not have Site parameter" {
            $cmd = Get-Command Get-NBIPAMPrefix
            $cmd.Parameters.Keys | Should -Not -Contain 'Site'
            $cmd.Parameters.Keys | Should -Not -Contain 'Site_Id'
        }
    }

    Context "New-NBIPAMPrefix" {
        It "Should create a prefix" {
            $Result = New-NBIPAMPrefix -Prefix "10.0.0.0/24"
            $Result.Method | Should -Be 'POST'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.prefix | Should -Be '10.0.0.0/24'
        }

        It "Should create a prefix with status and role" {
            $Result = New-NBIPAMPrefix -Prefix "10.0.0.0/24" -Status 'active' -Role 1
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.status | Should -Be 'active'
            $bodyObj.role | Should -Be 1
        }

        It "Should create a prefix with scope_type and scope_id" {
            $Result = New-NBIPAMPrefix -Prefix "10.0.0.0/24" -Scope_Type 'dcim.site' -Scope_Id 5
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.scope_type | Should -Be 'dcim.site'
            $bodyObj.scope_id | Should -Be 5
        }

        It "Should create a prefix with scope_type dcim.location" {
            $Result = New-NBIPAMPrefix -Prefix "10.0.0.0/24" -Scope_Type 'dcim.location' -Scope_Id 10
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.scope_type | Should -Be 'dcim.location'
            $bodyObj.scope_id | Should -Be 10
        }

        It "Should reject invalid scope_type" {
            { New-NBIPAMPrefix -Prefix "10.0.0.0/24" -Scope_Type 'invalid.type' } | Should -Throw
        }

        It "Should throw when Scope_Type is provided without Scope_Id" {
            { New-NBIPAMPrefix -Prefix "10.0.0.0/24" -Scope_Type 'dcim.site' } | Should -Throw '*must be used together*'
        }

        It "Should throw when Scope_Id is provided without Scope_Type" {
            { New-NBIPAMPrefix -Prefix "10.0.0.0/24" -Scope_Id 5 } | Should -Throw '*must be used together*'
        }

        It "Should not have Site parameter" {
            $cmd = Get-Command New-NBIPAMPrefix
            $cmd.Parameters.Keys | Should -Not -Contain 'Site'
        }
    }

    Context "Set-NBIPAMPrefix" {
        BeforeAll {
            Mock -CommandName "Get-NBIPAMPrefix" -ModuleName PowerNetbox -MockWith {
                return @{ 'prefix' = '10.0.0.0/24'; 'id' = $id }
            }
        }

        It "Should update a prefix" {
            $Result = Set-NBIPAMPrefix -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/ipam/prefixes/1/'
        }

        It "Should update prefix scope" {
            $Result = Set-NBIPAMPrefix -Id 1 -Scope_Type 'dcim.site' -Scope_Id 5 -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.scope_type | Should -Be 'dcim.site'
            $bodyObj.scope_id | Should -Be 5
        }

        It "Should reject invalid scope_type" {
            { Set-NBIPAMPrefix -Id 1 -Scope_Type 'invalid.type' -Confirm:$false } | Should -Throw
        }

        It "Should throw when Scope_Type is provided without Scope_Id" {
            { Set-NBIPAMPrefix -Id 1 -Scope_Type 'dcim.site' -Confirm:$false } | Should -Throw '*must be used together*'
        }

        It "Should throw when Scope_Id is provided without Scope_Type" {
            { Set-NBIPAMPrefix -Id 1 -Scope_Id 5 -Confirm:$false } | Should -Throw '*must be used together*'
        }

        It "Should not have Site parameter" {
            $cmd = Get-Command Set-NBIPAMPrefix
            $cmd.Parameters.Keys | Should -Not -Contain 'Site'
        }
    }

    Context "Remove-NBIPAMPrefix" {
        BeforeAll {
            Mock -CommandName "Get-NBIPAMPrefix" -ModuleName PowerNetbox -MockWith {
                return @{ 'prefix' = '10.0.0.0/24'; 'id' = $id }
            }
        }

        It "Should remove a prefix" {
            $Result = Remove-NBIPAMPrefix -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/ipam/prefixes/1/'
        }
    }
    #endregion

    #region Aggregate Tests
    Context "Get-NBIPAMAggregate" {
        It "Should request aggregates" {
            $Result = Get-NBIPAMAggregate
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/aggregates/'
        }

        It "Should request with a query" {
            $Result = Get-NBIPAMAggregate -Query '10.10.0.0'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/aggregates/?q=10.10.0.0'
        }

        It "Should request with a single ID" {
            $Result = Get-NBIPAMAggregate -Id 10
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/aggregates/10/'
        }
    }

    Context "New-NBIPAMAggregate" {
        It "Should create an aggregate" {
            $Result = New-NBIPAMAggregate -Prefix '10.0.0.0/8' -RIR 1
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/aggregates/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.prefix | Should -Be '10.0.0.0/8'
            $bodyObj.rir | Should -Be 1
        }
    }

    Context "Set-NBIPAMAggregate" {
        BeforeAll {
            Mock -CommandName "Get-NBIPAMAggregate" -ModuleName PowerNetbox -MockWith {
                return @{ 'prefix' = '10.0.0.0/8'; 'id' = $id }
            }
        }

        It "Should update an aggregate" {
            $Result = Set-NBIPAMAggregate -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/ipam/aggregates/1/'
        }
    }

    Context "Remove-NBIPAMAggregate" {
        BeforeAll {
            Mock -CommandName "Get-NBIPAMAggregate" -ModuleName PowerNetbox -MockWith {
                return @{ 'prefix' = '10.0.0.0/8'; 'id' = $id }
            }
        }

        It "Should remove an aggregate" {
            $Result = Remove-NBIPAMAggregate -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/ipam/aggregates/1/'
        }
    }
    #endregion

    #region VLAN Tests
    Context "Get-NBIPAMVLAN" {
        It "Should request VLANs" {
            $Result = Get-NBIPAMVLAN
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/vlans/'
        }

        It "Should request a VLAN by ID" {
            $Result = Get-NBIPAMVLAN -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/vlans/5/'
        }

        It "Should request a VLAN by VID" {
            $Result = Get-NBIPAMVLAN -VID 100
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/vlans/?vid=100'
        }
    }

    Context "New-NBIPAMVLAN" {
        It "Should create a VLAN" {
            $Result = New-NBIPAMVLAN -VID 100 -Name 'VLAN100'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/vlans/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.vid | Should -Be 100
            $bodyObj.name | Should -Be 'VLAN100'
        }
    }

    Context "Set-NBIPAMVLAN" {
        BeforeAll {
            Mock -CommandName "Get-NBIPAMVLAN" -ModuleName PowerNetbox -MockWith {
                return @{ 'vid' = 100; 'id' = $id }
            }
        }

        It "Should update a VLAN" {
            $Result = Set-NBIPAMVLAN -Id 1 -Name 'Updated VLAN' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/ipam/vlans/1/'
        }
    }

    Context "Remove-NBIPAMVLAN" {
        BeforeAll {
            Mock -CommandName "Get-NBIPAMVLAN" -ModuleName PowerNetbox -MockWith {
                return @{ 'vid' = 100; 'id' = $id }
            }
        }

        It "Should remove a VLAN" {
            $Result = Remove-NBIPAMVLAN -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/ipam/vlans/1/'
        }
    }
    #endregion

    #region VLANGroup Tests
    Context "Get-NBIPAMVLANGroup" {
        It "Should request VLAN groups" {
            $Result = Get-NBIPAMVLANGroup
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/vlan-groups/'
        }

        It "Should request a VLAN group by ID" {
            $Result = Get-NBIPAMVLANGroup -Id 3
            $Result.Uri | Should -Match '/api/ipam/vlan.groups/3/'
        }
    }

    Context "New-NBIPAMVLANGroup" {
        It "Should create a VLAN group" {
            $Result = New-NBIPAMVLANGroup -Name 'TestGroup' -Slug 'test-group'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/vlan-groups/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'TestGroup'
        }
    }

    Context "Set-NBIPAMVLANGroup" {
        It "Should update a VLAN group" {
            $Result = Set-NBIPAMVLANGroup -Id 1 -Name 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/ipam/vlan.groups/1/'
        }
    }

    Context "Remove-NBIPAMVLANGroup" {
        BeforeAll {
            Mock -CommandName "Get-NBIPAMVLANGroup" -ModuleName PowerNetbox -MockWith {
                return @{ 'name' = 'TestGroup'; 'id' = $id }
            }
        }

        It "Should remove a VLAN group" {
            $Result = Remove-NBIPAMVLANGroup -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/ipam/vlan.groups/1/'
        }
    }
    #endregion

    #region VRF Tests
    Context "Get-NBIPAMVRF" {
        It "Should request VRFs" {
            $Result = Get-NBIPAMVRF
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/vrfs/'
        }

        It "Should request a VRF by ID" {
            $Result = Get-NBIPAMVRF -Id 5
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/vrfs/5/'
        }

        It "Should request a VRF by name" {
            $Result = Get-NBIPAMVRF -Name 'Production'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/vrfs/?name=Production'
        }
    }

    Context "Get-NBIPAMVRF -All/-PageSize passthrough" {
        It "Should pass -All switch to InvokeNetboxRequest" {
            Get-NBIPAMVRF -All
            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -ParameterFilter {
                $All -eq $true
            }
        }

        It "Should pass -PageSize to InvokeNetboxRequest" {
            Get-NBIPAMVRF -All -PageSize 500
            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -ParameterFilter {
                $PageSize -eq 500
            }
        }
    }

    Context "New-NBIPAMVRF" {
        It "Should create a VRF" {
            $Result = New-NBIPAMVRF -Name 'TestVRF'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/vrfs/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'TestVRF'
        }

        It "Should create a VRF with RD" {
            $Result = New-NBIPAMVRF -Name 'TestVRF' -RD '65000:100'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.rd | Should -Be '65000:100'
        }
    }

    Context "Set-NBIPAMVRF" {
        It "Should update a VRF" {
            $Result = Set-NBIPAMVRF -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/ipam/vrfs/1/'
        }
    }

    Context "Remove-NBIPAMVRF" {
        BeforeAll {
            Mock -CommandName "Get-NBIPAMVRF" -ModuleName PowerNetbox -MockWith {
                return @{ 'name' = 'TestVRF'; 'id' = $id }
            }
        }

        It "Should remove a VRF" {
            $Result = Remove-NBIPAMVRF -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/ipam/vrfs/1/'
        }
    }
    #endregion

    #region RIR Tests
    Context "Get-NBIPAMRIR" {
        It "Should request RIRs" {
            $Result = Get-NBIPAMRIR
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/rirs/'
        }

        It "Should request a RIR by ID" {
            $Result = Get-NBIPAMRIR -Id 2
            $Result.Uri | Should -Match '/api/ipam/rirs/2/'
        }
    }

    Context "New-NBIPAMRIR" {
        It "Should create a RIR" {
            $Result = New-NBIPAMRIR -Name 'RFC1918' -Slug 'rfc1918'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/rirs/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'RFC1918'
        }
    }

    Context "Set-NBIPAMRIR" {
        It "Should update a RIR" {
            $Result = Set-NBIPAMRIR -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/ipam/rirs/1/'
        }
    }

    Context "Remove-NBIPAMRIR" {
        BeforeAll {
            Mock -CommandName "Get-NBIPAMRIR" -ModuleName PowerNetbox -MockWith {
                return @{ 'name' = 'RFC1918'; 'id' = $id }
            }
        }

        It "Should remove a RIR" {
            $Result = Remove-NBIPAMRIR -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/ipam/rirs/1/'
        }
    }
    #endregion

    #region Role Tests
    Context "Get-NBIPAMRole" {
        It "Should request roles by name" {
            $Result = Get-NBIPAMRole -Name 'Production'
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Match '/api/ipam/roles/'
            $Result.Uri | Should -Match 'name=Production'
        }

        It "Should request a role by ID" {
            $Result = Get-NBIPAMRole -Id 3
            $Result.Uri | Should -Match '/api/ipam/roles/3/'
        }
    }

    Context "New-NBIPAMRole" {
        It "Should create a role" {
            $Result = New-NBIPAMRole -Name 'Production' -Slug 'production'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/roles/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'Production'
        }
    }

    Context "Set-NBIPAMRole" {
        It "Should update a role" {
            $Result = Set-NBIPAMRole -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/ipam/roles/1/'
        }
    }

    Context "Remove-NBIPAMRole" {
        BeforeAll {
            Mock -CommandName "Get-NBIPAMRole" -ModuleName PowerNetbox -MockWith {
                return @{ 'name' = 'Production'; 'id' = $id }
            }
        }

        It "Should remove a role" {
            $Result = Remove-NBIPAMRole -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/ipam/roles/1/'
        }
    }
    #endregion

    #region ASN Tests
    Context "Get-NBIPAMASN" {
        It "Should request ASNs" {
            $Result = Get-NBIPAMASN
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/asns/'
        }

        It "Should request an ASN by ID" {
            $Result = Get-NBIPAMASN -Id 5
            $Result.Uri | Should -Match '/api/ipam/asns/5/'
        }
    }

    Context "New-NBIPAMASN" {
        It "Should create an ASN" {
            $Result = New-NBIPAMASN -ASN 65000 -RIR 1
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/asns/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.asn | Should -Be 65000
        }

        It "Should send the role (NetBox 4.6+)" {
            $Result = New-NBIPAMASN -ASN 65001 -Role 3
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.role | Should -Be 3
        }
    }

    Context "Set-NBIPAMASN" {
        It "Should update an ASN" {
            $Result = Set-NBIPAMASN -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/ipam/asns/1/'
        }

        It "Should set the role (NetBox 4.6+)" {
            $Result = Set-NBIPAMASN -Id 1 -Role 5 -Confirm:$false
            ($Result.Body | ConvertFrom-Json).role | Should -Be 5
        }

        It "Should clear the role with `$null (NetBox 4.6+)" {
            $Result = Set-NBIPAMASN -Id 1 -Role $null -Confirm:$false
            $Result.Body | ConvertFrom-Json | Select-Object -ExpandProperty role | Should -BeNullOrEmpty
        }
    }

    Context "Remove-NBIPAMASN" {
        BeforeAll {
            Mock -CommandName "Get-NBIPAMASN" -ModuleName PowerNetbox -MockWith {
                return @{ 'asn' = 65000; 'id' = $id }
            }
        }

        It "Should remove an ASN" {
            $Result = Remove-NBIPAMASN -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/ipam/asns/1/'
        }
    }
    #endregion

    #region ASNRange Tests
    Context "Get-NBIPAMASNRange" {
        It "Should request ASN ranges" {
            $Result = Get-NBIPAMASNRange
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/asn-ranges/'
        }

        It "Should request an ASN range by ID" {
            $Result = Get-NBIPAMASNRange -Id 2
            $Result.Uri | Should -Match '/api/ipam/asn.ranges/2/'
        }
    }

    Context "New-NBIPAMASNRange" {
        It "Should create an ASN range" {
            $Result = New-NBIPAMASNRange -Name 'Private' -Slug 'private' -RIR 1 -Start 64512 -End 65534
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/asn-ranges/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'Private'
        }
    }

    Context "Set-NBIPAMASNRange" {
        It "Should update an ASN range" {
            $Result = Set-NBIPAMASNRange -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/ipam/asn.ranges/1/'
        }
    }

    Context "Remove-NBIPAMASNRange" {
        BeforeAll {
            Mock -CommandName "Get-NBIPAMASNRange" -ModuleName PowerNetbox -MockWith {
                return @{ 'name' = 'Private'; 'id' = $id }
            }
        }

        It "Should remove an ASN range" {
            $Result = Remove-NBIPAMASNRange -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/ipam/asn.ranges/1/'
        }
    }
    #endregion

    #region RouteTarget Tests
    Context "Get-NBIPAMRouteTarget" {
        It "Should request route targets" {
            $Result = Get-NBIPAMRouteTarget
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/route-targets/'
        }

        It "Should request a route target by ID" {
            $Result = Get-NBIPAMRouteTarget -Id 4
            $Result.Uri | Should -Match '/api/ipam/route.targets/4/'
        }
    }

    Context "New-NBIPAMRouteTarget" {
        It "Should create a route target" {
            $Result = New-NBIPAMRouteTarget -Name '65000:100'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/route-targets/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be '65000:100'
        }
    }

    Context "Set-NBIPAMRouteTarget" {
        It "Should update a route target" {
            $Result = Set-NBIPAMRouteTarget -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/ipam/route.targets/1/'
        }
    }

    Context "Remove-NBIPAMRouteTarget" {
        BeforeAll {
            Mock -CommandName "Get-NBIPAMRouteTarget" -ModuleName PowerNetbox -MockWith {
                return @{ 'name' = '65000:100'; 'id' = $id }
            }
        }

        It "Should remove a route target" {
            $Result = Remove-NBIPAMRouteTarget -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/ipam/route.targets/1/'
        }
    }
    #endregion

    #region AddressRange Tests
    Context "Get-NBIPAMAddressRange" {
        It "Should request address ranges" {
            $Result = Get-NBIPAMAddressRange
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-ranges/'
        }

        It "Should request an address range by ID" {
            $Result = Get-NBIPAMAddressRange -Id 6
            $Result.Uri | Should -Match '/api/ipam/ip.ranges/6/'
        }

        It "Should request address ranges by parent prefix" {
            $Result = Get-NBIPAMAddressRange -Parent '10.0.0.0/24'
            $Result.Uri | Should -Match 'parent=10\.0\.0\.0'
        }

        It "Should filter by mark_utilized" {
            $Result = Get-NBIPAMAddressRange -Mark_Utilized $true
            $Result.Uri | Should -Match 'mark_utilized=True'
        }

        It "Should filter by mark_populated" {
            $Result = Get-NBIPAMAddressRange -Mark_Populated $false
            $Result.Uri | Should -Match 'mark_populated=False'
        }
    }

    Context "New-NBIPAMAddressRange" {
        It "Should create an address range" {
            $Result = New-NBIPAMAddressRange -Start_Address '10.0.0.1/24' -End_Address '10.0.0.100/24'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/ip-ranges/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.start_address | Should -Be '10.0.0.1/24'
        }

        It "Should pass mark_utilized in body" {
            $Result = New-NBIPAMAddressRange -Start_Address '10.0.0.1/24' -End_Address '10.0.0.100/24' -Mark_Utilized $true
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.mark_utilized | Should -BeTrue
        }

        It "Should pass mark_populated in body" {
            $Result = New-NBIPAMAddressRange -Start_Address '10.0.0.1/24' -End_Address '10.0.0.100/24' -Mark_Populated $true
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.mark_populated | Should -BeTrue
        }

        It "Should pass mark_utilized false in body" {
            $Result = New-NBIPAMAddressRange -Start_Address '10.0.0.1/24' -End_Address '10.0.0.100/24' -Mark_Utilized $false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.mark_utilized | Should -BeFalse
        }

        It "Mark_Utilized should be [bool] not [switch]" {
            $param = (Get-Command New-NBIPAMAddressRange).Parameters['Mark_Utilized']
            $param.ParameterType.Name | Should -Be 'Boolean'
        }

        It "Mark_Populated should be [bool]" {
            $param = (Get-Command New-NBIPAMAddressRange).Parameters['Mark_Populated']
            $param.ParameterType.Name | Should -Be 'Boolean'
        }
    }

    Context "Set-NBIPAMAddressRange" {
        It "Should update an address range" {
            $Result = Set-NBIPAMAddressRange -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/ipam/ip.ranges/1/'
        }

        It "Should pass mark_utilized in body" {
            $Result = Set-NBIPAMAddressRange -Id 1 -Mark_Utilized $true -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.mark_utilized | Should -BeTrue
        }

        It "Should pass mark_populated in body" {
            $Result = Set-NBIPAMAddressRange -Id 1 -Mark_Populated $true -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.mark_populated | Should -BeTrue
        }

        It "Mark_Utilized should be [bool] not [switch]" {
            $param = (Get-Command Set-NBIPAMAddressRange).Parameters['Mark_Utilized']
            $param.ParameterType.Name | Should -Be 'Boolean'
        }

        It "Mark_Populated should be [bool]" {
            $param = (Get-Command Set-NBIPAMAddressRange).Parameters['Mark_Populated']
            $param.ParameterType.Name | Should -Be 'Boolean'
        }
    }

    Context "Remove-NBIPAMAddressRange" {
        BeforeAll {
            Mock -CommandName "Get-NBIPAMAddressRange" -ModuleName PowerNetbox -MockWith {
                return @{ 'id' = $id }
            }
        }

        It "Should remove an address range" {
            $Result = Remove-NBIPAMAddressRange -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/ipam/ip.ranges/1/'
        }
    }
    #endregion

    #region FHRPGroup Tests
    Context "Get-NBIPAMFHRPGroup" {
        It "Should request FHRP groups" {
            $Result = Get-NBIPAMFHRPGroup
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/fhrp-groups/'
        }

        It "Should request a FHRP group by ID" {
            $Result = Get-NBIPAMFHRPGroup -Id 3
            $Result.Uri | Should -Match '/api/ipam/fhrp.groups/3/'
        }
    }

    Context "New-NBIPAMFHRPGroup" {
        It "Should create a FHRP group" {
            $Result = New-NBIPAMFHRPGroup -Protocol 'vrrp2' -Group_Id 1
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/fhrp-groups/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.protocol | Should -Be 'vrrp2'
        }
    }

    Context "Set-NBIPAMFHRPGroup" {
        It "Should update a FHRP group" {
            $Result = Set-NBIPAMFHRPGroup -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/ipam/fhrp.groups/1/'
        }
    }

    Context "Remove-NBIPAMFHRPGroup" {
        BeforeAll {
            Mock -CommandName "Get-NBIPAMFHRPGroup" -ModuleName PowerNetbox -MockWith {
                return @{ 'id' = $id }
            }
        }

        It "Should remove a FHRP group" {
            $Result = Remove-NBIPAMFHRPGroup -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/ipam/fhrp.groups/1/'
        }
    }
    #endregion

    #region FHRPGroupAssignment Tests
    Context "Get-NBIPAMFHRPGroupAssignment" {
        It "Should request FHRP group assignments" {
            $Result = Get-NBIPAMFHRPGroupAssignment
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/fhrp-group-assignments/'
        }

        It "Should request an assignment by ID" {
            $Result = Get-NBIPAMFHRPGroupAssignment -Id 2
            $Result.Uri | Should -Match '/api/ipam/fhrp.group.assignments/2/'
        }
    }

    Context "New-NBIPAMFHRPGroupAssignment" {
        It "Should create a FHRP group assignment" {
            $Result = New-NBIPAMFHRPGroupAssignment -Group 1 -Interface_Type 'dcim.interface' -Interface_Id 5 -Priority 100
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/fhrp-group-assignments/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.group | Should -Be 1
        }
    }

    Context "Set-NBIPAMFHRPGroupAssignment" {
        It "Should update a FHRP group assignment" {
            $Result = Set-NBIPAMFHRPGroupAssignment -Id 1 -Priority 200 -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/ipam/fhrp.group.assignments/1/'
        }
    }

    Context "Remove-NBIPAMFHRPGroupAssignment" {
        BeforeAll {
            Mock -CommandName "Get-NBIPAMFHRPGroupAssignment" -ModuleName PowerNetbox -MockWith {
                return @{ 'id' = $id }
            }
        }

        It "Should remove a FHRP group assignment" {
            $Result = Remove-NBIPAMFHRPGroupAssignment -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/ipam/fhrp.group.assignments/1/'
        }
    }
    #endregion

    #region Service Tests
    Context "Get-NBIPAMService" {
        It "Should request services" {
            $Result = Get-NBIPAMService
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/services/'
        }

        It "Should request a service by ID" {
            $Result = Get-NBIPAMService -Id 7
            $Result.Uri | Should -Match '/api/ipam/services/7/'
        }
    }

    Context "New-NBIPAMService" {
        It "Should create a service" {
            $Result = New-NBIPAMService -Name 'HTTP' -Protocol 'tcp' -Ports @(80, 443) -Device 1
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/services/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'HTTP'
        }
    }

    Context "Set-NBIPAMService" {
        It "Should update a service" {
            $Result = Set-NBIPAMService -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/ipam/services/1/'
        }
    }

    Context "Remove-NBIPAMService" {
        BeforeAll {
            Mock -CommandName "Get-NBIPAMService" -ModuleName PowerNetbox -MockWith {
                return @{ 'name' = 'HTTP'; 'id' = $id }
            }
        }

        It "Should remove a service" {
            $Result = Remove-NBIPAMService -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/ipam/services/1/'
        }
    }
    #endregion

    #region ServiceTemplate Tests
    Context "Get-NBIPAMServiceTemplate" {
        It "Should request service templates" {
            $Result = Get-NBIPAMServiceTemplate
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/service-templates/'
        }

        It "Should request a service template by ID" {
            $Result = Get-NBIPAMServiceTemplate -Id 4
            $Result.Uri | Should -Match '/api/ipam/service.templates/4/'
        }
    }

    Context "New-NBIPAMServiceTemplate" {
        It "Should create a service template" {
            $Result = New-NBIPAMServiceTemplate -Name 'SSH' -Protocol 'tcp' -Ports @(22)
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/service-templates/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'SSH'
        }
    }

    Context "Set-NBIPAMServiceTemplate" {
        It "Should update a service template" {
            $Result = Set-NBIPAMServiceTemplate -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/ipam/service.templates/1/'
        }
    }

    Context "Remove-NBIPAMServiceTemplate" {
        BeforeAll {
            Mock -CommandName "Get-NBIPAMServiceTemplate" -ModuleName PowerNetbox -MockWith {
                return @{ 'name' = 'SSH'; 'id' = $id }
            }
        }

        It "Should remove a service template" {
            $Result = Remove-NBIPAMServiceTemplate -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/ipam/service.templates/1/'
        }
    }
    #endregion

    #region VLANTranslationPolicy Tests
    Context "Get-NBIPAMVLANTranslationPolicy" {
        It "Should request VLAN translation policies" {
            $Result = Get-NBIPAMVLANTranslationPolicy
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/vlan-translation-policies/'
        }

        It "Should request a policy by ID" {
            $Result = Get-NBIPAMVLANTranslationPolicy -Id 2
            $Result.Uri | Should -Match '/api/ipam/vlan.translation.policies/2/'
        }
    }

    Context "New-NBIPAMVLANTranslationPolicy" {
        It "Should create a VLAN translation policy" {
            $Result = New-NBIPAMVLANTranslationPolicy -Name 'Policy1'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/vlan-translation-policies/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'Policy1'
        }
    }

    Context "Set-NBIPAMVLANTranslationPolicy" {
        It "Should update a VLAN translation policy" {
            $Result = Set-NBIPAMVLANTranslationPolicy -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/ipam/vlan.translation.policies/1/'
        }
    }

    Context "Remove-NBIPAMVLANTranslationPolicy" {
        BeforeAll {
            Mock -CommandName "Get-NBIPAMVLANTranslationPolicy" -ModuleName PowerNetbox -MockWith {
                return @{ 'name' = 'Policy1'; 'id' = $id }
            }
        }

        It "Should remove a VLAN translation policy" {
            $Result = Remove-NBIPAMVLANTranslationPolicy -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/ipam/vlan.translation.policies/1/'
        }
    }
    #endregion

    #region VLANTranslationRule Tests
    Context "Get-NBIPAMVLANTranslationRule" {
        It "Should request VLAN translation rules" {
            $Result = Get-NBIPAMVLANTranslationRule
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/vlan-translation-rules/'
        }

        It "Should request a rule by ID" {
            $Result = Get-NBIPAMVLANTranslationRule -Id 3
            $Result.Uri | Should -Match '/api/ipam/vlan.translation.rules/3/'
        }
    }

    Context "New-NBIPAMVLANTranslationRule" {
        It "Should create a VLAN translation rule" {
            $Result = New-NBIPAMVLANTranslationRule -Policy 1 -Local_VID 100 -Remote_VID 200
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/ipam/vlan-translation-rules/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.policy | Should -Be 1
        }
    }

    Context "Set-NBIPAMVLANTranslationRule" {
        It "Should update a VLAN translation rule" {
            $Result = Set-NBIPAMVLANTranslationRule -Id 1 -Description 'Updated' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.Uri | Should -Match '/api/ipam/vlan.translation.rules/1/'
        }
    }

    Context "Remove-NBIPAMVLANTranslationRule" {
        BeforeAll {
            Mock -CommandName "Get-NBIPAMVLANTranslationRule" -ModuleName PowerNetbox -MockWith {
                return @{ 'id' = $id }
            }
        }

        It "Should remove a VLAN translation rule" {
            $Result = Remove-NBIPAMVLANTranslationRule -Id 1 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.Uri | Should -Match '/api/ipam/vlan.translation.rules/1/'
        }
    }
    #endregion

    #region Parameter Validation Tests
    Context "Parameter Validation" {
        It "Should reject invalid Status for Get-NBIPAMAddress" {
            { Get-NBIPAMAddress -Status 'invalid' } | Should -Throw
        }

        It "Should reject invalid Family for Get-NBIPAMAddress" {
            { Get-NBIPAMAddress -Family 5 } | Should -Throw
        }

        It "Should accept valid Family value 4" {
            { Get-NBIPAMAddress -Family 4 } | Should -Not -Throw
        }

        It "Should reject VID below minimum (0) for New-NBIPAMVLAN" {
            { New-NBIPAMVLAN -Name 'test' -VID 0 -Confirm:$false } | Should -Throw
        }

        It "Should reject VID above maximum (4095) for New-NBIPAMVLAN" {
            { New-NBIPAMVLAN -Name 'test' -VID 4095 -Confirm:$false } | Should -Throw
        }

        It "Should accept valid VID boundary (1) for New-NBIPAMVLAN" {
            { New-NBIPAMVLAN -Name 'test' -VID 1 -Confirm:$false } | Should -Not -Throw
        }

        It "Should accept valid VID boundary (4094) for New-NBIPAMVLAN" {
            { New-NBIPAMVLAN -Name 'test' -VID 4094 -Confirm:$false } | Should -Not -Throw
        }

        It "Should reject invalid Status for Get-NBIPAMVLAN" {
            { Get-NBIPAMVLAN -Status 'invalid' } | Should -Throw
        }

        It "Should require mandatory Address for New-NBIPAMAddress" {
            { New-NBIPAMAddress -Status 'active' -Confirm:$false } | Should -Throw
        }

        It "Should reject invalid Assigned_Object_Type for New-NBIPAMAddress" {
            { New-NBIPAMAddress -Address '10.0.0.1/24' -Assigned_Object_Type 'invalid.type' -Confirm:$false } | Should -Throw
        }

        It "Should reject PageSize above maximum (1001)" {
            { Get-NBIPAMAddress -PageSize 1001 } | Should -Throw
        }
    }
    #endregion

    #region WhatIf Tests
    Context "WhatIf Support" {
        $whatIfTestCases = @(
            @{ Command = 'New-NBIPAMAddress'; Parameters = @{ Address = 'whatif-test' } }
            @{ Command = 'New-NBIPAMAddressRange'; Parameters = @{ Start_Address = 'whatif-test'; End_Address = 'whatif-test' } }
            @{ Command = 'New-NBIPAMAggregate'; Parameters = @{ Prefix = 'whatif-test'; RIR = 1 } }
            @{ Command = 'New-NBIPAMASN'; Parameters = @{ ASN = 1 } }
            @{ Command = 'New-NBIPAMASNRange'; Parameters = @{ Name = 'whatif-test'; Slug = 'whatif-test'; RIR = 1; Start = 1; End = 1 } }
            @{ Command = 'New-NBIPAMFHRPGroup'; Parameters = @{ Protocol = 'other'; Group_Id = 1 } }
            @{ Command = 'New-NBIPAMFHRPGroupAssignment'; Parameters = @{ Group = 1; Interface_Type = 'whatif-test'; Interface_Id = 1 } }
            @{ Command = 'New-NBIPAMPrefix'; Parameters = @{ Prefix = 'whatif-test' } }
            @{ Command = 'New-NBIPAMRIR'; Parameters = @{ Name = 'whatif-test' } }
            @{ Command = 'New-NBIPAMRole'; Parameters = @{ Name = 'whatif-test' } }
            @{ Command = 'New-NBIPAMRouteTarget'; Parameters = @{ Name = 'whatif-test' } }
            @{ Command = 'New-NBIPAMService'; Parameters = @{ Name = 'whatif-test'; Ports = 1 } }
            @{ Command = 'New-NBIPAMServiceTemplate'; Parameters = @{ Name = 'whatif-test'; Ports = 1 } }
            @{ Command = 'New-NBIPAMVLAN'; Parameters = @{ VID = 1; Name = 'whatif-test' } }
            @{ Command = 'New-NBIPAMVLANGroup'; Parameters = @{ Name = 'whatif-test' } }
            @{ Command = 'New-NBIPAMVLANTranslationPolicy'; Parameters = @{ Name = 'whatif-test' } }
            @{ Command = 'New-NBIPAMVLANTranslationRule'; Parameters = @{ Policy = 1; Local_Vid = 1; Remote_Vid = 1 } }
            @{ Command = 'New-NBIPAMVRF'; Parameters = @{ Name = 'whatif-test' } }
            @{ Command = 'Set-NBIPAMAddress'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBIPAMAddressRange'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBIPAMAggregate'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBIPAMASN'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBIPAMASNRange'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBIPAMFHRPGroup'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBIPAMFHRPGroupAssignment'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBIPAMPrefix'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBIPAMRIR'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBIPAMRole'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBIPAMRouteTarget'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBIPAMService'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBIPAMServiceTemplate'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBIPAMVLAN'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBIPAMVLANGroup'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBIPAMVLANTranslationPolicy'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBIPAMVLANTranslationRule'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBIPAMVRF'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBIPAMAddress'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBIPAMAddressRange'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBIPAMAggregate'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBIPAMASN'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBIPAMASNRange'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBIPAMFHRPGroup'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBIPAMFHRPGroupAssignment'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBIPAMPrefix'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBIPAMRIR'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBIPAMRole'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBIPAMRouteTarget'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBIPAMService'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBIPAMServiceTemplate'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBIPAMVLAN'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBIPAMVLANGroup'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBIPAMVLANTranslationPolicy'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBIPAMVLANTranslationRule'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBIPAMVRF'; Parameters = @{ Id = 1 } }
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
            @{ Command = 'Get-NBIPAMAddress' }
            @{ Command = 'Get-NBIPAMAddressRange' }
            @{ Command = 'Get-NBIPAMAggregate' }
            @{ Command = 'Get-NBIPAMASN' }
            @{ Command = 'Get-NBIPAMASNRange' }
            @{ Command = 'Get-NBIPAMFHRPGroup' }
            @{ Command = 'Get-NBIPAMFHRPGroupAssignment' }
            @{ Command = 'Get-NBIPAMPrefix' }
            @{ Command = 'Get-NBIPAMRIR' }
            @{ Command = 'Get-NBIPAMRole' }
            @{ Command = 'Get-NBIPAMRouteTarget' }
            @{ Command = 'Get-NBIPAMService' }
            @{ Command = 'Get-NBIPAMServiceTemplate' }
            @{ Command = 'Get-NBIPAMVLAN' }
            @{ Command = 'Get-NBIPAMVLANGroup' }
            @{ Command = 'Get-NBIPAMVLANTranslationPolicy' }
            @{ Command = 'Get-NBIPAMVLANTranslationRule' }
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
            @{ Command = 'Get-NBIPAMAddress' }
            @{ Command = 'Get-NBIPAMAddressRange' }
            @{ Command = 'Get-NBIPAMAggregate' }
            @{ Command = 'Get-NBIPAMASN' }
            @{ Command = 'Get-NBIPAMASNRange' }
            @{ Command = 'Get-NBIPAMFHRPGroup' }
            @{ Command = 'Get-NBIPAMFHRPGroupAssignment' }
            @{ Command = 'Get-NBIPAMPrefix' }
            @{ Command = 'Get-NBIPAMRIR' }
            @{ Command = 'Get-NBIPAMRole' }
            @{ Command = 'Get-NBIPAMRouteTarget' }
            @{ Command = 'Get-NBIPAMService' }
            @{ Command = 'Get-NBIPAMServiceTemplate' }
            @{ Command = 'Get-NBIPAMVLAN' }
            @{ Command = 'Get-NBIPAMVLANGroup' }
            @{ Command = 'Get-NBIPAMVLANTranslationPolicy' }
            @{ Command = 'Get-NBIPAMVLANTranslationRule' }
            @{ Command = 'Get-NBIPAMVRF' }
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
            @{ Command = 'Get-NBIPAMAddress' }
            @{ Command = 'Get-NBIPAMVLAN' }
        )

        It 'Should accept pipeline input by property name for <Command>' -TestCases $pipelineTestCases {
            param($Command)
            $Result = [pscustomobject]@{ 'Id' = 10 } | & $Command
            $Result.Uri | Should -Match '/10/'
        }
    }
    #endregion
}
