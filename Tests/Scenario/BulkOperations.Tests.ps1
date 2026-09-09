<#
.SYNOPSIS
    Scenario tests for bulk operations against populated Netbox test data.

.DESCRIPTION
    These tests verify that bulk create, update, and delete operations work
    correctly in a populated Netbox environment. Tests include:
    - Bulk device creation with realistic data
    - Bulk IP address management
    - Bulk status updates
    - Pipeline-based workflows

.NOTES
    Run with: Invoke-Pester -Path ./Tests/Scenario/BulkOperations.Tests.ps1 -Tag 'Scenario'

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
    $script:BulkPrefix = "BULK-TEST"  # Separate prefix for bulk test objects

    # Get reference objects for bulk operations
    $script:TestSite = Get-NBDCIMSite -Query $script:Prefix | Select-Object -First 1
    $script:TestRole = Get-NBDCIMDeviceRole -All | Where-Object { $_.name -like "$($script:Prefix)*" } | Select-Object -First 1
    $script:TestType = Get-NBDCIMDeviceType -Query $script:Prefix | Select-Object -First 1
    $script:TestCluster = Get-NBVirtualizationCluster -Query $script:Prefix | Select-Object -First 1
    $script:TestPrefix = Get-NBIPAMPrefix -Status 'active' -Limit 1 | Select-Object -First 1

    # Track created objects for cleanup
    $script:CreatedDevices = [System.Collections.ArrayList]::new()
    $script:CreatedVMs = [System.Collections.ArrayList]::new()
    $script:CreatedAddresses = [System.Collections.ArrayList]::new()
    $script:CreatedInterfaces = [System.Collections.ArrayList]::new()
}

AfterAll {
    Write-Host "`nCleaning up bulk test objects..." -ForegroundColor Yellow

    # Cleanup created objects in reverse dependency order

    # Clean up IP addresses first (most dependent)
    foreach ($id in $script:CreatedAddresses) {
        try {
            Remove-NBIPAMAddress -Id $id -Confirm:$false -ErrorAction SilentlyContinue
        }
        catch { }
    }

    # Clean up interfaces
    foreach ($id in $script:CreatedInterfaces) {
        try {
            Remove-NBDCIMInterface -Id $id -Confirm:$false -ErrorAction SilentlyContinue
        }
        catch { }
    }

    # Clean up VMs
    foreach ($id in $script:CreatedVMs) {
        try {
            Remove-NBVirtualMachine -Id $id -Confirm:$false -ErrorAction SilentlyContinue
        }
        catch { }
    }

    # Clean up devices
    foreach ($id in $script:CreatedDevices) {
        try {
            Remove-NBDCIMDevice -Id $id -Confirm:$false -ErrorAction SilentlyContinue
        }
        catch { }
    }

    Write-Host "Cleanup complete." -ForegroundColor Green
}

Describe "Bulk Device Operations" -Tag 'Scenario', 'Bulk', 'DCIM' {
    BeforeAll {
        # Skip if prerequisites are missing
        if (-not $script:TestSite -or -not $script:TestRole -or -not $script:TestType) {
            $script:SkipDeviceTests = $true
        }
        else {
            $script:SkipDeviceTests = $false
        }
    }

    Context "Bulk Device Creation" {
        It "Should create multiple devices via pipeline" -Skip:$script:SkipDeviceTests {
            $timestamp = Get-Date -Format "yyyyMMddHHmmss"
            $devices = 1..5 | ForEach-Object {
                [PSCustomObject]@{
                    Name        = "$($script:BulkPrefix)-Device-$_-$timestamp"
                    Role        = $script:TestRole.id
                    Device_Type = $script:TestType.id
                    Site        = $script:TestSite.id
                    Status      = 'planned'
                }
            }

            $created = $devices | New-NBDCIMDevice -BatchSize 3 -Force

            $created | Should -Not -BeNullOrEmpty
            $created.Count | Should -Be 5

            # Track for cleanup
            $created | ForEach-Object { [void]$script:CreatedDevices.Add($_.id) }

            # Verify all devices were created correctly
            foreach ($device in $created) {
                $device.site.id | Should -Be $script:TestSite.id
                $device.role.id | Should -Be $script:TestRole.id
                $device.device_type.id | Should -Be $script:TestType.id
                $device.status.value | Should -Be 'planned'
            }

            Write-Host "  Created $($created.Count) devices" -ForegroundColor Green
        }

        It "Should create devices with interfaces" -Skip:$script:SkipDeviceTests {
            $timestamp = Get-Date -Format "yyyyMMddHHmmss"

            # Create device (use -Confirm:$false instead of -Force for single creation)
            $device = New-NBDCIMDevice `
                -Name "$($script:BulkPrefix)-IntfDevice-$timestamp" `
                -Role $script:TestRole.id `
                -Device_Type $script:TestType.id `
                -Site $script:TestSite.id `
                -Status 'active' `
                -Confirm:$false

            [void]$script:CreatedDevices.Add($device.id)

            # Create interfaces in bulk
            $interfaces = 0..3 | ForEach-Object {
                [PSCustomObject]@{
                    Device = $device.id
                    Name   = "eth$_"
                    Type   = '1000base-t'
                }
            }

            $createdInterfaces = $interfaces | New-NBDCIMInterface -Force

            $createdInterfaces | Should -Not -BeNullOrEmpty
            $createdInterfaces.Count | Should -Be 4

            # Track for cleanup
            $createdInterfaces | ForEach-Object { [void]$script:CreatedInterfaces.Add($_.id) }

            # Verify interfaces are linked to device
            foreach ($interface in $createdInterfaces) {
                $interface.device.id | Should -Be $device.id
            }

            Write-Host "  Created device with $($createdInterfaces.Count) interfaces" -ForegroundColor Green
        }
    }

    Context "Bulk Device Updates" {
        It "Should update multiple devices via pipeline" -Skip:$script:SkipDeviceTests {
            # Get devices created in previous tests
            $devices = Get-NBDCIMDevice -Name "$($script:BulkPrefix)*" -Status 'planned' -Limit 5

            if ($devices) {
                # Create update objects
                $updates = $devices | ForEach-Object {
                    [PSCustomObject]@{
                        Id     = $_.id
                        Status = 'active'
                    }
                }

                $updated = $updates | Set-NBDCIMDevice -Force

                $updated | Should -Not -BeNullOrEmpty
                $updated.Count | Should -Be $devices.Count

                # Verify status was updated
                foreach ($device in $updated) {
                    $device.status.value | Should -Be 'active'
                }

                Write-Host "  Updated $($updated.Count) devices to 'active'" -ForegroundColor Green
            }
            else {
                Set-ItResult -Skipped -Because "No 'planned' devices found to update"
            }
        }

        It "Should update device comments in batch" -Skip:$script:SkipDeviceTests {
            $devices = Get-NBDCIMDevice -Name "$($script:BulkPrefix)*" -Limit 3

            if ($devices) {
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $updates = $devices | ForEach-Object {
                    [PSCustomObject]@{
                        Id       = $_.id
                        Comments = "Bulk updated at $timestamp"
                    }
                }

                $updated = $updates | Set-NBDCIMDevice -Force

                foreach ($device in $updated) {
                    $device.comments | Should -Match $timestamp
                }

                Write-Host "  Updated comments on $($updated.Count) devices" -ForegroundColor Green
            }
            else {
                Set-ItResult -Skipped -Because "No bulk test devices found"
            }
        }
    }

    Context "Bulk Device Deletion" {
        It "Should delete multiple devices via pipeline" -Skip:$script:SkipDeviceTests {
            $timestamp = Get-Date -Format "yyyyMMddHHmmss"

            # Create temporary devices for deletion
            $tempDevices = 1..3 | ForEach-Object {
                [PSCustomObject]@{
                    Name        = "$($script:BulkPrefix)-TempDelete-$_-$timestamp"
                    Role        = $script:TestRole.id
                    Device_Type = $script:TestType.id
                    Site        = $script:TestSite.id
                }
            }

            $created = $tempDevices | New-NBDCIMDevice -Force

            $created.Count | Should -Be 3

            # Delete via pipeline
            { $created | Remove-NBDCIMDevice -Force } | Should -Not -Throw

            # Verify deletion
            foreach ($device in $created) {
                { Get-NBDCIMDevice -Id $device.id } | Should -Throw
            }

            Write-Host "  Deleted $($created.Count) devices" -ForegroundColor Green
        }
    }
}

Describe "Bulk IP Address Operations" -Tag 'Scenario', 'Bulk', 'IPAM' {
    Context "Bulk IP Address Creation" {
        It "Should create multiple IP addresses in sequence" {
            $timestamp = Get-Date -Format "yyyyMMddHHmmss"
            $baseOctet = Get-Random -Minimum 1 -Maximum 200

            $addresses = 1..10 | ForEach-Object {
                [PSCustomObject]@{
                    Address     = "10.99.$baseOctet.$_/32"
                    Status      = 'active'
                    Description = "$($script:BulkPrefix)-IP-$timestamp"
                }
            }

            $created = $addresses | New-NBIPAMAddress -BatchSize 5 -Force

            $created | Should -Not -BeNullOrEmpty
            $created.Count | Should -Be 10

            # Track for cleanup
            $created | ForEach-Object { [void]$script:CreatedAddresses.Add($_.id) }

            # Verify addresses were created
            foreach ($ip in $created) {
                $ip.status.value | Should -Be 'active'
                $ip.description | Should -Match $script:BulkPrefix
            }

            Write-Host "  Created $($created.Count) IP addresses" -ForegroundColor Green
        }

        It "Should create IP addresses with VRF assignment" {
            $vrf = Get-NBIPAMVRF -Query $script:Prefix -Limit 1 | Select-Object -First 1

            if ($vrf) {
                $timestamp = Get-Date -Format "yyyyMMddHHmmss"
                $baseOctet = Get-Random -Minimum 1 -Maximum 200

                $addresses = 1..5 | ForEach-Object {
                    [PSCustomObject]@{
                        Address     = "172.16.$baseOctet.$_/32"
                        Status      = 'reserved'
                        Vrf         = $vrf.id
                        Description = "$($script:BulkPrefix)-VRF-IP-$timestamp"
                    }
                }

                $created = $addresses | New-NBIPAMAddress -Force

                $created | Should -Not -BeNullOrEmpty

                # Track for cleanup
                $created | ForEach-Object { [void]$script:CreatedAddresses.Add($_.id) }

                foreach ($ip in $created) {
                    $ip.vrf.id | Should -Be $vrf.id
                }

                Write-Host "  Created $($created.Count) IP addresses in VRF '$($vrf.name)'" -ForegroundColor Green
            }
            else {
                Set-ItResult -Skipped -Because "No test VRFs found"
            }
        }
    }

    Context "Bulk IP Address Updates" {
        It "Should update IP address status in bulk" {
            # Use -Query for partial matching on description
            $addresses = Get-NBIPAMAddress -Query $script:BulkPrefix -Status 'active' -Limit 5

            if ($addresses) {
                $updates = $addresses | ForEach-Object {
                    [PSCustomObject]@{
                        Id     = $_.id
                        Status = 'reserved'
                    }
                }

                $updated = $updates | Set-NBIPAMAddress -Force

                foreach ($ip in $updated) {
                    $ip.status.value | Should -Be 'reserved'
                }

                Write-Host "  Updated $($updated.Count) IP addresses to 'reserved'" -ForegroundColor Green
            }
            else {
                Set-ItResult -Skipped -Because "No bulk test IP addresses found"
            }
        }
    }

    Context "Bulk IP Address Deletion" {
        It "Should delete IP addresses via pipeline" {
            $timestamp = Get-Date -Format "yyyyMMddHHmmss"
            $baseOctet = Get-Random -Minimum 1 -Maximum 200

            # Create temporary addresses
            $tempAddresses = 1..5 | ForEach-Object {
                [PSCustomObject]@{
                    Address     = "192.168.$baseOctet.$_/32"
                    Description = "$($script:BulkPrefix)-TempDelete-$timestamp"
                }
            }

            $created = $tempAddresses | New-NBIPAMAddress -Force

            # Delete via pipeline
            { $created | Remove-NBIPAMAddress -Force } | Should -Not -Throw

            Write-Host "  Deleted $($created.Count) IP addresses" -ForegroundColor Green
        }
    }
}

Describe "Bulk VM Operations" -Tag 'Scenario', 'Bulk', 'Virtualization' {
    BeforeAll {
        if (-not $script:TestCluster) {
            $script:SkipVMTests = $true
        }
        else {
            $script:SkipVMTests = $false
        }
    }

    Context "Bulk VM Creation" {
        It "Should create multiple VMs via pipeline" -Skip:$script:SkipVMTests {
            $timestamp = Get-Date -Format "yyyyMMddHHmmss"

            $vms = 1..5 | ForEach-Object {
                [PSCustomObject]@{
                    Name    = "$($script:BulkPrefix)-VM-$_-$timestamp"
                    Cluster = $script:TestCluster.id
                    VCPUs   = Get-Random -Minimum 1 -Maximum 8
                    Memory  = (Get-Random -Minimum 1 -Maximum 16) * 1024
                    Status  = 'active'
                }
            }

            $created = $vms | New-NBVirtualMachine -BatchSize 3 -Force

            $created | Should -Not -BeNullOrEmpty
            $created.Count | Should -Be 5

            # Track for cleanup
            $created | ForEach-Object { [void]$script:CreatedVMs.Add($_.id) }

            foreach ($vm in $created) {
                $vm.cluster.id | Should -Be $script:TestCluster.id
                $vm.status.value | Should -Be 'active'
            }

            Write-Host "  Created $($created.Count) VMs in cluster '$($script:TestCluster.name)'" -ForegroundColor Green
        }

        It "Should create VMs with varying specs" -Skip:$script:SkipVMTests {
            $timestamp = Get-Date -Format "yyyyMMddHHmmss"

            $vmSpecs = @(
                @{ Name = "$($script:BulkPrefix)-Small-$timestamp"; VCPUs = 1; Memory = 1024 }
                @{ Name = "$($script:BulkPrefix)-Medium-$timestamp"; VCPUs = 2; Memory = 4096 }
                @{ Name = "$($script:BulkPrefix)-Large-$timestamp"; VCPUs = 4; Memory = 8192 }
            )

            $vms = $vmSpecs | ForEach-Object {
                [PSCustomObject]@{
                    Name    = $_.Name
                    Cluster = $script:TestCluster.id
                    VCPUs   = $_.VCPUs
                    Memory  = $_.Memory
                }
            }

            $created = $vms | New-NBVirtualMachine -Force

            # Track for cleanup
            $created | ForEach-Object { [void]$script:CreatedVMs.Add($_.id) }

            # Verify specs
            $smallVM = $created | Where-Object { $_.name -match 'Small' }
            $smallVM.vcpus | Should -Be 1
            $smallVM.memory | Should -Be 1024

            $largeVM = $created | Where-Object { $_.name -match 'Large' }
            $largeVM.vcpus | Should -Be 4
            $largeVM.memory | Should -Be 8192

            Write-Host "  Created VMs with varying specs" -ForegroundColor Green
        }
    }

    Context "Bulk VM Updates" {
        It "Should update VM resources in bulk" -Skip:$script:SkipVMTests {
            $vms = Get-NBVirtualMachine -Name "$($script:BulkPrefix)*" -Limit 3

            if ($vms) {
                $updates = $vms | ForEach-Object {
                    [PSCustomObject]@{
                        Id     = $_.id
                        VCPUs  = 4
                        Memory = 8192
                    }
                }

                $updated = $updates | Set-NBVirtualMachine -Force

                foreach ($vm in $updated) {
                    $vm.vcpus | Should -Be 4
                    $vm.memory | Should -Be 8192
                }

                Write-Host "  Updated resources on $($updated.Count) VMs" -ForegroundColor Green
            }
            else {
                Set-ItResult -Skipped -Because "No bulk test VMs found"
            }
        }
    }
}

Describe "Mixed Pipeline Operations" -Tag 'Scenario', 'Bulk', 'Pipeline' {
    Context "Complex Pipeline Workflows" {
        It "Should chain operations: Create Device -> Add Interfaces -> Assign IPs" {
            if (-not $script:TestSite -or -not $script:TestRole -or -not $script:TestType) {
                Set-ItResult -Skipped -Because "Missing test prerequisites"
                return
            }

            $timestamp = Get-Date -Format "yyyyMMddHHmmss"

            # Step 1: Create device
            $device = New-NBDCIMDevice `
                -Name "$($script:BulkPrefix)-Pipeline-$timestamp" `
                -Role $script:TestRole.id `
                -Device_Type $script:TestType.id `
                -Site $script:TestSite.id `
                -Status 'active' `
                -Confirm:$false

            [void]$script:CreatedDevices.Add($device.id)

            # Step 2: Create interfaces
            $interfaces = 0..1 | ForEach-Object {
                [PSCustomObject]@{
                    Device = $device.id
                    Name   = "eth$_"
                    Type   = '1000base-t'
                }
            } | New-NBDCIMInterface -Force

            $interfaces | ForEach-Object { [void]$script:CreatedInterfaces.Add($_.id) }

            # Step 3: Assign IP addresses to interfaces
            $baseOctet = Get-Random -Minimum 1 -Maximum 200

            $ipAddresses = $interfaces | ForEach-Object -Begin { $i = 0 } -Process {
                $i++
                [PSCustomObject]@{
                    Address              = "10.100.$baseOctet.$i/24"
                    Status               = 'active'
                    Assigned_Object_Type = 'dcim.interface'
                    Assigned_Object_Id   = $_.id
                    Description          = "$($script:BulkPrefix)-Pipeline-IP"
                }
            } | New-NBIPAMAddress -Force

            $ipAddresses | ForEach-Object { [void]$script:CreatedAddresses.Add($_.id) }

            # Verify complete chain
            $ipAddresses.Count | Should -Be 2
            foreach ($ip in $ipAddresses) {
                $ip.assigned_object.device.id | Should -Be $device.id
            }

            Write-Host "  Pipeline: Device -> 2 Interfaces -> 2 IPs" -ForegroundColor Green
        }

        It "Should process mixed object types in sequence" {
            if (-not $script:TestSite -or -not $script:TestCluster) {
                Set-ItResult -Skipped -Because "Missing test prerequisites"
                return
            }

            $timestamp = Get-Date -Format "yyyyMMddHHmmss"

            # Create device
            $device = New-NBDCIMDevice `
                -Name "$($script:BulkPrefix)-Mixed-Device-$timestamp" `
                -Role $script:TestRole.id `
                -Device_Type $script:TestType.id `
                -Site $script:TestSite.id `
                -Confirm:$false

            [void]$script:CreatedDevices.Add($device.id)

            # Create VM in same operation batch
            $vm = New-NBVirtualMachine `
                -Name "$($script:BulkPrefix)-Mixed-VM-$timestamp" `
                -Cluster $script:TestCluster.id `
                -Confirm:$false

            [void]$script:CreatedVMs.Add($vm.id)

            # Create IP addresses for both
            $baseOctet = Get-Random -Minimum 1 -Maximum 200
            $ips = 1..2 | ForEach-Object {
                [PSCustomObject]@{
                    Address     = "10.101.$baseOctet.$_/32"
                    Description = "$($script:BulkPrefix)-Mixed-$timestamp"
                }
            } | New-NBIPAMAddress -Force

            $ips | ForEach-Object { [void]$script:CreatedAddresses.Add($_.id) }

            # Verify
            $device | Should -Not -BeNullOrEmpty
            $vm | Should -Not -BeNullOrEmpty
            $ips.Count | Should -Be 2

            Write-Host "  Created mixed resources: 1 Device, 1 VM, 2 IPs" -ForegroundColor Green
        }
    }
}

Describe "Batch Size Performance" -Tag 'Scenario', 'Bulk', 'Performance' {
    Context "Batch Size Variations" {
        It "Should handle batch size 1 (many API calls)" {
            $timestamp = Get-Date -Format "yyyyMMddHHmmss"
            $baseOctet = Get-Random -Minimum 1 -Maximum 200

            $addresses = 1..5 | ForEach-Object {
                [PSCustomObject]@{
                    Address     = "10.102.$baseOctet.$_/32"
                    Description = "$($script:BulkPrefix)-BatchSize1-$timestamp"
                }
            }

            $startTime = Get-Date
            $created = $addresses | New-NBIPAMAddress -BatchSize 1 -Force
            $duration = (Get-Date) - $startTime

            $created | ForEach-Object { [void]$script:CreatedAddresses.Add($_.id) }

            $created.Count | Should -Be 5

            Write-Host "  BatchSize 1: $($created.Count) items in $($duration.TotalSeconds.ToString('F2'))s" -ForegroundColor Gray
        }

        It "Should handle large batch size (few API calls)" {
            $timestamp = Get-Date -Format "yyyyMMddHHmmss"
            $baseOctet = Get-Random -Minimum 1 -Maximum 200

            $addresses = 1..10 | ForEach-Object {
                [PSCustomObject]@{
                    Address     = "10.103.$baseOctet.$_/32"
                    Description = "$($script:BulkPrefix)-LargeBatch-$timestamp"
                }
            }

            $startTime = Get-Date
            $created = $addresses | New-NBIPAMAddress -BatchSize 100 -Force
            $duration = (Get-Date) - $startTime

            $created | ForEach-Object { [void]$script:CreatedAddresses.Add($_.id) }

            $created.Count | Should -Be 10

            Write-Host "  BatchSize 100: $($created.Count) items in $($duration.TotalSeconds.ToString('F2'))s" -ForegroundColor Gray
        }
    }
}
