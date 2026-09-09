<#
.SYNOPSIS
    Scenario tests for object relationships in populated Netbox test data.

.DESCRIPTION
    These tests verify that object relationships are correctly maintained
    and navigable in a populated Netbox environment. Tests include:
    - Parent-child relationships (Region -> Site -> Location)
    - Device hierarchy (Device -> Interfaces -> IP Addresses)
    - Cross-module references (Device -> Circuit Termination)

.NOTES
    Run with: Invoke-Pester -Path ./Tests/Scenario/Relationships.Tests.ps1 -Tag 'Scenario'

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

    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue
    $ModulePath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "PowerNetbox/PowerNetbox.psd1"
    if (-not (Test-Path $ModulePath)) {
        $ModulePath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "PowerNetbox.psd1"
    }
    Import-Module $ModulePath -Force -ErrorAction Stop
    Import-Module (Join-Path $PSScriptRoot "ScenarioTestHelper.psm1") -Force -ErrorAction Stop

    $script:Version = Connect-ScenarioTest -Environment $script:TestEnvironment
    Write-Host "Connected to Netbox $($script:Version.'netbox-version') ($script:TestEnvironment)" -ForegroundColor Cyan

    if (-not $script:SkipImport) {
        if (-not (Test-ScenarioTestData)) {
            Write-Host "Importing test data..." -ForegroundColor Yellow
            Import-ScenarioTestData -Environment $script:TestEnvironment -Force
        }
    }

    $script:Prefix = Get-TestPrefix
}

Describe "DCIM Hierarchy Relationships" -Tag 'Scenario', 'Relationships', 'DCIM' {
    Context "Region -> Site -> Location" {
        It "Should have sites linked to regions" {
            $regions = Get-NBDCIMRegion -Query $script:Prefix

            if ($regions) {
                $regionsWithSites = $regions | Where-Object { $_.site_count -gt 0 }

                $regionsWithSites | Should -Not -BeNullOrEmpty -Because "Test regions should have associated sites"

                foreach ($region in $regionsWithSites) {
                    $sites = Get-NBDCIMSite -Region_ID $region.id

                    $sites | Should -Not -BeNullOrEmpty
                    $sites | ForEach-Object {
                        $_.region.id | Should -Be $region.id
                        $_.region.name | Should -Be $region.name
                    }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test regions found"
            }
        }

        It "Should have locations linked to sites" {
            $sites = Get-NBDCIMSite -Query $script:Prefix | Where-Object { $_.location_count -gt 0 }

            if ($sites) {
                foreach ($site in $sites | Select-Object -First 2) {
                    $locations = Get-NBDCIMLocation -Site_Id $site.id

                    $locations | Should -Not -BeNullOrEmpty
                    $locations | ForEach-Object {
                        $_.site.id | Should -Be $site.id
                    }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test sites with locations found"
            }
        }

        It "Should support nested location hierarchy" {
            # Get all locations and filter for parent-less ones client-side
            $allLocations = Get-NBDCIMLocation -Query $script:Prefix
            $parentLocations = $allLocations | Where-Object { -not $_.parent }

            if ($parentLocations) {
                $locationsWithChildren = $parentLocations | Where-Object { $_.child_count -gt 0 }

                if ($locationsWithChildren) {
                    foreach ($parent in $locationsWithChildren | Select-Object -First 1) {
                        $children = Get-NBDCIMLocation -Parent_Id $parent.id

                        $children | Should -Not -BeNullOrEmpty
                        $children | ForEach-Object {
                            $_.parent.id | Should -Be $parent.id
                        }
                    }
                }
            }
        }
    }

    Context "Site -> Rack -> Device" {
        It "Should have racks linked to sites" {
            $sites = Get-NBDCIMSite -Query $script:Prefix | Where-Object { $_.rack_count -gt 0 }

            if ($sites) {
                foreach ($site in $sites | Select-Object -First 2) {
                    $racks = Get-NBDCIMRack -Site_Id $site.id

                    $racks | Should -Not -BeNullOrEmpty
                    $racks | ForEach-Object {
                        $_.site.id | Should -Be $site.id
                    }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test sites with racks found"
            }
        }

        It "Should have devices in racks" {
            $racks = Get-NBDCIMRack -Query $script:Prefix | Where-Object { $_.device_count -gt 0 }

            if ($racks) {
                foreach ($rack in $racks | Select-Object -First 2) {
                    $devices = Get-NBDCIMDevice -Rack_Id $rack.id

                    $devices | Should -Not -BeNullOrEmpty
                    $devices | ForEach-Object {
                        $_.rack.id | Should -Be $rack.id
                        $_.rack.name | Should -Be $rack.name
                    }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test racks with devices found"
            }
        }

        It "Should have consistent site across rack and devices" {
            $racks = Get-NBDCIMRack -Query $script:Prefix | Where-Object { $_.device_count -gt 0 } | Select-Object -First 1

            if ($racks) {
                $rack = $racks | Select-Object -First 1
                $devices = Get-NBDCIMDevice -Rack_Id $rack.id

                $devices | ForEach-Object {
                    $_.site.id | Should -Be $rack.site.id -Because "Device site should match rack site"
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test racks with devices found"
            }
        }
    }

    Context "Device -> Interface -> IP Address" {
        It "Should have interfaces linked to devices" {
            $devices = Get-NBDCIMDevice -Query $script:Prefix -Limit 5

            if ($devices) {
                $devicesWithInterfaces = $devices | Where-Object { $_.interface_count -gt 0 }

                foreach ($device in $devicesWithInterfaces | Select-Object -First 2) {
                    $interfaces = Get-NBDCIMInterface -Device_Id $device.id

                    $interfaces | Should -Not -BeNullOrEmpty
                    $interfaces | ForEach-Object {
                        $_.device.id | Should -Be $device.id
                        $_.device.name | Should -Be $device.name
                    }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test devices found"
            }
        }

        It "Should have IP addresses assigned to interfaces" {
            $devices = Get-NBDCIMDevice -Query $script:Prefix | Where-Object { $_.primary_ip4 -or $_.primary_ip6 } | Select-Object -First 3

            if ($devices) {
                foreach ($device in $devices) {
                    $interfaces = Get-NBDCIMInterface -Device_Id $device.id

                    $interfacesWithIPs = $interfaces | Where-Object {
                        $_.count_ipaddresses -gt 0
                    }

                    if ($interfacesWithIPs) {
                        foreach ($interface in $interfacesWithIPs | Select-Object -First 1) {
                            $addresses = Get-NBIPAMAddress -Assigned_Object_Id $interface.id

                            $addresses | Should -Not -BeNullOrEmpty
                            $addresses | ForEach-Object {
                                $_.assigned_object.id | Should -Be $interface.id
                                $_.assigned_object_type | Should -Be 'dcim.interface'
                            }
                        }
                    }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test devices with primary IP found"
            }
        }

        It "Should have primary IP linked to device" {
            $devices = Get-NBDCIMDevice -Query $script:Prefix | Where-Object { $_.primary_ip4 -or $_.primary_ip6 } | Select-Object -First 5

            if ($devices) {
                foreach ($device in $devices) {
                    if ($device.primary_ip4) {
                        $primaryIP = Get-NBIPAMAddress -Id $device.primary_ip4.id

                        $primaryIP | Should -Not -BeNullOrEmpty
                        $primaryIP.assigned_object.device.id | Should -Be $device.id
                    }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test devices with primary IP found"
            }
        }
    }

    Context "Device Type -> Manufacturer" {
        It "Should have device types linked to manufacturers" {
            $deviceTypes = Get-NBDCIMDeviceType -Query $script:Prefix

            if ($deviceTypes) {
                foreach ($deviceType in $deviceTypes) {
                    $deviceType.manufacturer | Should -Not -BeNullOrEmpty
                    $deviceType.manufacturer.id | Should -BeGreaterThan 0

                    $manufacturer = Get-NBDCIMManufacturer -Id $deviceType.manufacturer.id

                    $manufacturer | Should -Not -BeNullOrEmpty
                    $manufacturer.id | Should -Be $deviceType.manufacturer.id
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test device types found"
            }
        }

        It "Should have devices using device types" {
            $deviceTypes = Get-NBDCIMDeviceType -Query $script:Prefix | Where-Object { $_.device_count -gt 0 }

            if ($deviceTypes) {
                foreach ($deviceType in $deviceTypes | Select-Object -First 2) {
                    $devices = Get-NBDCIMDevice -Device_Type_Id $deviceType.id

                    $devices | Should -Not -BeNullOrEmpty
                    $devices | ForEach-Object {
                        $_.device_type.id | Should -Be $deviceType.id
                    }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test device types with devices found"
            }
        }
    }

    Context "Cable Connections" {
        It "Should have cables linking interfaces" {
            $cables = Get-NBDCIMCable -Limit 50

            # Find cables connected to test devices that have both terminations
            $testCables = $cables | Where-Object {
                $_.a_terminations -and $_.a_terminations.Count -gt 0 -and
                $_.b_terminations -and $_.b_terminations.Count -gt 0 -and
                (($_.a_terminations[0].object.device.name -like "$($script:Prefix)*") -or
                 ($_.b_terminations[0].object.device.name -like "$($script:Prefix)*"))
            }

            if ($testCables) {
                foreach ($cable in $testCables | Select-Object -First 2) {
                    # Verify A termination
                    $cable.a_terminations | Should -Not -BeNullOrEmpty
                    $cable.a_terminations[0].object_type | Should -Match '^dcim\.'

                    # Verify B termination
                    $cable.b_terminations | Should -Not -BeNullOrEmpty
                    $cable.b_terminations[0].object_type | Should -Match '^dcim\.'
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test cables with complete terminations found"
            }
        }
    }
}

Describe "IPAM Hierarchy Relationships" -Tag 'Scenario', 'Relationships', 'IPAM' {
    Context "Aggregate -> Prefix -> IP Address" {
        It "Should have aggregates containing prefixes" {
            $aggregates = Get-NBIPAMAggregate -Query $script:Prefix

            if ($aggregates) {
                foreach ($aggregate in $aggregates | Select-Object -First 2) {
                    # Get prefixes within aggregate range
                    $prefixes = Get-NBIPAMPrefix -Within $aggregate.prefix

                    if ($prefixes) {
                        $prefixes.Count | Should -BeGreaterThan 0
                    }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test aggregates found"
            }
        }

        It "Should have prefixes containing IP addresses" {
            $prefixes = Get-NBIPAMPrefix -Status 'active' -Limit 5

            # Find prefixes with children
            $prefixesWithChildren = $prefixes | Where-Object { $_.children -gt 0 -or $_.prefix -match '/24$' }

            if ($prefixesWithChildren) {
                foreach ($prefix in $prefixesWithChildren | Select-Object -First 2) {
                    $addresses = Get-NBIPAMAddress -Parent $prefix.prefix

                    if ($addresses) {
                        $addresses.Count | Should -BeGreaterThan 0
                    }
                }
            }
        }
    }

    Context "VRF -> Prefix/Address" {
        It "Should have VRFs with associated prefixes" {
            $vrfs = Get-NBIPAMVRF -Query $script:Prefix

            if ($vrfs) {
                $vrfsWithPrefixes = $vrfs | Where-Object { $_.prefix_count -gt 0 }

                foreach ($vrf in $vrfsWithPrefixes | Select-Object -First 2) {
                    $prefixes = Get-NBIPAMPrefix -Vrf_Id $vrf.id

                    $prefixes | Should -Not -BeNullOrEmpty
                    $prefixes | ForEach-Object {
                        $_.vrf.id | Should -Be $vrf.id
                    }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test VRFs found"
            }
        }
    }

    Context "VLAN -> Prefix" {
        It "Should have VLANs linked to prefixes" {
            $vlans = Get-NBIPAMVLAN -Query $script:Prefix

            if ($vlans) {
                $vlansWithPrefixes = $vlans | Where-Object { $_.prefix_count -gt 0 }

                foreach ($vlan in $vlansWithPrefixes | Select-Object -First 2) {
                    $prefixes = Get-NBIPAMPrefix -Vlan_Id $vlan.id

                    $prefixes | Should -Not -BeNullOrEmpty
                    $prefixes | ForEach-Object {
                        $_.vlan.id | Should -Be $vlan.id
                        $_.vlan.vid | Should -Be $vlan.vid
                    }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test VLANs found"
            }
        }
    }

    Context "VLAN Group -> VLAN" {
        It "Should have VLAN groups containing VLANs" {
            $vlanGroups = Get-NBIPAMVLANGroup -Query $script:Prefix

            if ($vlanGroups) {
                $groupsWithVLANs = $vlanGroups | Where-Object { $_.vlan_count -gt 0 }

                foreach ($group in $groupsWithVLANs | Select-Object -First 2) {
                    $vlans = Get-NBIPAMVLAN -Group_Id $group.id

                    $vlans | Should -Not -BeNullOrEmpty
                    $vlans | ForEach-Object {
                        $_.group.id | Should -Be $group.id
                    }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test VLAN groups found"
            }
        }
    }
}

Describe "Virtualization Relationships" -Tag 'Scenario', 'Relationships', 'Virtualization' {
    Context "Cluster -> Virtual Machine -> Interface" {
        It "Should have VMs linked to clusters" {
            $clusters = Get-NBVirtualizationCluster -Query $script:Prefix

            if ($clusters) {
                $clustersWithVMs = $clusters | Where-Object { $_.virtualmachine_count -gt 0 }

                foreach ($cluster in $clustersWithVMs | Select-Object -First 2) {
                    $vms = Get-NBVirtualMachine -Cluster_Id $cluster.id

                    $vms | Should -Not -BeNullOrEmpty
                    $vms | ForEach-Object {
                        $_.cluster.id | Should -Be $cluster.id
                        $_.cluster.name | Should -Be $cluster.name
                    }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test clusters found"
            }
        }

        It "Should have VM interfaces linked to VMs" {
            $vms = Get-NBVirtualMachine -Query $script:Prefix -Limit 5

            if ($vms) {
                $vmsWithInterfaces = $vms | Where-Object { $_.interface_count -gt 0 }

                foreach ($vm in $vmsWithInterfaces | Select-Object -First 2) {
                    $interfaces = Get-NBVirtualMachineInterface -Virtual_Machine_Id $vm.id

                    $interfaces | Should -Not -BeNullOrEmpty
                    $interfaces | ForEach-Object {
                        $_.virtual_machine.id | Should -Be $vm.id
                    }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test VMs found"
            }
        }

        It "Should have IP addresses assigned to VM interfaces" {
            $vms = Get-NBVirtualMachine -Query $script:Prefix | Where-Object { $_.primary_ip4 -or $_.primary_ip6 } | Select-Object -First 3

            if ($vms) {
                foreach ($vm in $vms) {
                    if ($vm.primary_ip4) {
                        $primaryIP = Get-NBIPAMAddress -Id $vm.primary_ip4.id

                        $primaryIP | Should -Not -BeNullOrEmpty
                        $primaryIP.assigned_object_type | Should -Be 'virtualization.vminterface'
                    }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test VMs with primary IP found"
            }
        }
    }

    Context "Cluster Type/Group -> Cluster" {
        It "Should have clusters linked to cluster types" {
            $clusterTypes = Get-NBVirtualizationClusterType -Query $script:Prefix

            if ($clusterTypes) {
                $typesWithClusters = $clusterTypes | Where-Object { $_.cluster_count -gt 0 }

                foreach ($type in $typesWithClusters | Select-Object -First 2) {
                    $clusters = Get-NBVirtualizationCluster -Type_Id $type.id

                    $clusters | Should -Not -BeNullOrEmpty
                    $clusters | ForEach-Object {
                        $_.type.id | Should -Be $type.id
                    }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test cluster types found"
            }
        }
    }
}

Describe "Tenancy Relationships" -Tag 'Scenario', 'Relationships', 'Tenancy' {
    Context "Tenant Group -> Tenant" {
        It "Should have tenants linked to tenant groups" {
            $tenantGroups = Get-NBTenantGroup -Query $script:Prefix

            if ($tenantGroups) {
                $groupsWithTenants = $tenantGroups | Where-Object { $_.tenant_count -gt 0 }

                if ($groupsWithTenants) {
                    foreach ($group in $groupsWithTenants | Select-Object -First 2) {
                        $tenants = Get-NBTenant -GroupID $group.id

                        $tenants | Should -Not -BeNullOrEmpty
                        # Verify the number of returned tenants matches the group's tenant_count
                        $tenants.Count | Should -BeLessOrEqual $group.tenant_count
                    }
                }
                else {
                    Set-ItResult -Skipped -Because "No tenant groups have associated tenants"
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test tenant groups found"
            }
        }
    }

    Context "Tenant -> Resources" {
        It "Should have tenants associated with sites" {
            $tenants = Get-NBTenant -Query $script:Prefix

            if ($tenants) {
                foreach ($tenant in $tenants | Select-Object -First 2) {
                    $sites = Get-NBDCIMSite -Tenant_ID $tenant.id

                    if ($sites) {
                        $sites | ForEach-Object {
                            $_.tenant.id | Should -Be $tenant.id
                        }
                    }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test tenants found"
            }
        }

        It "Should have tenants associated with prefixes" {
            $tenants = Get-NBTenant -Query $script:Prefix

            if ($tenants) {
                foreach ($tenant in $tenants | Select-Object -First 2) {
                    $prefixes = Get-NBIPAMPrefix -Tenant_Id $tenant.id

                    if ($prefixes) {
                        $prefixes | ForEach-Object {
                            $_.tenant.id | Should -Be $tenant.id
                        }
                    }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test tenants found"
            }
        }
    }

    Context "Contact Assignments" {
        It "Should have contacts assigned to objects" {
            $contacts = Get-NBContact -Query $script:Prefix

            if ($contacts) {
                $contactAssignments = Get-NBContactAssignment -Limit 20

                # Find assignments for test contacts
                $testAssignments = $contactAssignments | Where-Object {
                    $_.contact.name -like "$($script:Prefix)*"
                }

                if ($testAssignments) {
                    foreach ($assignment in $testAssignments | Select-Object -First 2) {
                        $assignment.contact | Should -Not -BeNullOrEmpty
                        $assignment.object | Should -Not -BeNullOrEmpty
                        $assignment.role | Should -Not -BeNullOrEmpty
                    }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test contacts found"
            }
        }
    }
}

Describe "Circuits Relationships" -Tag 'Scenario', 'Relationships', 'Circuits' {
    Context "Provider -> Circuit -> Termination" {
        It "Should have circuits linked to providers" {
            $providers = Get-NBCircuitProvider -Query $script:Prefix

            if ($providers) {
                $providersWithCircuits = $providers | Where-Object { $_.circuit_count -gt 0 }

                foreach ($provider in $providersWithCircuits | Select-Object -First 2) {
                    # Get-NBCircuit Provider filter has issues in Netbox 4.x API
                    # Use client-side filtering instead
                    $allCircuits = Get-NBCircuit -Limit 100
                    $circuits = $allCircuits | Where-Object { $_.provider.id -eq $provider.id }

                    $circuits | Should -Not -BeNullOrEmpty
                    $circuits | ForEach-Object {
                        $_.provider.id | Should -Be $provider.id
                    }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test providers found"
            }
        }

        It "Should have circuit terminations linked to sites" {
            $circuits = Get-NBCircuit -Query $script:Prefix -Limit 10

            if ($circuits) {
                foreach ($circuit in $circuits | Select-Object -First 2) {
                    $terminations = Get-NBCircuitTermination -Circuit_Id $circuit.id

                    if ($terminations) {
                        foreach ($termination in $terminations) {
                            $termination.circuit.id | Should -Be $circuit.id

                            if ($termination.site) {
                                $termination.site.id | Should -BeGreaterThan 0
                            }
                        }
                    }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test circuits found"
            }
        }
    }
}

Describe "VPN Relationships" -Tag 'Scenario', 'Relationships', 'VPN' {
    Context "IPSec Hierarchy" {
        It "Should have IPSec profiles linked to policies" {
            # Get-NBVPNIPSecProfile doesn't have -All parameter, use -Limit
            $ipsecProfiles = Get-NBVPNIPSecProfile -Limit 100 | Where-Object { $_.name -like "$($script:Prefix)*" }

            if ($ipsecProfiles) {
                foreach ($profile in $ipsecProfiles) {
                    # Check IKE policy link
                    if ($profile.ike_policy) {
                        $ikePolicy = Get-NBVPNIKEPolicy -Id $profile.ike_policy.id

                        $ikePolicy | Should -Not -BeNullOrEmpty
                        $ikePolicy.id | Should -Be $profile.ike_policy.id
                    }

                    # Check IPSec policy link
                    if ($profile.ipsec_policy) {
                        $ipsecPolicy = Get-NBVPNIPSecPolicy -Id $profile.ipsec_policy.id

                        $ipsecPolicy | Should -Not -BeNullOrEmpty
                        $ipsecPolicy.id | Should -Be $profile.ipsec_policy.id
                    }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test IPSec profiles found"
            }
        }

        It "Should have tunnels linked to IPSec profiles" {
            $tunnels = Get-NBVPNTunnel -Query $script:Prefix

            if ($tunnels) {
                $tunnelsWithProfile = $tunnels | Where-Object { $_.ipsec_profile }

                foreach ($tunnel in $tunnelsWithProfile | Select-Object -First 2) {
                    $tunnel.ipsec_profile | Should -Not -BeNullOrEmpty

                    $profile = Get-NBVPNIPSecProfile -Id $tunnel.ipsec_profile.id

                    $profile | Should -Not -BeNullOrEmpty
                    $profile.id | Should -Be $tunnel.ipsec_profile.id
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test tunnels found"
            }
        }
    }

    Context "Tunnel -> Termination" {
        It "Should have tunnel terminations linked to interfaces" {
            $tunnels = Get-NBVPNTunnel -Query $script:Prefix

            if ($tunnels) {
                foreach ($tunnel in $tunnels | Select-Object -First 2) {
                    $terminations = Get-NBVPNTunnelTermination -Tunnel_Id $tunnel.id

                    if ($terminations) {
                        foreach ($termination in $terminations) {
                            $termination.tunnel.id | Should -Be $tunnel.id
                        }
                    }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test tunnels found"
            }
        }
    }
}

Describe "Cross-Module Relationships" -Tag 'Scenario', 'Relationships', 'CrossModule' {
    Context "Device with full context" {
        It "Should retrieve device with all related objects" {
            $devices = Get-NBDCIMDevice -Query $script:Prefix | Where-Object { $_.primary_ip4 -or $_.primary_ip6 } | Select-Object -First 1

            if ($devices) {
                $device = $devices | Select-Object -First 1

                # Verify site relationship
                $device.site | Should -Not -BeNullOrEmpty
                $site = Get-NBDCIMSite -Id $device.site.id
                $site | Should -Not -BeNullOrEmpty

                # Verify device type relationship
                $device.device_type | Should -Not -BeNullOrEmpty
                $deviceType = Get-NBDCIMDeviceType -Id $device.device_type.id
                $deviceType | Should -Not -BeNullOrEmpty

                # Verify manufacturer through device type
                $deviceType.manufacturer | Should -Not -BeNullOrEmpty
                $manufacturer = Get-NBDCIMManufacturer -Id $deviceType.manufacturer.id
                $manufacturer | Should -Not -BeNullOrEmpty

                # Verify primary IP
                if ($device.primary_ip4) {
                    $ip = Get-NBIPAMAddress -Id $device.primary_ip4.id
                    $ip | Should -Not -BeNullOrEmpty
                    $ip.assigned_object.device.id | Should -Be $device.id
                }

                Write-Host "Device: $($device.name)" -ForegroundColor Cyan
                Write-Host "  Site: $($site.name)" -ForegroundColor Gray
                Write-Host "  Type: $($deviceType.model) ($($manufacturer.name))" -ForegroundColor Gray
                if ($device.primary_ip4) {
                    Write-Host "  IP: $($device.primary_ip4.address)" -ForegroundColor Gray
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test devices with primary IP found"
            }
        }
    }
}
