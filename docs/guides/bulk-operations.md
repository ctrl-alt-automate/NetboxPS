# Bulk Operations

PowerNetbox supports high-performance bulk operations for creating, updating, and deleting multiple resources in a single API request. This significantly improves performance when working with large datasets.

## Overview

Bulk operations use Netbox's native bulk API endpoints, which process arrays of objects in batches. This is much faster than making individual API calls for each resource.

### Supported Functions

| Function | Operation | Description |
|----------|-----------|-------------|
| `New-NBDCIMDevice` | POST | Create multiple devices |
| `New-NBDCIMInterface` | POST | Create multiple device interfaces |
| `New-NBIPAMAddress` | POST | Create multiple IP addresses |
| `New-NBIPAMPrefix` | POST | Create multiple IP prefixes |
| `New-NBIPAMVLAN` | POST | Create multiple VLANs |
| `New-NBVirtualMachine` | POST | Create multiple VMs |
| `New-NBVirtualMachineInterface` | POST | Create multiple VM interfaces |
| `Set-NBDCIMDevice` | PATCH | Update multiple devices |
| `Remove-NBDCIMDevice` | DELETE | Delete multiple devices |

### Common Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-InputObject` | PSCustomObject | - | Pipeline input for bulk mode |
| `-BatchSize` | int (1-1000) | 50 | Items per API request |
| `-Force` | switch | - | Skip confirmation prompts |

## Basic Usage

### Bulk Create Devices

```powershell
# Create objects with required properties
$devices = 1..10 | ForEach-Object {
    [PSCustomObject]@{
        Name        = "server-$_"
        Role        = 1           # Device role ID
        Device_Type = 1           # Device type ID
        Site        = 1           # Site ID
        Status      = "planned"
    }
}

# Pipe to function with -Force to skip prompts
$created = $devices | New-NBDCIMDevice -BatchSize 5 -Force

# View results
$created | Select-Object id, name, status
```

### Bulk Create VLANs

```powershell
# Create VLAN range 100-199
$vlans = 100..199 | ForEach-Object {
    [PSCustomObject]@{
        VID    = $_
        Name   = "VLAN$_"
        Status = "active"
        Site   = 1
    }
}

$vlans | New-NBIPAMVLAN -BatchSize 50 -Force
```

### Bulk Create IP Addresses

```powershell
# Create all IPs in a /24 subnet
$addresses = 1..254 | ForEach-Object {
    [PSCustomObject]@{
        Address     = "192.168.1.$_/24"
        Status      = "active"
        Description = "Host $_"
    }
}

$addresses | New-NBIPAMAddress -BatchSize 100 -Force
```

### Bulk Create VM Interfaces

```powershell
# Get all VMs in a cluster
$vms = Get-NBVirtualMachine -Cluster 1

# Create eth0 interface for each VM
$interfaces = $vms | ForEach-Object {
    [PSCustomObject]@{
        Virtual_Machine = $_.id
        Name            = "eth0"
        Enabled         = $true
        Description     = "Primary interface"
    }
}

$interfaces | New-NBVirtualMachineInterface -BatchSize 50 -Force
```

## Bulk Update

### Update Device Status

```powershell
# Get devices to update
$devices = Get-NBDCIMDevice -Status "planned"

# Create update objects (must include Id)
$updates = $devices | ForEach-Object {
    [PSCustomObject]@{
        Id       = $_.id
        Status   = "active"
        Comments = "Deployed on $(Get-Date -Format 'yyyy-MM-dd')"
    }
}

# Bulk update
$updated = $updates | Set-NBDCIMDevice -BatchSize 50 -Force

Write-Host "Updated $($updated.Count) devices"
```

### Update Multiple Properties

```powershell
# Update devices with multiple changes
$updates = @(
    [PSCustomObject]@{ Id = 100; Status = "active"; Serial = "SN001" }
    [PSCustomObject]@{ Id = 101; Status = "active"; Serial = "SN002" }
    [PSCustomObject]@{ Id = 102; Status = "staged"; Serial = "SN003" }
)

$updates | Set-NBDCIMDevice -Force
```

## Bulk Delete

### Delete by Status

```powershell
# Get decommissioned devices
$toDelete = Get-NBDCIMDevice -Status "decommissioning"

# Bulk delete (WARNING: This cannot be undone!)
$toDelete | Remove-NBDCIMDevice -BatchSize 50 -Force
```

### Delete by Query

```powershell
# Delete all test devices
Get-NBDCIMDevice -Name "test-*" | Remove-NBDCIMDevice -Force
```

## CSV Import

### Import Devices from CSV

```csv
Name,Role,Device_Type,Site,Status,Serial
server-01,1,1,1,active,SN001
server-02,1,1,1,active,SN002
server-03,1,1,1,planned,SN003
```

```powershell
Import-Csv devices.csv | New-NBDCIMDevice -BatchSize 100 -Force
```

### Import VLANs from CSV

```csv
VID,Name,Status,Site,Description
100,Management,active,1,Management VLAN
101,Production,active,1,Production servers
102,DMZ,active,1,DMZ network
```

```powershell
Import-Csv vlans.csv | New-NBIPAMVLAN -BatchSize 50 -Force
```

### Import Prefixes from CSV

```csv
Prefix,Status,Site,Description,Is_Pool
10.0.0.0/24,active,1,Server network,false
10.0.1.0/24,active,1,Client network,false
10.0.2.0/24,container,1,DHCP pool,true
```

```powershell
Import-Csv prefixes.csv | New-NBIPAMPrefix -BatchSize 50 -Force
```

## Error Handling

Bulk operations track successes and failures individually:

```powershell
# Capture results
$result = $items | New-NBDCIMDevice -BatchSize 50 -Force

# Check for errors in output
if ($Error.Count -gt 0) {
    Write-Host "Some items failed:" -ForegroundColor Yellow
    $Error | ForEach-Object { Write-Host $_.Exception.Message }
}

# Successful items are output to pipeline
Write-Host "Successfully created: $($result.Count) devices"
```

### Verbose Output

```powershell
# Use -Verbose to see batch progress
$items | New-NBDCIMDevice -BatchSize 50 -Force -Verbose
```

### Automatic 500 Error Recovery (v4.4.9.3+)

When a bulk batch fails with a 500 Internal Server Error, PowerNetbox automatically falls back to sequential processing with exponential backoff retry. This provides resilience against transient server errors that can occur when referencing recently created objects.

**What happens automatically:**
1. Batch fails with 500 error
2. Waits 3 seconds for server to stabilize
3. Retries each item individually with delays (500ms → 1s → 2s)
4. Up to 3 retry attempts per item
5. Items that succeed are tracked; permanent failures are reported

```powershell
# Resilient chain: create devices → interfaces → IPs
# Even if bulk batch fails, each item is retried individually
$devices = 1..5 | ForEach-Object {
    [PSCustomObject]@{ Name = "server-$_"; Role = 1; Device_Type = 1; Site = 1 }
} | New-NBDCIMDevice -Force

# Reference newly created devices (resilient to 500 errors)
$interfaces = $devices | ForEach-Object {
    [PSCustomObject]@{ Device = $_.id; Name = "eth0"; Type = "1000base-t" }
} | New-NBDCIMInterface -Force
```

**Note**: This fallback is transparent - you don't need to change your code. The module handles recovery automatically.

## Performance Tips

### Optimal Batch Size

| Item Count | Recommended BatchSize | API Calls |
|------------|----------------------|-----------|
| 1-50 | 50 (default) | 1 |
| 51-200 | 50 | 1-4 |
| 201-1000 | 100 | 3-10 |
| 1000+ | 200-500 | 5+ |

```powershell
# For large imports, increase batch size
Import-Csv large-dataset.csv | New-NBDCIMDevice -BatchSize 200 -Force
```

### Parallel Processing

For very large datasets, split into chunks and process in parallel:

```powershell
# Split into 4 chunks for parallel processing
$items = Import-Csv huge-dataset.csv
$chunks = [System.Collections.ArrayList]@()
$chunkSize = [math]::Ceiling($items.Count / 4)

for ($i = 0; $i -lt $items.Count; $i += $chunkSize) {
    [void]$chunks.Add($items[$i..([math]::Min($i + $chunkSize - 1, $items.Count - 1))])
}

# Process chunks in parallel (PowerShell 7+)
$chunks | ForEach-Object -Parallel {
    Import-Module PowerNetbox
    Connect-NBAPI -Hostname $using:NetboxHost -Credential $using:cred
    $_ | New-NBDCIMDevice -BatchSize 100 -Force
} -ThrottleLimit 4
```

## Real-World Examples

### Provision Rack of Servers

```powershell
# Define server template
$rackId = 1
$siteId = 1
$roleId = 1  # Server role
$typeId = 1  # Server type

# Create 42U worth of servers
$servers = 1..42 | ForEach-Object {
    [PSCustomObject]@{
        Name        = "rack01-u$_"
        Role        = $roleId
        Device_Type = $typeId
        Site        = $siteId
        Rack        = $rackId
        Position    = $_
        Face        = "front"
        Status      = "planned"
    }
}

$created = $servers | New-NBDCIMDevice -BatchSize 20 -Force
Write-Host "Provisioned $($created.Count) servers in rack"
```

### Create VLAN Structure per Site

```powershell
$sites = Get-NBDCIMSite

foreach ($site in $sites) {
    # Standard VLAN template per site
    $vlans = @(
        @{ VID = 10; Name = "Management"; Description = "Management network" }
        @{ VID = 20; Name = "Servers"; Description = "Server network" }
        @{ VID = 30; Name = "Clients"; Description = "Client network" }
        @{ VID = 40; Name = "Voice"; Description = "VoIP network" }
        @{ VID = 99; Name = "Native"; Description = "Native VLAN" }
    ) | ForEach-Object {
        [PSCustomObject]@{
            VID         = $_.VID
            Name        = "$($site.name)-$($_.Name)"
            Site        = $site.id
            Status      = "active"
            Description = $_.Description
        }
    }

    $vlans | New-NBIPAMVLAN -Force
    Write-Host "Created VLANs for site: $($site.name)"
}
```

### Decommission Old Devices

```powershell
# Find devices older than 5 years (using custom field)
$oldDevices = Get-NBDCIMDevice | Where-Object {
    $_.custom_fields.install_date -and
    ([datetime]$_.custom_fields.install_date) -lt (Get-Date).AddYears(-5)
}

# Update status to decommissioning
$updates = $oldDevices | ForEach-Object {
    [PSCustomObject]@{
        Id       = $_.id
        Status   = "decommissioning"
        Comments = "Scheduled for decommission - age > 5 years"
    }
}

$updates | Set-NBDCIMDevice -Force

Write-Host "Marked $($updates.Count) devices for decommissioning"
```

### Migrate VMs Between Clusters

```powershell
$sourceCluster = 1
$targetCluster = 2

# Get VMs from source cluster
$vms = Get-NBVirtualMachine -Cluster $sourceCluster

# Create update objects
$updates = $vms | ForEach-Object {
    [PSCustomObject]@{
        Id      = $_.id
        Cluster = $targetCluster
    }
}

# Bulk migrate
$updates | Set-NBVirtualMachine -Force

Write-Host "Migrated $($updates.Count) VMs to new cluster"
```

## Comparison: Single vs Bulk

### Without Bulk (Slow)

```powershell
# 100 API calls - one per device
Measure-Command {
    1..100 | ForEach-Object {
        New-NBDCIMDevice -Name "server-$_" -Role 1 -Device_Type 1 -Site 1
    }
}
# Time: ~60 seconds
```

### With Bulk (Fast)

```powershell
# 2 API calls - batched
Measure-Command {
    $devices = 1..100 | ForEach-Object {
        [PSCustomObject]@{ Name = "server-$_"; Role = 1; Device_Type = 1; Site = 1 }
    }
    $devices | New-NBDCIMDevice -BatchSize 50 -Force
}
# Time: ~2 seconds (30x faster!)
```

## See Also

- [Common Workflows](common-workflows.md) - General workflow examples
- [DCIM Examples](dcim-examples.md) - Device management examples
- [IPAM Examples](ipam-examples.md) - IP address management examples

## Background Processing (NetBox 4.7+)

Add `-Background` to any bulk-capable cmdlet to queue each batch as a NetBox background job instead of waiting for the synchronous response:

```powershell
$result = $devices | New-NBDCIMDevice -BatchSize 500 -Background -Force
$result.Succeeded | ForEach-Object { Get-NBJob -Id $_.id }     # the returned items are job objects
```

- NetBox answers `202 Accepted` with the job; validation runs in the worker, so inspect the job status for the real outcome.
- Requires NetBox 4.7+ and a running RQ worker. On older servers the switch warns and the batch is processed synchronously.
- `docker compose --profile worker` starts a worker in the local test stack.

## Partial Tag Updates

`Set-NBObjectTag` adds or removes tags on any object without resending its whole tag list (NetBox 4.6+):

```powershell
Get-NBDCIMDevice -Tag 'staging' | Set-NBObjectTag -Add 'production' -Remove 'staging'
```
