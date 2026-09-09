<#
.SYNOPSIS
    Deletes one or more devices from Netbox DCIM module.

.DESCRIPTION
    Deletes devices from Netbox by ID. Supports both single device deletion
    and bulk deletion via pipeline input.

    For bulk operations, use the -BatchSize parameter to control how many
    devices are deleted per API request.

    WARNING: This operation cannot be undone. Deleted devices and their
    associated data (interfaces, connections, etc.) will be permanently removed.

.PARAMETER Id
    Database ID(s) of the device(s) to delete. Required for single mode.

.PARAMETER InputObject
    Pipeline input for bulk operations. Each object must have an Id property.

.PARAMETER BatchSize
    Number of devices to delete per API request in bulk mode.
    Default: 50, Range: 1-1000

.PARAMETER Background
    Netbox 4.7+: queue each bulk batch as a background job (?background=true) instead of processing it
    synchronously; the returned items are the job objects (check them with Get-NBJob). Ignored with a
    warning on older Netbox versions. Only meaningful together with -BatchSize pipeline input.
.PARAMETER Force
    Skip confirmation prompts. Use with caution!

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Remove-NBDCIMDevice -Id 123 -Force

    Deletes device 123 without confirmation.

.EXAMPLE
    Remove-NBDCIMDevice -Id 100, 101, 102 -Force

    Deletes multiple devices by ID.

.EXAMPLE
    Get-NBDCIMDevice -Status "decommissioning" | Remove-NBDCIMDevice -Force

    Bulk delete all devices in decommissioning status.

.EXAMPLE
    Get-NBDCIMDevice -Query "temp-*" | Remove-NBDCIMDevice -BatchSize 50 -Force

    Bulk delete devices matching a pattern with batching.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v1.0.4

#>

function Remove-NBDCIMDevice {
    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'High',
        DefaultParameterSetName = 'Single')]
    [OutputType([void])]
    param(
        # Single mode parameters
        [Parameter(ParameterSetName = 'Single', Mandatory = $true)]
        [uint64]$Id,

        # Bulk mode parameters
        [Parameter(ParameterSetName = 'Bulk', Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]$InputObject,

        [Parameter(ParameterSetName = 'Bulk')]
        [ValidateRange(1, 1000)]
        [int]$BatchSize = 100,

        [switch]$Background,

        # Common parameters
        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [switch]$Raw
    )

    begin {
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'devices'))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ParameterSetName -eq 'Bulk') {
            $bulkItems = [System.Collections.ArrayList]::new()
        }
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Single') {
            # Use Id directly - no need to fetch device first (saves an API call per delete)
            if ($Force -or $PSCmdlet.ShouldProcess("Device ID $Id", "Delete device")) {
                $DeviceSegments = [System.Collections.ArrayList]::new(@('dcim', 'devices', $Id))

                $DeviceURI = BuildNewURI -Segments $DeviceSegments

                InvokeNetboxRequest -URI $DeviceURI -Method DELETE -Raw:$Raw
            }
        }
        else {
            # Bulk mode - collect items
            if ($InputObject) {
                # Extract Id from object
                $itemId = if ($InputObject.Id) { $InputObject.Id }
                          elseif ($InputObject.id) { $InputObject.id }
                          else { $null }

                if (-not $itemId) {
                    Write-Error "InputObject must have an 'Id' property for bulk delete" -TargetObject $InputObject
                    return
                }

                # Netbox bulk DELETE expects array of objects with 'id'
                [void]$bulkItems.Add([PSCustomObject]@{ id = $itemId })
            }
        }
    }

    end {
        if ($PSCmdlet.ParameterSetName -eq 'Bulk' -and $bulkItems.Count -gt 0) {
            $target = "$($bulkItems.Count) device(s) - THIS CANNOT BE UNDONE!"

            if ($Force -or $PSCmdlet.ShouldProcess($target, 'Delete devices (bulk)')) {
                Write-Verbose "Processing $($bulkItems.Count) devices in bulk DELETE mode with batch size $BatchSize"

                $useBackground = $Background -and -not (Test-NBMinimumVersion -ParameterName 'Background' -MinimumVersion '4.7.0' -BoundParameters $PSBoundParameters -FeatureName 'Background bulk processing (-Background)')
                $bulkParams = @{
                    URI          = $URI
                    Items        = $bulkItems.ToArray()
                    Method       = 'DELETE'
                    BatchSize    = $BatchSize
                    ShowProgress = $true
                    ActivityName = 'Deleting devices'
                    Background   = $useBackground
                }
                $result = Send-NBBulkRequest @bulkParams

                # Write summary
                if ($result.HasErrors) {
                    Write-Warning $result.GetSummary()
                    foreach ($failure in $result.Failed) {
                        Write-Error "Failed to delete device: $($failure.Error)" -TargetObject $failure.Item
                    }
                }
                else {
                    Write-Verbose $result.GetSummary()
                }
            }
        }
    }
}
