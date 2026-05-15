<#
.SYNOPSIS
    Deletes a rack group from Netbox DCIM.

.DESCRIPTION
    Deletes an existing RackGroup (NetBox 4.6+).

.PARAMETER Id
    The ID of the rack group to delete.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMRackGroup -Id 1

.EXAMPLE
    Get-NBDCIMRackGroup -Name 'Row A' | Remove-NBDCIMRackGroup

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.6.0.1

#>
function Remove-NBDCIMRackGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        Write-Verbose "Deleting DCIM Rack Group"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'rack-groups', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete rack group')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
