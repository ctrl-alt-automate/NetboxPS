<#
.SYNOPSIS
    Deletes one or more IP addresses from Netbox.

.DESCRIPTION
    Deletes IP addresses from Netbox IPAM module. Supports both
    single IP address deletion with the Id parameter and bulk deletion via pipeline input.

    For bulk operations, use the -BatchSize parameter to control how many
    IP addresses are deleted per API request. Each object must have an Id property.

.PARAMETER Id
    The database ID(s) of the IP address(es) to delete. Required for single mode.

.PARAMETER InputObject
    Pipeline input for bulk operations. Each object MUST have an Id property.

.PARAMETER BatchSize
    Number of IP addresses to delete per API request in bulk mode.
    Default: 50, Range: 1-1000

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response object instead of the .results collection.

.EXAMPLE
    Remove-NBIPAMAddress -Id 123 -Force

    Deletes IP address with ID 123 without confirmation.

.EXAMPLE
    Get-NBIPAMAddress -Status "deprecated" | Remove-NBIPAMAddress -Force

    Bulk delete all deprecated IP addresses.

.EXAMPLE
    $ipsToDelete = @(
        [PSCustomObject]@{Id = 100}
        [PSCustomObject]@{Id = 101}
        [PSCustomObject]@{Id = 102}
    )
    $ipsToDelete | Remove-NBIPAMAddress -BatchSize 50 -Force

    Bulk delete multiple IP addresses.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v1.0.4

#>

function Remove-NBIPAMAddress {
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
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'ip-addresses'))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ParameterSetName -eq 'Bulk') {
            $bulkItems = [System.Collections.ArrayList]::new()
        }
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Single') {
            foreach ($IPId in $Id) {

                if ($Force -or $PSCmdlet.ShouldProcess("ID: $IPId", "Delete")) {
                    $IPSegments = [System.Collections.ArrayList]::new(@('ipam', 'ip-addresses', $IPId))

                    $IPURI = BuildNewURI -Segments $IPSegments

                    InvokeNetboxRequest -URI $IPURI -Method DELETE -Raw:$Raw
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
            $target = "$($bulkItems.Count) IP address(es)"

            if ($Force -or $PSCmdlet.ShouldProcess($target, 'Delete IP addresses (bulk)')) {
                Write-Verbose "Processing $($bulkItems.Count) IP addresses in bulk DELETE mode with batch size $BatchSize"

                $bulkParams = @{
                    URI          = $URI
                    Items        = $bulkItems.ToArray()
                    Method       = 'DELETE'
                    BatchSize    = $BatchSize
                    ShowProgress = $true
                    ActivityName = 'Deleting IP addresses'
                }
                $result = Send-NBBulkRequest @bulkParams

                # Write errors for failed items
                foreach ($failure in $result.Failed) {
                    Write-Error "Failed to delete IP address: $($failure.Error)" -TargetObject $failure.Item
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