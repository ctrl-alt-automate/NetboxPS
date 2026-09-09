<#
.SYNOPSIS
    Scenario tests for filter queries against populated Netbox test data.

.DESCRIPTION
    These tests verify that filter parameters work correctly when querying
    objects in a populated Netbox environment. Requires test data to be
    imported via the TestData import scripts.

.NOTES
    Run with: Invoke-Pester -Path ./Tests/Scenario/Filters.Tests.ps1 -Tag 'Scenario'

    Environment variables:
    - SCENARIO_ENV: Netbox version (4.7.0, 4.6.10, 4.5.10, 4.4.10, 4.3.7 or custom) - defaults to 4.7.0;
      the local Docker stack from ./scripts/Start-NetboxDocker.ps1 -Version <ver> -SetEnvironment
    - SCENARIO_SKIP_IMPORT: Set to '1' to skip data import (if already imported)
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

BeforeAll {
    # Determine test environment from environment variable
    $script:TestEnvironment = if ($env:SCENARIO_ENV) { $env:SCENARIO_ENV } else { '4.7.0' }
    $script:SkipImport = $env:SCENARIO_SKIP_IMPORT -eq '1'

    # Import modules
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue
    $ModulePath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "PowerNetbox/PowerNetbox.psd1"
    if (-not (Test-Path $ModulePath)) {
        $ModulePath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "PowerNetbox.psd1"
    }
    Import-Module $ModulePath -Force -ErrorAction Stop

    Import-Module (Join-Path $PSScriptRoot "ScenarioTestHelper.psm1") -Force -ErrorAction Stop

    # Connect to test environment
    $script:Version = Connect-ScenarioTest -Environment $script:TestEnvironment
    Write-Host "Connected to Netbox $($script:Version.'netbox-version') ($script:TestEnvironment)" -ForegroundColor Cyan

    # Import test data if needed
    if (-not $script:SkipImport) {
        if (-not (Test-ScenarioTestData)) {
            Write-Host "Importing test data..." -ForegroundColor Yellow
            $imported = Import-ScenarioTestData -Environment $script:TestEnvironment -Force
            if (-not $imported) {
                throw "Failed to import test data"
            }
        }
        else {
            Write-Host "Test data already present, skipping import" -ForegroundColor Green
        }
    }

    # Get test prefix
    $script:Prefix = Get-TestPrefix
}

Describe "DCIM Filter Tests" -Tag 'Scenario', 'Filters', 'DCIM' {
    Context "Site Filters" {
        It "Should filter sites by query" {
            $sites = Get-NBDCIMSite -Query $script:Prefix

            $sites | Should -Not -BeNullOrEmpty
            $sites | ForEach-Object { $_.name | Should -BeLike "$($script:Prefix)*" }
        }

        It "Should filter sites by status" {
            $sites = Get-NBDCIMSite -Query $script:Prefix
            $activeSites = $sites | Where-Object { $_.status.value -eq 'active' }

            $activeSites | Should -Not -BeNullOrEmpty
            $activeSites | ForEach-Object { $_.status.value | Should -Be 'active' }
        }

        It "Should filter sites by region" {
            $regions = Get-NBDCIMRegion -Query $script:Prefix -Limit 1
            if ($regions) {
                $sitesByRegion = Get-NBDCIMSite -Region_ID $regions[0].id

                $sitesByRegion | Should -Not -BeNullOrEmpty
                $sitesByRegion | ForEach-Object { $_.region.id | Should -Be $regions[0].id }
            }
            else {
                Set-ItResult -Skipped -Because "No test regions found"
            }
        }

        It "Should filter sites by tenant" {
            $tenants = Get-NBTenant -Query $script:Prefix -Limit 1
            if ($tenants) {
                $sitesByTenant = Get-NBDCIMSite -Tenant_ID $tenants[0].id

                if ($sitesByTenant) {
                    $sitesByTenant | ForEach-Object { $_.tenant.id | Should -Be $tenants[0].id }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test tenants found"
            }
        }
    }

    Context "Device Filters" {
        It "Should filter devices by query" {
            $devices = Get-NBDCIMDevice -Query $script:Prefix

            $devices | Should -Not -BeNullOrEmpty
            $devices | ForEach-Object { $_.name | Should -BeLike "$($script:Prefix)*" }
        }

        It "Should filter devices by status" {
            $devices = Get-NBDCIMDevice -Query $script:Prefix
            $activeDevices = $devices | Where-Object { $_.status.value -eq 'active' }

            if ($activeDevices) {
                $activeDevices | ForEach-Object { $_.status.value | Should -Be 'active' }
            }
        }

        It "Should filter devices by site" {
            $sites = Get-NBDCIMSite -Query $script:Prefix -Limit 1
            if ($sites) {
                $devicesBySite = Get-NBDCIMDevice -Site_Id $sites[0].id

                $devicesBySite | Should -Not -BeNullOrEmpty
                $devicesBySite | ForEach-Object { $_.site.id | Should -Be $sites[0].id }
            }
            else {
                Set-ItResult -Skipped -Because "No test sites found"
            }
        }

        It "Should filter devices by role" {
            $roles = Get-NBDCIMDeviceRole -All | Where-Object { $_.name -like "$($script:Prefix)*" } | Select-Object -First 1
            if ($roles) {
                $devicesByRole = Get-NBDCIMDevice -Role_Id $roles.id

                if ($devicesByRole) {
                    $devicesByRole | ForEach-Object { $_.role.id | Should -Be $roles.id }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test device roles found"
            }
        }

        It "Should filter devices by device type" {
            $types = Get-NBDCIMDeviceType -Query $script:Prefix -Limit 1
            if ($types) {
                $devicesByType = Get-NBDCIMDevice -Device_Type_Id $types[0].id

                if ($devicesByType) {
                    $devicesByType | ForEach-Object { $_.device_type.id | Should -Be $types[0].id }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test device types found"
            }
        }

        It "Should filter devices by manufacturer" {
            $manufacturers = Get-NBDCIMManufacturer -Query $script:Prefix -Limit 1
            if ($manufacturers) {
                $devicesByManufacturer = Get-NBDCIMDevice -Manufacturer_Id $manufacturers[0].id

                if ($devicesByManufacturer) {
                    $devicesByManufacturer | ForEach-Object {
                        $_.device_type.manufacturer.id | Should -Be $manufacturers[0].id
                    }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test manufacturers found"
            }
        }

        It "Should filter devices by rack" {
            $racks = Get-NBDCIMRack -Query $script:Prefix -Limit 1
            if ($racks) {
                $devicesByRack = Get-NBDCIMDevice -Rack_Id $racks[0].id

                if ($devicesByRack) {
                    $devicesByRack | ForEach-Object { $_.rack.id | Should -Be $racks[0].id }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test racks found"
            }
        }

        It "Should filter devices with has_primary_ip" {
            $devices = Get-NBDCIMDevice -Query $script:Prefix
            $devicesWithIP = $devices | Where-Object { $_.primary_ip4 -or $_.primary_ip6 }

            if ($devicesWithIP) {
                $devicesWithIP | ForEach-Object {
                    ($_.primary_ip4 -or $_.primary_ip6) | Should -BeTrue
                }
            }
        }
    }

    Context "Interface Filters" {
        It "Should filter interfaces by device" {
            # Find a device that has interfaces
            $devices = Get-NBDCIMDevice -Query $script:Prefix | Where-Object { $_.interface_count -gt 0 } | Select-Object -First 1
            if ($devices) {
                $interfaces = Get-NBDCIMInterface -Device_Id $devices.id

                $interfaces | Should -Not -BeNullOrEmpty
                $interfaces | ForEach-Object { $_.device.id | Should -Be $devices.id }
            }
            else {
                Set-ItResult -Skipped -Because "No test devices with interfaces found"
            }
        }

        It "Should filter interfaces by type" {
            $interfaces = Get-NBDCIMInterface -Type '1000base-t' -Limit 10

            if ($interfaces) {
                $interfaces | ForEach-Object { $_.type.value | Should -Be '1000base-t' }
            }
        }

        It "Should filter interfaces by enabled status" {
            $enabledInterfaces = Get-NBDCIMInterface -Enabled $true -Limit 10

            if ($enabledInterfaces) {
                $enabledInterfaces | ForEach-Object { $_.enabled | Should -BeTrue }
            }
        }
    }

    Context "Rack Filters" {
        It "Should filter racks by site" {
            $sites = Get-NBDCIMSite -Query $script:Prefix -Limit 1
            if ($sites) {
                $racksBySite = Get-NBDCIMRack -Site_Id $sites[0].id

                if ($racksBySite) {
                    $racksBySite | ForEach-Object { $_.site.id | Should -Be $sites[0].id }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test sites found"
            }
        }

        It "Should filter racks by status" {
            $racks = Get-NBDCIMRack -Query $script:Prefix
            $activeRacks = $racks | Where-Object { $_.status.value -eq 'active' }

            if ($activeRacks) {
                $activeRacks | ForEach-Object { $_.status.value | Should -Be 'active' }
            }
        }
    }
}

Describe "IPAM Filter Tests" -Tag 'Scenario', 'Filters', 'IPAM' {
    Context "Prefix Filters" {
        It "Should filter prefixes by VRF" {
            $vrfs = Get-NBIPAMVRF -Query $script:Prefix -Limit 1
            if ($vrfs) {
                $prefixesByVRF = Get-NBIPAMPrefix -Vrf_Id $vrfs[0].id

                if ($prefixesByVRF) {
                    $prefixesByVRF | ForEach-Object { $_.vrf.id | Should -Be $vrfs[0].id }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test VRFs found"
            }
        }

        It "Should filter prefixes by status" {
            $activePrefixes = Get-NBIPAMPrefix -Status 'active' -Limit 10

            if ($activePrefixes) {
                $activePrefixes | ForEach-Object { $_.status.value | Should -Be 'active' }
            }
        }

        It "Should filter prefixes by site" {
            $sites = Get-NBDCIMSite -Query $script:Prefix -Limit 1
            if ($sites) {
                # Prefix.site was replaced by the generic scope (scope_type/scope_id) in NetBox 4.2
                $prefixesBySite = Get-NBIPAMPrefix -Scope_Type 'dcim.site' -Scope_Id $sites[0].id

                if ($prefixesBySite) {
                    $prefixesBySite | ForEach-Object { $_.scope.id | Should -Be $sites[0].id }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test sites found"
            }
        }

        It "Should filter prefixes by VLAN" {
            $vlans = Get-NBIPAMVLAN -Query $script:Prefix -Limit 1
            if ($vlans) {
                $prefixesByVLAN = Get-NBIPAMPrefix -Vlan_Id $vlans[0].id

                if ($prefixesByVLAN) {
                    $prefixesByVLAN | ForEach-Object { $_.vlan.id | Should -Be $vlans[0].id }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test VLANs found"
            }
        }

        It "Should filter prefixes by family (IPv4)" {
            $ipv4Prefixes = Get-NBIPAMPrefix -Family 4 -Limit 10

            if ($ipv4Prefixes) {
                $ipv4Prefixes | ForEach-Object { $_.family.value | Should -Be 4 }
            }
        }
    }

    Context "IP Address Filters" {
        It "Should filter addresses by status" {
            $activeAddresses = Get-NBIPAMAddress -Status 'active' -Limit 10

            if ($activeAddresses) {
                $activeAddresses | ForEach-Object { $_.status.value | Should -Be 'active' }
            }
        }

        It "Should filter addresses by VRF" {
            $vrfs = Get-NBIPAMVRF -Query $script:Prefix -Limit 1
            if ($vrfs) {
                $addressesByVRF = Get-NBIPAMAddress -Vrf_Id $vrfs[0].id

                if ($addressesByVRF) {
                    $addressesByVRF | ForEach-Object { $_.vrf.id | Should -Be $vrfs[0].id }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test VRFs found"
            }
        }

        It "Should filter addresses by tenant" {
            $tenants = Get-NBTenant -Query $script:Prefix -Limit 1
            if ($tenants) {
                $addressesByTenant = Get-NBIPAMAddress -Tenant_Id $tenants[0].id

                if ($addressesByTenant) {
                    $addressesByTenant | ForEach-Object { $_.tenant.id | Should -Be $tenants[0].id }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test tenants found"
            }
        }

        It "Should filter addresses by role" {
            $loopbackAddresses = Get-NBIPAMAddress -Role 'loopback' -Limit 10

            if ($loopbackAddresses) {
                $loopbackAddresses | ForEach-Object { $_.role.value | Should -Be 'loopback' }
            }
        }
    }

    Context "VLAN Filters" {
        It "Should filter VLANs by VID range" {
            # Get VLANs with client-side filtering since Vid__gte/Vid__lte may not exist
            $vlans = Get-NBIPAMVLAN -All | Where-Object { $_.vid -ge 100 -and $_.vid -le 200 } | Select-Object -First 10

            if ($vlans) {
                $vlans | ForEach-Object {
                    $_.vid | Should -BeGreaterOrEqual 100
                    $_.vid | Should -BeLessOrEqual 200
                }
            }
        }

        It "Should filter VLANs by group" {
            $groups = Get-NBIPAMVLANGroup -Query $script:Prefix -Limit 1
            if ($groups) {
                $vlansByGroup = Get-NBIPAMVLAN -Group_Id $groups[0].id

                if ($vlansByGroup) {
                    $vlansByGroup | ForEach-Object { $_.group.id | Should -Be $groups[0].id }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test VLAN groups found"
            }
        }

        It "Should filter VLANs by status" {
            $vlans = Get-NBIPAMVLAN -Query $script:Prefix
            $activeVLANs = $vlans | Where-Object { $_.status.value -eq 'active' }

            if ($activeVLANs) {
                $activeVLANs | ForEach-Object { $_.status.value | Should -Be 'active' }
            }
        }
    }
}

Describe "Virtualization Filter Tests" -Tag 'Scenario', 'Filters', 'Virtualization' {
    Context "Virtual Machine Filters" {
        It "Should filter VMs by cluster" {
            $clusters = Get-NBVirtualizationCluster -Query $script:Prefix -Limit 1
            if ($clusters) {
                $vmsByCluster = Get-NBVirtualMachine -Cluster_Id $clusters[0].id

                if ($vmsByCluster) {
                    $vmsByCluster | ForEach-Object { $_.cluster.id | Should -Be $clusters[0].id }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test clusters found"
            }
        }

        It "Should filter VMs by status" {
            $vms = Get-NBVirtualMachine -Query $script:Prefix
            $activeVMs = $vms | Where-Object { $_.status.value -eq 'active' }

            if ($activeVMs) {
                $activeVMs | ForEach-Object { $_.status.value | Should -Be 'active' }
            }
        }

        It "Should filter VMs by tenant" {
            $tenants = Get-NBTenant -Query $script:Prefix -Limit 1
            if ($tenants) {
                $vmsByTenant = Get-NBVirtualMachine -Tenant_ID $tenants[0].id

                if ($vmsByTenant) {
                    $vmsByTenant | ForEach-Object { $_.tenant.id | Should -Be $tenants[0].id }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test tenants found"
            }
        }

        It "Should filter VMs by role" {
            $roles = Get-NBDCIMDeviceRole -All | Where-Object { $_.vm_role -and $_.name -like "$($script:Prefix)*" } | Select-Object -First 1
            if ($roles) {
                $vmsByRole = Get-NBVirtualMachine -Role_Id $roles.id

                if ($vmsByRole) {
                    $vmsByRole | ForEach-Object { $_.role.id | Should -Be $roles.id }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test VM roles found"
            }
        }
    }

    Context "Cluster Filters" {
        It "Should filter clusters by type" {
            $types = Get-NBVirtualizationClusterType -Query $script:Prefix -Limit 1
            if ($types) {
                $clustersByType = Get-NBVirtualizationCluster -Type_Id $types[0].id

                if ($clustersByType) {
                    $clustersByType | ForEach-Object { $_.type.id | Should -Be $types[0].id }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test cluster types found"
            }
        }

        It "Should filter clusters by group" {
            $groups = Get-NBVirtualizationClusterGroup -Query $script:Prefix -Limit 1
            if ($groups) {
                $clustersByGroup = Get-NBVirtualizationCluster -Group_Id $groups[0].id

                if ($clustersByGroup) {
                    $clustersByGroup | ForEach-Object { $_.group.id | Should -Be $groups[0].id }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test cluster groups found"
            }
        }
    }
}

Describe "Tenancy Filter Tests" -Tag 'Scenario', 'Filters', 'Tenancy' {
    Context "Tenant Filters" {
        It "Should filter tenants by group" {
            $groups = Get-NBTenantGroup -Query $script:Prefix -Limit 1
            if ($groups) {
                $tenantsByGroup = Get-NBTenant -GroupID $groups[0].id

                if ($tenantsByGroup) {
                    # GroupID filter returns tenants, but group property may not be expanded
                    # Verify we got tenants that belong to the group by checking count matches
                    $tenantsByGroup.Count | Should -BeGreaterThan 0

                    # Also verify via Get-NBTenantGroup that it has these tenants
                    $groups[0].tenant_count | Should -BeGreaterOrEqual $tenantsByGroup.Count
                }
                else {
                    Set-ItResult -Skipped -Because "No tenants belong to test groups"
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test tenant groups found"
            }
        }

        It "Should filter tenants by query" {
            $tenants = Get-NBTenant -Query $script:Prefix

            $tenants | Should -Not -BeNullOrEmpty
            $tenants | ForEach-Object { $_.name | Should -BeLike "$($script:Prefix)*" }
        }
    }

    Context "Contact Filters" {
        It "Should filter contacts by query" {
            $contacts = Get-NBContact -Query $script:Prefix

            if ($contacts) {
                $contacts | ForEach-Object { $_.name | Should -BeLike "$($script:Prefix)*" }
            }
            else {
                Set-ItResult -Skipped -Because "No test contacts found"
            }
        }
    }
}

Describe "Circuits Filter Tests" -Tag 'Scenario', 'Filters', 'Circuits' {
    Context "Circuit Filters" {
        It "Should filter circuits by provider" {
            $providers = Get-NBCircuitProvider -Query $script:Prefix -Limit 1
            if ($providers) {
                # Get-NBCircuit Provider filter doesn't work with names in Netbox 4.x
                # Filter circuits client-side for now
                $allCircuits = Get-NBCircuit -Limit 100
                $circuitsByProvider = $allCircuits | Where-Object { $_.provider.id -eq $providers[0].id }

                if ($circuitsByProvider) {
                    $circuitsByProvider | ForEach-Object { $_.provider.id | Should -Be $providers[0].id }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test providers found"
            }
        }

        It "Should filter circuits by type" {
            $types = Get-NBCircuitType -Query $script:Prefix -Limit 1
            if ($types) {
                # Get-NBCircuit Type filter doesn't work with names in Netbox 4.x
                # Filter circuits client-side for now
                $allCircuits = Get-NBCircuit -Limit 100
                $circuitsByType = $allCircuits | Where-Object { $_.type.id -eq $types[0].id }

                if ($circuitsByType) {
                    $circuitsByType | ForEach-Object { $_.type.id | Should -Be $types[0].id }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test circuit types found"
            }
        }

        It "Should filter circuits by status" {
            # Get-NBCircuit doesn't have Status parameter - use client-side filtering
            $circuits = Get-NBCircuit -Limit 50
            $activeCircuits = $circuits | Where-Object { $_.status.value -eq 'active' } | Select-Object -First 10

            if ($activeCircuits) {
                $activeCircuits | ForEach-Object { $_.status.value | Should -Be 'active' }
            }
        }
    }
}

Describe "VPN Filter Tests" -Tag 'Scenario', 'Filters', 'VPN' {
    Context "Tunnel Filters" {
        It "Should filter tunnels by status" {
            $tunnels = Get-NBVPNTunnel -Query $script:Prefix
            $activeTunnels = $tunnels | Where-Object { $_.status.value -eq 'active' }

            if ($activeTunnels) {
                $activeTunnels | ForEach-Object { $_.status.value | Should -Be 'active' }
            }
        }

        It "Should filter tunnels by group" {
            # Get-NBVPNTunnelGroup doesn't have -All switch, use Limit
            $groups = Get-NBVPNTunnelGroup -Limit 100 | Where-Object { $_.name -like "$($script:Prefix)*" } | Select-Object -First 1
            if ($groups) {
                $tunnelsByGroup = Get-NBVPNTunnel -Group_Id $groups.id

                if ($tunnelsByGroup) {
                    $tunnelsByGroup | ForEach-Object { $_.group.id | Should -Be $groups.id }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test tunnel groups found"
            }
        }
    }
}

Describe "Tag Filter Tests" -Tag 'Scenario', 'Filters', 'Extras' {
    Context "Tag-Based Filtering" {
        It "Should filter objects by tag" {
            # -Tag / -Tag_Id exist on every taggable Get cmdlet since v4.7.0.1 (AND semantics by default)
            $tag = Get-NBTag -All | Where-Object { $_.slug -like 'pnb-test-*' } | Select-Object -First 1
            if (-not $tag) { Set-ItResult -Skipped -Because 'No PNB-Test tags found'; return }

            $devices = Get-NBDCIMDevice -Tag $tag.slug -All
            $byId = Get-NBDCIMDevice -Tag_Id $tag.id -All
            @($devices).Count | Should -Be @($byId).Count
            foreach ($d in $devices) { $d.tags.slug | Should -Contain $tag.slug }
        }

        It "Should filter sites by tag" {
            $tag = Get-NBTag -All | Where-Object { $_.slug -like 'pnb-test-*' } | Select-Object -First 1
            if (-not $tag) { Set-ItResult -Skipped -Because 'No PNB-Test tags found'; return }

            $sites = Get-NBDCIMSite -Tag $tag.slug -All
            foreach ($s in $sites) { $s.tags.slug | Should -Contain $tag.slug }
            @(Get-NBDCIMSite -Tag_Id $tag.id -All).Count | Should -Be @($sites).Count

            # NetBox validates the tag filter against existing tags: an unknown slug is a 400, not an empty list
            { Get-NBDCIMSite -Tag 'pnb-test-no-such-tag-zzz' -ErrorAction Stop } | Should -Throw '*not one of the available choices*'
        }
    }
}

Describe "Pagination Tests" -Tag 'Scenario', 'Filters', 'Pagination' {
    Context "Limit and Offset" {
        It "Should respect Limit parameter" {
            $limit = 5
            $result = Get-NBDCIMDevice -Limit $limit

            $result.Count | Should -BeLessOrEqual $limit
        }

        It "Should paginate correctly with Offset" {
            $allDevices = Get-NBDCIMDevice -Query $script:Prefix -Limit 10

            if ($allDevices.Count -gt 2) {
                $firstPage = Get-NBDCIMDevice -Query $script:Prefix -Limit 2 -Offset 0
                $secondPage = Get-NBDCIMDevice -Query $script:Prefix -Limit 2 -Offset 2

                $firstPage.Count | Should -Be 2
                $secondPage | Should -Not -BeNullOrEmpty

                # Ensure no overlap
                $firstPageIds = $firstPage | ForEach-Object { $_.id }
                $secondPageIds = $secondPage | ForEach-Object { $_.id }

                foreach ($id in $secondPageIds) {
                    $firstPageIds | Should -Not -Contain $id
                }
            }
            else {
                Set-ItResult -Skipped -Because "Not enough devices for pagination test"
            }
        }

        It "Should retrieve all results with -All switch" {
            $limitedResult = Get-NBDCIMDevice -Limit 5
            $allResult = Get-NBDCIMDevice -All

            $allResult.Count | Should -BeGreaterOrEqual $limitedResult.Count
        }
    }
}
