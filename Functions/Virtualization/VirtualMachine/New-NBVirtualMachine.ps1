<#
.SYNOPSIS
    Creates one or more virtual machines in Netbox Virtualization module.

.DESCRIPTION
    Creates new virtual machines in Netbox. Supports both single VM
    creation with individual parameters and bulk creation via pipeline input.

    For bulk operations, use the -BatchSize parameter to control how many
    VMs are sent per API request. This significantly improves performance
    when importing VMs from vCenter or other sources.

.PARAMETER Name
    The name of the virtual machine. Required for single VM creation.

.PARAMETER Site
    The site ID. Optional in Netbox 4.x.

.PARAMETER Cluster
    The cluster ID. Optional - VMs can be standalone in Netbox 4.x.

.PARAMETER Device
    The device ID to attach this VM to (NetBox 4.6+). Allows a clusterless,
    device-bound VM.

.PARAMETER Virtual_Machine_Type
    The virtual machine type ID (NetBox 4.6+).

.PARAMETER Tenant
    The tenant ID.

.PARAMETER Status
    Status of the VM. Defaults to 'Active'.

.PARAMETER Role
    The role ID for the VM.

.PARAMETER Platform
    The platform ID (e.g., VMware, Hyper-V).

.PARAMETER vCPUs
    Number of virtual CPUs.

.PARAMETER Memory
    Memory in MB.

.PARAMETER Disk
    Disk space in GB.

.PARAMETER Primary_IP4
    Primary IPv4 address ID.

.PARAMETER Primary_IP6
    Primary IPv6 address ID.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Comments
    Comments about the VM.

.PARAMETER Start_On_Boot
    Boot behavior for the VM (Netbox 4.5+ only).
    Values: 'on', 'off', 'laststate'

.PARAMETER InputObject
    Pipeline input for bulk operations. Each object should contain
    at minimum the Name property.

.PARAMETER BatchSize
    Number of VMs to create per API request in bulk mode.
    Default: 50, Range: 1-1000

.PARAMETER Force
    Skip confirmation prompts for bulk operations.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBVirtualMachine -Name "webserver01" -Cluster 1 -vCPUs 4 -Memory 8192

    Creates a single VM with 4 vCPUs and 8GB RAM.

.EXAMPLE
    $vms = Get-VM | ForEach-Object {
        [PSCustomObject]@{
            Name = $_.Name
            Cluster = 1
            vCPUs = $_.NumCpu
            Memory = $_.MemoryMB
            Disk = [math]::Round($_.UsedSpaceGB)
            Status = 'active'
        }
    }
    $vms | New-NBVirtualMachine -BatchSize 100 -Force

    Imports VMs from VMware vCenter in bulk.

.LINK
    https://netbox.readthedocs.io/en/stable/models/virtualization/virtualmachine/
.NOTES
    AddedInVersion: v1.0.4

#>

function New-NBVirtualMachine {
    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'Low',
        DefaultParameterSetName = 'Single')]
    [OutputType([PSCustomObject])]
    param(
        # Single mode parameters
        [Parameter(ParameterSetName = 'Single', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Site,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Cluster,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Device,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Virtual_Machine_Type,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Tenant,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('offline', 'active', 'planned', 'staged', 'failed', 'decommissioning', 'paused', IgnoreCase = $true)]
        [string]$Status = 'active',

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Role,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Platform,

        [Parameter(ParameterSetName = 'Single')]
        [uint16]$vCPUs,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Memory,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Disk,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Primary_IP4,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Primary_IP6,

        [Parameter(ParameterSetName = 'Single')]
        [hashtable]$Custom_Fields,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Comments,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('on', 'off', 'laststate', IgnoreCase = $true)]
        [string]$Start_On_Boot,

        # Bulk mode parameters
        [Parameter(ParameterSetName = 'Bulk', Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]$InputObject,

        [Parameter(ParameterSetName = 'Bulk')]
        [ValidateRange(1, 1000)]
        [int]$BatchSize = 100,

        [Parameter(ParameterSetName = 'Bulk')]
        [switch]$Force,

        # Common parameters
        [Parameter()]

        [object[]]$Tags,

        [switch]$Raw
    )

    begin {
        $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'virtual-machines'))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ParameterSetName -eq 'Bulk') {
            $bulkItems = [System.Collections.ArrayList]::new()
        }
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Single') {
            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

            if ($PSCmdlet.ShouldProcess($Name, 'Create new Virtual Machine')) {
                InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
            }
        }
        else {
            # Bulk mode - collect items
            if ($InputObject) {
                $item = @{}
                foreach ($prop in $InputObject.PSObject.Properties) {
                    $key = $prop.Name.ToLower()
                    $value = $prop.Value

                    # Handle property name mappings
                    switch ($key) {
                        'device_role' { $key = 'role' }  # Backwards compatibility
                    }

                    $item[$key] = $value
                }
                [void]$bulkItems.Add([PSCustomObject]$item)
            }
        }
    }

    end {
        if ($PSCmdlet.ParameterSetName -eq 'Bulk' -and $bulkItems.Count -gt 0) {
            $target = "$($bulkItems.Count) virtual machine(s)"

            if ($Force -or $PSCmdlet.ShouldProcess($target, 'Create virtual machines (bulk)')) {
                Write-Verbose "Processing $($bulkItems.Count) VMs in bulk mode with batch size $BatchSize"

                $bulkParams = @{
                    URI          = $URI
                    Items        = $bulkItems.ToArray()
                    Method       = 'POST'
                    BatchSize    = $BatchSize
                    ShowProgress = $true
                    ActivityName = 'Creating virtual machines'
                }
                $result = Send-NBBulkRequest @bulkParams

                # Output succeeded items to pipeline
                foreach ($item in $result.Succeeded) {
                    Write-Output $item
                }

                # Write errors for failed items
                foreach ($failure in $result.Failed) {
                    Write-Error "Failed to create VM: $($failure.Error)" -TargetObject $failure.Item
                }

                # Write summary
                if ($result.HasErrors) {
                    Write-Warning $result.GetSummary()
                }
                else {
                    Write-Verbose $result.GetSummary()
                }
            }
        }
    }
}
