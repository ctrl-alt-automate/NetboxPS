<#
.SYNOPSIS
    Removes a Cooling Source from Netbox DCIM module.

.DESCRIPTION
    Removes a Cooling Source from Netbox DCIM module (NetBox 4.7+).
    Any cooling feeds attached to the source are deleted by NetBox as well.
    Supports pipeline input for the Id parameter.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the cooling source to delete.

.EXAMPLE
    Remove-NBDCIMCoolingSource -Id 5

    Deletes cooling source ID 5 after confirmation.

.EXAMPLE
    Get-NBDCIMCoolingSource -Status planned | Remove-NBDCIMCoolingSource -Confirm:$false

    Deletes every planned cooling source without prompting.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.7.0.1
    Requires NetBox 4.7.0 or later.

#>
function Remove-NBDCIMCoolingSource {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Cooling Source"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete cooling source')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim', 'cooling-sources', $Id)) -Method DELETE -Raw:$Raw
        }
    }
}
