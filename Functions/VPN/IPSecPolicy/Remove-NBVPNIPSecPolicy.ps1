<#
.SYNOPSIS
    Removes a VPN IPSecPolicy from Netbox VPN module.

.DESCRIPTION
    Removes a VPN IPSecPolicy from Netbox VPN module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to delete.

.EXAMPLE
    Remove-NBVPNIPSecPolicy

    Deletes a VPN IPSecPolicy object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Remove-NBVPNIPSecPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[switch]$Raw)
    process { if ($PSCmdlet.ShouldProcess($Id, 'Delete IPSec policy')) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('vpn','ipsec-policies',$Id)) -Method DELETE -Raw:$Raw } }
}
