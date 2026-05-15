<#
.SYNOPSIS
    Deletes a cable bundle from Netbox DCIM.

.DESCRIPTION
    Deletes an existing CableBundle (NetBox 4.6+).

.PARAMETER Id
    The ID of the cable bundle to delete.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBDCIMCableBundle -Id 1

.EXAMPLE
    Get-NBDCIMCableBundle -Name 'PP1-PP2 trunk' | Remove-NBDCIMCableBundle

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.6.0.1

#>
function Remove-NBDCIMCableBundle {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        Write-Verbose "Deleting DCIM Cable Bundle"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cable-bundles', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete cable bundle')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
