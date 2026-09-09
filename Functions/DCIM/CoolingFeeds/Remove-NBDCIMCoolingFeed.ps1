<#
.SYNOPSIS
    Removes a Cooling Feed from Netbox DCIM module.

.DESCRIPTION
    Removes a Cooling Feed from Netbox DCIM module (NetBox 4.7+).
    Supports pipeline input for the Id parameter.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the cooling feed to delete.

.EXAMPLE
    Remove-NBDCIMCoolingFeed -Id 7

    Deletes cooling feed ID 7 after confirmation.

.EXAMPLE
    Get-NBDCIMCoolingFeed -Cooling_Source_Id 3 | Remove-NBDCIMCoolingFeed -Confirm:$false

    Deletes every cooling feed provisioned from cooling source ID 3 without prompting.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.7.0.1
    Requires NetBox 4.7.0 or later.

#>
function Remove-NBDCIMCoolingFeed {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Cooling Feed"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete cooling feed')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim', 'cooling-feeds', $Id)) -Method DELETE -Raw:$Raw
        }
    }
}
