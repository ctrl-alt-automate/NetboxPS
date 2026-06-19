<#
.SYNOPSIS
    Creates a new VPN TunnelTermination in Netbox VPN module.

.DESCRIPTION
    Creates a new VPN TunnelTermination in Netbox VPN module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Tunnel
    Tunnel.

.PARAMETER Role
    Role assigned to this object (database ID).

.PARAMETER Termination_Type
    Termination Type.

.PARAMETER Termination_Id
    Database ID of the termination.

.PARAMETER Outside_IP
    Outside IP.

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBVPNTunnelTermination

    Creates a new VPN TunnelTermination object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBVPNTunnelTermination {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true)][uint64]$Tunnel,[Parameter(Mandatory = $true)][ValidateSet('peer', 'hub', 'spoke')][string]$Role,
        [string]$Termination_Type,[uint64]$Termination_Id,[uint64]$Outside_IP,[hashtable]$Custom_Fields,[object[]]$Tags,[switch]$Raw)
    process {
        Write-Verbose "Creating VPN Tunnel Termination"
        $s = [System.Collections.ArrayList]::new(@('vpn','tunnel-terminations')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess("Tunnel $Tunnel", 'Create tunnel termination')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}
