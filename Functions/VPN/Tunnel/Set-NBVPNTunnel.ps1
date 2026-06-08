<#
.SYNOPSIS
    Updates an existing VPN Tunnel in Netbox VPN module.

.DESCRIPTION
    Updates an existing VPN Tunnel in Netbox VPN module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to update.

.PARAMETER Name
    Name of the object.

.PARAMETER Status
    Operational status.

.PARAMETER Encapsulation
    Encapsulation.

.PARAMETER Group
    Group assigned to this object (database ID).

.PARAMETER IPSec_Profile
    IPSec Profile.

.PARAMETER Tenant
    Tenant assigned to this object (database ID).

.PARAMETER Description
    Brief description.

.PARAMETER Comments
    Detailed comments (Markdown is supported).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    Set-NBVPNTunnel

    Updates an existing VPN Tunnel object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBVPNTunnel {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Name,
        [ValidateSet('active', 'planned', 'disabled')][string]$Status,
        [ValidateSet('ipsec-transport', 'ipsec-tunnel', 'ip-ip', 'gre', 'l2tp', 'openvpn', 'pptp', 'wireguard')][string]$Encapsulation,
        [uint64]$Group,
        [uint64]$IPSec_Profile,
        [uint64]$Tenant,
        [string]$Description,
        [string]$Comments,
        [hashtable]$Custom_Fields,

        [object[]]$Tags,

        [switch]$Raw
    )
    process {
        Write-Verbose "Updating VPN Tunnel"
        $Segments = [System.Collections.ArrayList]::new(@('vpn', 'tunnels', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments
        if ($PSCmdlet.ShouldProcess($Id, 'Update VPN tunnel')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
