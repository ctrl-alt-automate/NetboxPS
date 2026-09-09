<#
.SYNOPSIS
    End-to-end workflow scenario tests for PowerNetbox.

.DESCRIPTION
    These tests simulate real-world workflows and use cases that span
    multiple Netbox modules and operations. They verify that complex
    multi-step operations work correctly together.

    Scenarios include:
    - New datacenter onboarding
    - Server lifecycle management
    - Network provisioning
    - IP address management workflows

.NOTES
    Run with: Invoke-Pester -Path ./Tests/Scenario/Workflows.Tests.ps1 -Tag 'Scenario'

    Environment variables:
    - SCENARIO_ENV: Netbox version (4.7.0, 4.6.10, 4.5.10, 4.4.10, 4.3.7 or custom) - defaults to 4.7.0;
      the local Docker stack from ./scripts/Start-NetboxDocker.ps1 -Version <ver> -SetEnvironment
    - SCENARIO_SKIP_IMPORT: Set to '1' to skip data import

    WARNING: These tests create and delete objects. They clean up after themselves,
    but you should not run them against a production environment.
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
    $script:WorkflowPrefix = "WF-TEST"  # Prefix for workflow test objects

    # Track created objects for cleanup
    $script:CreatedObjects = @{
        Regions        = [System.Collections.ArrayList]::new()
        Sites          = [System.Collections.ArrayList]::new()
        Locations      = [System.Collections.ArrayList]::new()
        Racks          = [System.Collections.ArrayList]::new()
        Devices        = [System.Collections.ArrayList]::new()
        Interfaces     = [System.Collections.ArrayList]::new()
        Addresses      = [System.Collections.ArrayList]::new()
        Prefixes       = [System.Collections.ArrayList]::new()
        VLANs          = [System.Collections.ArrayList]::new()
        VLANGroups     = [System.Collections.ArrayList]::new()
        VMs            = [System.Collections.ArrayList]::new()
        VMInterfaces   = [System.Collections.ArrayList]::new()
        Cables         = [System.Collections.ArrayList]::new()
    }
}

AfterAll {
    Write-Host "`nCleaning up workflow test objects..." -ForegroundColor Yellow

    # Cleanup in reverse dependency order
    $cleanupOrder = @(
        @{ Type = 'Cables'; Func = { param($id) Remove-NBDCIMCable -Id $id -Confirm:$false -ErrorAction SilentlyContinue } }
        @{ Type = 'Addresses'; Func = { param($id) Remove-NBIPAMAddress -Id $id -Confirm:$false -ErrorAction SilentlyContinue } }
        @{ Type = 'VMInterfaces'; Func = { param($id) Remove-NBVirtualMachineInterface -Id $id -Confirm:$false -ErrorAction SilentlyContinue } }
        @{ Type = 'VMs'; Func = { param($id) Remove-NBVirtualMachine -Id $id -Confirm:$false -ErrorAction SilentlyContinue } }
        @{ Type = 'Interfaces'; Func = { param($id) Remove-NBDCIMInterface -Id $id -Confirm:$false -ErrorAction SilentlyContinue } }
        @{ Type = 'Devices'; Func = { param($id) Remove-NBDCIMDevice -Id $id -Confirm:$false -ErrorAction SilentlyContinue } }
        @{ Type = 'Racks'; Func = { param($id) Remove-NBDCIMRack -Id $id -Confirm:$false -ErrorAction SilentlyContinue } }
        @{ Type = 'Prefixes'; Func = { param($id) Remove-NBIPAMPrefix -Id $id -Confirm:$false -ErrorAction SilentlyContinue } }
        @{ Type = 'VLANs'; Func = { param($id) Remove-NBIPAMVLAN -Id $id -Confirm:$false -ErrorAction SilentlyContinue } }
        @{ Type = 'VLANGroups'; Func = { param($id) Remove-NBIPAMVLANGroup -Id $id -Confirm:$false -ErrorAction SilentlyContinue } }
        @{ Type = 'Locations'; Func = { param($id) Remove-NBDCIMLocation -Id $id -Confirm:$false -ErrorAction SilentlyContinue } }
        @{ Type = 'Sites'; Func = { param($id) Remove-NBDCIMSite -Id $id -Confirm:$false -ErrorAction SilentlyContinue } }
        @{ Type = 'Regions'; Func = { param($id) Remove-NBDCIMRegion -Id $id -Confirm:$false -ErrorAction SilentlyContinue } }
    )

    foreach ($item in $cleanupOrder) {
        foreach ($id in $script:CreatedObjects[$item.Type]) {
            try {
                & $item.Func $id
            }
            catch { }
        }
    }

    Write-Host "Cleanup complete." -ForegroundColor Green
}

Describe "Server Lifecycle Workflow" -Tag 'Scenario', 'Workflow', 'Lifecycle' {
    BeforeAll {
        # Get test prerequisites
        $script:WF_Site = Get-NBDCIMSite -Query $script:Prefix | Select-Object -First 1
        $script:WF_Role = Get-NBDCIMDeviceRole -All | Where-Object { $_.name -like "$($script:Prefix)*" } | Select-Object -First 1
        $script:WF_Type = Get-NBDCIMDeviceType -Query $script:Prefix | Select-Object -First 1
        $script:WF_Rack = Get-NBDCIMRack -Query $script:Prefix | Select-Object -First 1

        if (-not $script:WF_Site -or -not $script:WF_Role -or -not $script:WF_Type) {
            $script:SkipLifecycleTests = $true
        }
        else {
            $script:SkipLifecycleTests = $false
        }

        $script:ServerName = "$($script:WorkflowPrefix)-SERVER-$(Get-Date -Format 'yyyyMMddHHmmss')"
        $script:BaseOctet = Get-Random -Minimum 1 -Maximum 200
    }

    Context "Phase 1: Server Provisioning (Planned)" {
        It "Should create server in 'planned' state" -Skip:$script:SkipLifecycleTests {
            $params = @{
                Name        = $script:ServerName
                Role        = $script:WF_Role.id
                Device_Type = $script:WF_Type.id
                Site        = $script:WF_Site.id
                Status      = 'planned'
            }

            if ($script:WF_Rack) {
                $params.Rack = $script:WF_Rack.id
                $params.Position = 10
                $params.Face = 'front'
            }

            # Note: Don't use -Force with single device creation (it's only for bulk mode)
            $device = New-NBDCIMDevice @params -Confirm:$false

            $device | Should -Not -BeNullOrEmpty
            $device.status.value | Should -Be 'planned'
            $device.name | Should -Be $script:ServerName

            [void]$script:CreatedObjects.Devices.Add($device.id)
            $script:WF_Device = $device

            Write-Host "  Created planned server: $($device.name)" -ForegroundColor Cyan
        }

        It "Should provision management interface" -Skip:$script:SkipLifecycleTests {
            $interface = New-NBDCIMInterface `
                -Device $script:WF_Device.id `
                -Name 'MGMT' `
                -Type '1000base-t' `
                -Mgmt_Only $true `
                -Confirm:$false

            $interface | Should -Not -BeNullOrEmpty
            $interface.mgmt_only | Should -BeTrue

            [void]$script:CreatedObjects.Interfaces.Add($interface.id)
            $script:WF_MgmtInterface = $interface

            Write-Host "  Created management interface: $($interface.name)" -ForegroundColor Gray
        }

        It "Should assign management IP" -Skip:$script:SkipLifecycleTests {
            $ip = New-NBIPAMAddress `
                -Address "10.200.$($script:BaseOctet).1/24" `
                -Status 'active' `
                -Assigned_Object_Type 'dcim.interface' `
                -Assigned_Object_Id $script:WF_MgmtInterface.id `
                -Description "Management IP for $($script:ServerName)" `
                -Confirm:$false

            $ip | Should -Not -BeNullOrEmpty
            $ip.assigned_object.id | Should -Be $script:WF_MgmtInterface.id

            [void]$script:CreatedObjects.Addresses.Add($ip.id)
            $script:WF_MgmtIP = $ip

            Write-Host "  Assigned management IP: $($ip.address)" -ForegroundColor Gray
        }
    }

    Context "Phase 2: Server Staging" {
        It "Should add production interfaces" -Skip:$script:SkipLifecycleTests {
            $interfaces = 0..3 | ForEach-Object {
                [PSCustomObject]@{
                    Device = $script:WF_Device.id
                    Name   = "eth$_"
                    Type   = '10gbase-sr'
                }
            } | New-NBDCIMInterface -Force

            $interfaces | Should -Not -BeNullOrEmpty
            $interfaces.Count | Should -Be 4

            $interfaces | ForEach-Object { [void]$script:CreatedObjects.Interfaces.Add($_.id) }
            $script:WF_ProdInterfaces = $interfaces

            Write-Host "  Created $($interfaces.Count) production interfaces" -ForegroundColor Gray
        }

        It "Should transition to 'staged' status" -Skip:$script:SkipLifecycleTests {
            $updated = Set-NBDCIMDevice -Id $script:WF_Device.id -Status 'staged' -Force

            $updated | Should -Not -BeNullOrEmpty
            $updated.status.value | Should -Be 'staged'

            Write-Host "  Server status: staged" -ForegroundColor Cyan
        }
    }

    Context "Phase 3: Server Activation" {
        It "Should assign production IPs" -Skip:$script:SkipLifecycleTests {
            $ips = $script:WF_ProdInterfaces | ForEach-Object -Begin { $i = 1 } -Process {
                $i++
                [PSCustomObject]@{
                    Address              = "10.200.$($script:BaseOctet).$i/24"
                    Status               = 'active'
                    Assigned_Object_Type = 'dcim.interface'
                    Assigned_Object_Id   = $_.id
                }
            } | New-NBIPAMAddress -Force

            $ips | Should -Not -BeNullOrEmpty
            $ips.Count | Should -Be 4

            $ips | ForEach-Object { [void]$script:CreatedObjects.Addresses.Add($_.id) }
            $script:WF_ProdIPs = $ips

            Write-Host "  Assigned $($ips.Count) production IPs" -ForegroundColor Gray
        }

        It "Should set primary IP" -Skip:$script:SkipLifecycleTests {
            $updated = Set-NBDCIMDevice `
                -Id $script:WF_Device.id `
                -Primary_Ip4 $script:WF_ProdIPs[0].id `
                -Force

            $updated | Should -Not -BeNullOrEmpty
            $updated.primary_ip4.id | Should -Be $script:WF_ProdIPs[0].id

            Write-Host "  Set primary IP: $($script:WF_ProdIPs[0].address)" -ForegroundColor Gray
        }

        It "Should transition to 'active' status" -Skip:$script:SkipLifecycleTests {
            $updated = Set-NBDCIMDevice -Id $script:WF_Device.id -Status 'active' -Force

            $updated | Should -Not -BeNullOrEmpty
            $updated.status.value | Should -Be 'active'

            Write-Host "  Server status: ACTIVE" -ForegroundColor Green
        }
    }

    Context "Phase 4: Verification" {
        It "Should have complete server configuration" -Skip:$script:SkipLifecycleTests {
            $device = Get-NBDCIMDevice -Id $script:WF_Device.id

            $device | Should -Not -BeNullOrEmpty
            $device.status.value | Should -Be 'active'
            $device.primary_ip4 | Should -Not -BeNullOrEmpty

            $interfaces = Get-NBDCIMInterface -Device_Id $device.id
            $interfaces.Count | Should -BeGreaterOrEqual 5

            Write-Host "  Verified: $($device.name) is fully configured" -ForegroundColor Green
        }
    }

    Context "Phase 5: Decommissioning" {
        It "Should transition to 'decommissioning' status" -Skip:$script:SkipLifecycleTests {
            $updated = Set-NBDCIMDevice -Id $script:WF_Device.id -Status 'decommissioning' -Force

            $updated.status.value | Should -Be 'decommissioning'

            Write-Host "  Server status: decommissioning" -ForegroundColor Yellow
        }

        It "Should release IP addresses" -Skip:$script:SkipLifecycleTests {
            # Mark IPs as deprecated
            $allIPs = $script:WF_ProdIPs + @($script:WF_MgmtIP)
            $updates = $allIPs | ForEach-Object {
                [PSCustomObject]@{
                    Id     = $_.id
                    Status = 'deprecated'
                }
            }

            $updated = $updates | Set-NBIPAMAddress -Force

            $updated | ForEach-Object {
                $_.status.value | Should -Be 'deprecated'
            }

            Write-Host "  Released $($updated.Count) IP addresses" -ForegroundColor Gray
        }
    }
}

Describe "VM Provisioning Workflow" -Tag 'Scenario', 'Workflow', 'VM' {
    BeforeAll {
        $script:WF_Cluster = Get-NBVirtualizationCluster -Query $script:Prefix | Select-Object -First 1
        $script:WF_VMRole = Get-NBDCIMDeviceRole -All | Where-Object { $_.vm_role -and $_.name -like "$($script:Prefix)*" } | Select-Object -First 1

        if (-not $script:WF_Cluster) {
            $script:SkipVMWorkflow = $true
        }
        else {
            $script:SkipVMWorkflow = $false
        }

        $script:VMName = "$($script:WorkflowPrefix)-VM-$(Get-Date -Format 'yyyyMMddHHmmss')"
        $script:VMBaseOctet = Get-Random -Minimum 1 -Maximum 200
    }

    Context "VM Creation and Configuration" {
        It "Should create VM with specifications" -Skip:$script:SkipVMWorkflow {
            $params = @{
                Name    = $script:VMName
                Cluster = $script:WF_Cluster.id
                VCPUs   = 4
                Memory  = 8192  # 8GB
                Disk    = 100   # 100GB
                Status  = 'active'
            }

            if ($script:WF_VMRole) {
                $params.Role = $script:WF_VMRole.id
            }

            # Note: -Force is only for bulk mode, use -Confirm:$false for single creation
            $vm = New-NBVirtualMachine @params -Confirm:$false

            $vm | Should -Not -BeNullOrEmpty
            $vm.vcpus | Should -Be 4
            $vm.memory | Should -Be 8192

            [void]$script:CreatedObjects.VMs.Add($vm.id)
            $script:WF_VM = $vm

            Write-Host "  Created VM: $($vm.name) (vCPU: $($vm.vcpus), RAM: $($vm.memory)MB)" -ForegroundColor Cyan
        }

        It "Should add network interfaces" -Skip:$script:SkipVMWorkflow {
            $interfaces = @(
                [PSCustomObject]@{ Virtual_Machine = $script:WF_VM.id; Name = 'eth0' }
                [PSCustomObject]@{ Virtual_Machine = $script:WF_VM.id; Name = 'eth1' }
            ) | New-NBVirtualMachineInterface -Force

            $interfaces | Should -Not -BeNullOrEmpty
            $interfaces.Count | Should -Be 2

            $interfaces | ForEach-Object { [void]$script:CreatedObjects.VMInterfaces.Add($_.id) }
            $script:WF_VMInterfaces = $interfaces

            Write-Host "  Added $($interfaces.Count) network interfaces" -ForegroundColor Gray
        }

        It "Should assign IP addresses" -Skip:$script:SkipVMWorkflow {
            $ips = $script:WF_VMInterfaces | ForEach-Object -Begin { $i = 0 } -Process {
                $i++
                [PSCustomObject]@{
                    Address              = "10.201.$($script:VMBaseOctet).$i/24"
                    Status               = 'active'
                    Assigned_Object_Type = 'virtualization.vminterface'
                    Assigned_Object_Id   = $_.id
                }
            } | New-NBIPAMAddress -Force

            $ips | Should -Not -BeNullOrEmpty

            $ips | ForEach-Object { [void]$script:CreatedObjects.Addresses.Add($_.id) }
            $script:WF_VMIPs = $ips

            Write-Host "  Assigned IPs: $($ips.address -join ', ')" -ForegroundColor Gray
        }

        It "Should set primary IP" -Skip:$script:SkipVMWorkflow {
            $updated = Set-NBVirtualMachine `
                -Id $script:WF_VM.id `
                -Primary_Ip4 $script:WF_VMIPs[0].id `
                -Force

            $updated.primary_ip4.id | Should -Be $script:WF_VMIPs[0].id

            Write-Host "  Primary IP set: $($script:WF_VMIPs[0].address)" -ForegroundColor Green
        }
    }

    Context "VM Lifecycle Operations" {
        It "Should resize VM resources" -Skip:$script:SkipVMWorkflow {
            $updated = Set-NBVirtualMachine `
                -Id $script:WF_VM.id `
                -VCPUs 8 `
                -Memory 16384 `
                -Force

            $updated.vcpus | Should -Be 8
            $updated.memory | Should -Be 16384

            Write-Host "  Resized VM: vCPU 4->8, RAM 8->16GB" -ForegroundColor Cyan
        }

        It "Should add comments/documentation" -Skip:$script:SkipVMWorkflow {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $comments = @"
## VM Documentation
- Created: $timestamp
- Purpose: Workflow test VM
- Owner: PowerNetbox Test Suite
"@

            $updated = Set-NBVirtualMachine `
                -Id $script:WF_VM.id `
                -Comments $comments `
                -Force

            $updated.comments | Should -Match 'VM Documentation'

            Write-Host "  Added documentation to VM" -ForegroundColor Gray
        }
    }
}

Describe "Network Segment Provisioning Workflow" -Tag 'Scenario', 'Workflow', 'Network' {
    BeforeAll {
        $script:WF_NetSite = Get-NBDCIMSite -Query $script:Prefix | Select-Object -First 1

        if (-not $script:WF_NetSite) {
            $script:SkipNetworkWorkflow = $true
        }
        else {
            $script:SkipNetworkWorkflow = $false
        }

        $script:NetTimestamp = Get-Date -Format "yyyyMMddHHmmss"
        $script:NetOctet = Get-Random -Minimum 1 -Maximum 200
    }

    Context "VLAN and Prefix Setup" {
        It "Should create VLAN group" -Skip:$script:SkipNetworkWorkflow {
            # Note: Scope_Type requires content type ID (uint64), not string
            # Creating group without scope for simplicity
            $vlanGroup = New-NBIPAMVLANGroup `
                -Name "$($script:WorkflowPrefix)-VLAN-Group-$($script:NetTimestamp)" `
                -Slug "wf-vlan-group-$($script:NetTimestamp)"

            $vlanGroup | Should -Not -BeNullOrEmpty

            [void]$script:CreatedObjects.VLANGroups.Add($vlanGroup.id)
            $script:WF_VLANGroup = $vlanGroup

            Write-Host "  Created VLAN group: $($vlanGroup.name)" -ForegroundColor Cyan
        }

        It "Should create production VLANs" -Skip:$script:SkipNetworkWorkflow {
            $vlans = @(
                @{ VID = 100; Name = "$($script:WorkflowPrefix)-Servers"; Role = 'Server network' }
                @{ VID = 110; Name = "$($script:WorkflowPrefix)-Storage"; Role = 'Storage network' }
                @{ VID = 200; Name = "$($script:WorkflowPrefix)-Management"; Role = 'Management network' }
            ) | ForEach-Object {
                [PSCustomObject]@{
                    VID    = $_.VID
                    Name   = "$($_.Name)-$($script:NetTimestamp)"
                    Status = 'active'
                    Group  = $script:WF_VLANGroup.id
                }
            } | New-NBIPAMVLAN -Force

            $vlans | Should -Not -BeNullOrEmpty
            $vlans.Count | Should -Be 3

            $vlans | ForEach-Object { [void]$script:CreatedObjects.VLANs.Add($_.id) }
            $script:WF_VLANs = $vlans

            Write-Host "  Created VLANs: $($vlans.vid -join ', ')" -ForegroundColor Gray
        }

        It "Should create prefixes for VLANs" -Skip:$script:SkipNetworkWorkflow {
            $prefixes = $script:WF_VLANs | ForEach-Object -Begin { $i = -1 } -Process {
                $i++
                [PSCustomObject]@{
                    Prefix      = "10.$($script:NetOctet).$i.0/24"
                    Status      = 'active'
                    Site        = $script:WF_NetSite.id
                    Vlan        = $_.id
                    Description = "Prefix for VLAN $($_.vid)"
                }
            } | New-NBIPAMPrefix -Force

            $prefixes | Should -Not -BeNullOrEmpty
            $prefixes.Count | Should -Be 3

            $prefixes | ForEach-Object { [void]$script:CreatedObjects.Prefixes.Add($_.id) }
            $script:WF_Prefixes = $prefixes

            Write-Host "  Created prefixes: $($prefixes.prefix -join ', ')" -ForegroundColor Gray
        }
    }

    Context "IP Address Allocation" {
        It "Should allocate gateway IPs (.1)" -Skip:$script:SkipNetworkWorkflow {
            $gateways = $script:WF_Prefixes | ForEach-Object {
                $baseIP = ($_.prefix -split '/')[0] -replace '\.0$', '.1'
                [PSCustomObject]@{
                    Address     = "$baseIP/24"
                    Status      = 'active'
                    Role        = 'anycast'  # Gateway role
                    Description = "Gateway for $($_.prefix)"
                }
            } | New-NBIPAMAddress -Force

            $gateways | Should -Not -BeNullOrEmpty
            $gateways.Count | Should -Be 3

            $gateways | ForEach-Object { [void]$script:CreatedObjects.Addresses.Add($_.id) }

            Write-Host "  Allocated gateway IPs: $($gateways.address -join ', ')" -ForegroundColor Gray
        }

        It "Should allocate DHCP range (.100-.200)" -Skip:$script:SkipNetworkWorkflow {
            $prefix = $script:WF_Prefixes | Select-Object -First 1
            $baseNet = ($prefix.prefix -split '/')[0] -replace '\.0$', ''

            $dhcpIPs = 100..105 | ForEach-Object {
                [PSCustomObject]@{
                    Address     = "$baseNet.$_/24"
                    Status      = 'dhcp'
                    Description = "DHCP pool"
                }
            } | New-NBIPAMAddress -Force

            $dhcpIPs | Should -Not -BeNullOrEmpty

            $dhcpIPs | ForEach-Object { [void]$script:CreatedObjects.Addresses.Add($_.id) }

            Write-Host "  Allocated DHCP range: $($dhcpIPs.Count) addresses" -ForegroundColor Gray
        }
    }
}

Describe "Infrastructure Inventory Workflow" -Tag 'Scenario', 'Workflow', 'Inventory' {
    Context "Query and Report Generation" {
        It "Should generate site inventory report" {
            $sites = Get-NBDCIMSite -Query $script:Prefix

            $report = $sites | ForEach-Object {
                [PSCustomObject]@{
                    Name        = $_.name
                    Status      = $_.status.value
                    Devices     = $_.device_count
                    Racks       = $_.rack_count
                    Prefixes    = $_.prefix_count
                    VirtualMachines = $_.virtualmachine_count
                }
            }

            $report | Should -Not -BeNullOrEmpty

            Write-Host "`n  Site Inventory Report:" -ForegroundColor Cyan
            $report | ForEach-Object {
                Write-Host "    $($_.Name): Devices=$($_.Devices), Racks=$($_.Racks), Prefixes=$($_.Prefixes)" -ForegroundColor Gray
            }
        }

        It "Should generate device type usage report" {
            $deviceTypes = Get-NBDCIMDeviceType -Query $script:Prefix

            if ($deviceTypes) {
                $report = $deviceTypes | Where-Object { $_.device_count -gt 0 } | ForEach-Object {
                    [PSCustomObject]@{
                        Manufacturer = $_.manufacturer.name
                        Model        = $_.model
                        DeviceCount  = $_.device_count
                        UHeight      = $_.u_height
                    }
                }

                if ($report) {
                    Write-Host "`n  Device Type Usage:" -ForegroundColor Cyan
                    $report | ForEach-Object {
                        Write-Host "    $($_.Manufacturer) $($_.Model): $($_.DeviceCount) devices ($($_.UHeight)U)" -ForegroundColor Gray
                    }
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test device types found"
            }
        }

        It "Should generate IP utilization report" {
            $prefixes = Get-NBIPAMPrefix -Status 'active' -Limit 10

            if ($prefixes) {
                $report = $prefixes | Where-Object { $_.prefix -match '/24$' } | Select-Object -First 5 | ForEach-Object {
                    # Calculate utilization based on children
                    $utilizationPct = if ($_.children -gt 0) {
                        [math]::Round(($_.children / 256) * 100, 1)
                    }
                    else { 0 }

                    [PSCustomObject]@{
                        Prefix      = $_.prefix
                        Status      = $_.status.value
                        Site        = if ($_.site) { $_.site.name } else { 'N/A' }
                        Children    = $_.children
                        Utilization = "$utilizationPct%"
                    }
                }

                Write-Host "`n  Prefix Utilization:" -ForegroundColor Cyan
                $report | ForEach-Object {
                    Write-Host "    $($_.Prefix): $($_.Children) children ($($_.Utilization) used)" -ForegroundColor Gray
                }
            }
            else {
                Set-ItResult -Skipped -Because "No active prefixes found"
            }
        }
    }

    Context "Cross-Reference Queries" {
        It "Should find devices without primary IP" {
            $devices = Get-NBDCIMDevice -Query $script:Prefix -Has_Primary_IP $false -Limit 10

            Write-Host "`n  Devices without Primary IP:" -ForegroundColor Yellow
            if ($devices) {
                $devices | ForEach-Object {
                    Write-Host "    - $($_.name) (Site: $($_.site.name))" -ForegroundColor Gray
                }
            }
            else {
                Write-Host "    None found - all devices have primary IPs" -ForegroundColor Green
            }
        }

        It "Should find VMs with low resources" {
            $vms = Get-NBVirtualMachine -Query $script:Prefix

            if ($vms) {
                $lowResourceVMs = $vms | Where-Object { $_.vcpus -le 2 -or $_.memory -le 2048 }

                Write-Host "`n  VMs with Low Resources (<=2 vCPU or <=2GB RAM):" -ForegroundColor Yellow
                if ($lowResourceVMs) {
                    $lowResourceVMs | ForEach-Object {
                        Write-Host "    - $($_.name): $($_.vcpus) vCPU, $($_.memory)MB RAM" -ForegroundColor Gray
                    }
                }
                else {
                    Write-Host "    None found" -ForegroundColor Green
                }
            }
            else {
                Set-ItResult -Skipped -Because "No test VMs found"
            }
        }
    }
}

Describe "Error Handling Workflow" -Tag 'Scenario', 'Workflow', 'ErrorHandling' {
    Context "Graceful Error Recovery" {
        It "Should handle missing referenced object" {
            # ID 999999 doesn't exist, so this should throw (404 Not Found)
            { Get-NBDCIMDevice -Id 999999 } | Should -Throw
        }

        It "Should handle invalid filter values" {
            # Invalid status filter - Netbox API returns 400 Bad Request
            # This should throw an error
            { Get-NBDCIMDevice -Status 'invalid_status' -ErrorAction Stop } | Should -Throw
        }

        It "Should validate required fields on create" {
            # Providing empty name should throw - API rejects it with 400
            { New-NBDCIMDevice -Name '' -Site 1 -Role 1 -Device_Type 1 -ErrorAction Stop } | Should -Throw
        }
    }
}
