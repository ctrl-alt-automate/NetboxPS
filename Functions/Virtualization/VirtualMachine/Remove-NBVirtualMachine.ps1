<#
.SYNOPSIS
    Deletes one or more virtual machines from Netbox.

.DESCRIPTION
    Deletes virtual machines from Netbox Virtualization module. Supports both
    single VM deletion with the Id parameter and bulk deletion via pipeline input.

    For bulk operations, use the -BatchSize parameter to control how many
    VMs are deleted per API request. Each object must have an Id property.

.PARAMETER Id
    The database ID(s) of the virtual machine(s) to delete. Required for single mode.

.PARAMETER InputObject
    Pipeline input for bulk operations. Each object MUST have an Id property.

.PARAMETER BatchSize
    Number of VMs to delete per API request in bulk mode.
    Default: 50, Range: 1-1000

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response object instead of the .results collection.

.EXAMPLE
    Remove-NBVirtualMachine -Id 123 -Force

    Deletes VM with ID 123 without confirmation.

.EXAMPLE
    Get-NBVirtualMachine -Status "decommissioning" | Remove-NBVirtualMachine -Force

    Bulk delete all VMs with decommissioning status.

.EXAMPLE
    $vmsToDelete = @(
        [PSCustomObject]@{Id = 100}
        [PSCustomObject]@{Id = 101}
        [PSCustomObject]@{Id = 102}
    )
    $vmsToDelete | Remove-NBVirtualMachine -BatchSize 50 -Force

    Bulk delete multiple VMs.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v1.0.4

#>

function Remove-NBVirtualMachine {
    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'High',
        DefaultParameterSetName = 'Single')]
    [OutputType([void])]
    param
    (
        # Single mode parameters
        [Parameter(ParameterSetName = 'Single', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        # Bulk mode parameters
        [Parameter(ParameterSetName = 'Bulk', Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]$InputObject,

        [Parameter(ParameterSetName = 'Bulk')]
        [ValidateRange(1, 1000)]
        [int]$BatchSize = 100,

        # Common parameters
        [Parameter()]
        [switch]$Force,

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
            foreach ($VMId in $Id) {

                if ($Force -or $PSCmdlet.ShouldProcess("ID $VMId", "Remove")) {
                    $VMSegments = [System.Collections.ArrayList]::new(@('virtualization', 'virtual-machines', $VMId))

                    $VMURI = BuildNewURI -Segments $VMSegments

                    InvokeNetboxRequest -URI $VMURI -Method DELETE -Raw:$Raw
                }
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
                    Write-Error "InputObject must have an 'Id' property for bulk deletes" -TargetObject $InputObject
                    return
                }

                $item = @{ id = $itemId }
                [void]$bulkItems.Add([PSCustomObject]$item)
            }
        }
    }

    end {
        if ($PSCmdlet.ParameterSetName -eq 'Bulk' -and $bulkItems.Count -gt 0) {
            $target = "$($bulkItems.Count) virtual machine(s)"

            if ($Force -or $PSCmdlet.ShouldProcess($target, 'Delete virtual machines (bulk)')) {
                Write-Verbose "Processing $($bulkItems.Count) VMs in bulk DELETE mode with batch size $BatchSize"

                $bulkParams = @{
                    URI          = $URI
                    Items        = $bulkItems.ToArray()
                    Method       = 'DELETE'
                    BatchSize    = $BatchSize
                    ShowProgress = $true
                    ActivityName = 'Deleting virtual machines'
                }
                $result = Send-NBBulkRequest @bulkParams

                # Write errors for failed items
                foreach ($failure in $result.Failed) {
                    Write-Error "Failed to delete VM: $($failure.Error)" -TargetObject $failure.Item
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