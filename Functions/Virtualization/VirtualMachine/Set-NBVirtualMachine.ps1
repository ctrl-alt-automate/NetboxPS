<#
.SYNOPSIS
    Updates one or more virtual machines in Netbox Virtualization module.

.DESCRIPTION
    Updates existing virtual machines in Netbox Virtualization module. Supports both
    single VM updates with individual parameters and bulk updates via pipeline input.

    For bulk operations, use the -BatchSize parameter to control how many
    VMs are sent per API request. Each object must have an Id property.

.PARAMETER Id
    The database ID of the virtual machine to update. Required for single updates.

.PARAMETER Name
    The new name for the VM.

.PARAMETER Role
    The device role ID.

.PARAMETER Cluster
    The cluster ID.

.PARAMETER Device
    The device ID to attach this VM to (NetBox 4.6+). Pass $null to clear.

.PARAMETER Virtual_Machine_Type
    The virtual machine type ID (NetBox 4.6+). Pass $null to clear.

.PARAMETER Status
    Status of the VM.

.PARAMETER Platform
    The platform ID.

.PARAMETER Primary_IP4
    The primary IPv4 address ID.

.PARAMETER Primary_IP6
    The primary IPv6 address ID.

.PARAMETER VCPUs
    Number of virtual CPUs.

.PARAMETER Memory
    Memory in MB.

.PARAMETER Disk
    Disk size in GB.

.PARAMETER Tenant
    The tenant ID.

.PARAMETER Comments
    Comments about the VM.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Start_On_Boot
    Boot behavior for the VM (Netbox 4.5+ only).
    Values: 'on', 'off', 'laststate'

.PARAMETER InputObject
    Pipeline input for bulk operations. Each object MUST have an Id property.

.PARAMETER BatchSize
    Number of VMs to update per API request in bulk mode.
    Default: 50, Range: 1-1000

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    Set-NBVirtualMachine -Id 123 -Status "active"

    Updates VM 123 to active status.

.EXAMPLE
    Get-NBVirtualMachine -Status "offline" | ForEach-Object {
        [PSCustomObject]@{Id = $_.id; Status = "active"}
    } | Set-NBVirtualMachine -Force

    Bulk update all offline VMs to active status.

.EXAMPLE
    $updates = @(
        [PSCustomObject]@{Id = 100; Status = "active"; Comments = "Migrated"}
        [PSCustomObject]@{Id = 101; Status = "active"; Comments = "Migrated"}
    )
    $updates | Set-NBVirtualMachine -BatchSize 50 -Force

    Bulk update multiple VMs with different values.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v1.0.4

#>

function Set-NBVirtualMachine {
    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium',
        DefaultParameterSetName = 'Single')]
    [OutputType([PSCustomObject])]
    param(
        # Single mode parameters
        [Parameter(ParameterSetName = 'Single', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Role,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Cluster,

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[uint64]]$Device,

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[uint64]]$Virtual_Machine_Type,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('offline', 'active', 'planned', 'staged', 'failed', 'decommissioning', 'paused', IgnoreCase = $true)]
        [string]$Status,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Platform,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Primary_IP4,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Primary_IP6,

        [Parameter(ParameterSetName = 'Single')]
        [uint16]$VCPUs,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Memory,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Disk,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Tenant,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Comments,

        [Parameter(ParameterSetName = 'Single')]
        [hashtable]$Custom_Fields,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('on', 'off', 'laststate', IgnoreCase = $true)]
        [string]$Start_On_Boot,

        # Bulk mode parameters
        [Parameter(ParameterSetName = 'Bulk', Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]$InputObject,

        [Parameter(ParameterSetName = 'Bulk')]
        [ValidateRange(1, 1000)]
        [int]$BatchSize = 100,

        # Common parameters
        [Parameter()]
        [switch]$Force,

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
            $VMSegments = [System.Collections.ArrayList]::new(@('virtualization', 'virtual-machines', $Id))

            if ($Force -or $PSCmdlet.ShouldProcess($Id, "Update virtual machine")) {
                $URIComponents = BuildURIComponents -URISegments $VMSegments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force', 'Raw'

                $VMURI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $VMURI -Body $URIComponents.Parameters -Method PATCH -Raw:$Raw
            }
        }
        else {
            # Bulk mode - collect items
            if ($InputObject) {
                # Validate that Id is present
                $itemId = if ($InputObject.Id) { $InputObject.Id }
                          elseif ($InputObject.id) { $InputObject.id }
                          else { $null }

                if (-not $itemId) {
                    Write-Error "InputObject must have an 'Id' property for bulk updates" -TargetObject $InputObject
                    return
                }

                $item = @{}
                foreach ($prop in $InputObject.PSObject.Properties) {
                    $key = $prop.Name.ToLower()
                    $value = $prop.Value

                    $item[$key] = $value
                }
                [void]$bulkItems.Add([PSCustomObject]$item)
            }
        }
    }

    end {
        if ($PSCmdlet.ParameterSetName -eq 'Bulk' -and $bulkItems.Count -gt 0) {
            $target = "$($bulkItems.Count) virtual machine(s)"

            if ($Force -or $PSCmdlet.ShouldProcess($target, 'Update virtual machines (bulk)')) {
                Write-Verbose "Processing $($bulkItems.Count) VMs in bulk PATCH mode with batch size $BatchSize"

                $bulkParams = @{
                    URI          = $URI
                    Items        = $bulkItems.ToArray()
                    Method       = 'PATCH'
                    BatchSize    = $BatchSize
                    ShowProgress = $true
                    ActivityName = 'Updating virtual machines'
                }
                $result = Send-NBBulkRequest @bulkParams

                # Output succeeded items to pipeline
                foreach ($item in $result.Succeeded) {
                    Write-Output $item
                }

                # Write errors for failed items
                foreach ($failure in $result.Failed) {
                    Write-Error "Failed to update VM: $($failure.Error)" -TargetObject $failure.Item
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
