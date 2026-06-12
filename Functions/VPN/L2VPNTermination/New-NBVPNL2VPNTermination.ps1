<#
.SYNOPSIS
    Creates a new VPN L2VPNTermination in Netbox VPN module.

.DESCRIPTION
    Creates a new VPN L2VPNTermination in Netbox VPN module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER L2VPN
    L2VPN.

.PARAMETER Assigned_Object_Type
    Assigned Object Type.

.PARAMETER Assigned_Object_Id
    Database ID of the assigned object.

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBVPNL2VPNTermination

    Creates a new VPN L2VPNTermination object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBVPNL2VPNTermination {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true)][uint64]$L2VPN,[Parameter(Mandatory = $true)][string]$Assigned_Object_Type,[Parameter(Mandatory = $true)][uint64]$Assigned_Object_Id,[hashtable]$Custom_Fields,[object[]]$Tags,[switch]$Raw)
    process {
        Write-Verbose "Creating VPN L2VPN Termination"
        $s = [System.Collections.ArrayList]::new(@('vpn','l2vpn-terminations')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess("L2VPN $L2VPN", 'Create L2VPN termination')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}
