<#
.SYNOPSIS
    Removes a Wireless LAN Group from Netbox Wireless module.

.DESCRIPTION
    Removes a Wireless LAN Group from Netbox Wireless module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to delete.

.EXAMPLE
    Remove-NBWirelessLANGroup

    Deletes a Wireless LAN Group object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Remove-NBWirelessLANGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete wireless LAN group')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('wireless','wireless-lan-groups',$Id)) -Method DELETE -Raw:$Raw } }
}
