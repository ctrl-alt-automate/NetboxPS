<#
.SYNOPSIS
    Removes a VPN Tunnel from Netbox VPN module.

.DESCRIPTION
    Removes a VPN Tunnel from Netbox VPN module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to delete.

.EXAMPLE
    Remove-NBVPNTunnel

    Deletes a VPN Tunnel object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Remove-NBVPNTunnel {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing VPN Tunnel"
        $Segments = [System.Collections.ArrayList]::new(@('vpn', 'tunnels', $Id))
        $URI = BuildNewURI -Segments $Segments
        if ($PSCmdlet.ShouldProcess($Id, 'Delete VPN tunnel')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
