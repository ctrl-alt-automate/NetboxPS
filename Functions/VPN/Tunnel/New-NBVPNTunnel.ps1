<#
.SYNOPSIS
    Creates a new VPN Tunnel in Netbox VPN module.

.DESCRIPTION
    Creates a new VPN Tunnel in Netbox VPN module.

.PARAMETER Name
    The name of the VPN tunnel (required).

.PARAMETER Status
    Tunnel status: 'active', 'planned', or 'disabled' (required).

.PARAMETER Encapsulation
    Tunnel encapsulation type: 'ipsec-transport', 'ipsec-tunnel', 'ip-ip', or 'gre' (required).

.PARAMETER Group
    Tunnel group ID.

.PARAMETER IPSec_Profile
    IPSec profile ID to associate with this tunnel.

.PARAMETER Tenant
    Tenant ID.

.PARAMETER Tunnel_Id
    Numeric tunnel identifier.

.PARAMETER Description
    Description of the tunnel.

.PARAMETER Comments
    Additional comments.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBVPNTunnel -Name "Site-to-Site" -Status "active" -Encapsulation "ipsec-tunnel"

    Creates a new VPN Tunnel object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBVPNTunnel {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('active', 'planned', 'disabled')]
        [string]$Status,

        [Parameter(Mandatory = $true)]
        [ValidateSet('ipsec-transport', 'ipsec-tunnel', 'ip-ip', 'gre', 'l2tp', 'openvpn', 'pptp', 'wireguard')]
        [string]$Encapsulation,

        [uint64]$Group,

        [uint64]$IPSec_Profile,

        [uint64]$Tenant,

        [uint64]$Tunnel_Id,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating VPN Tunnel"
        $Segments = [System.Collections.ArrayList]::new(@('vpn', 'tunnels'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create new VPN tunnel')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
