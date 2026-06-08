<#
.SYNOPSIS
    Creates a new VPN L2VPN in Netbox VPN module.

.DESCRIPTION
    Creates a new VPN L2VPN in Netbox VPN module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Name
    Name of the object.

.PARAMETER Slug
    URL-friendly unique identifier (slug).

.PARAMETER Identifier
    Identifier.

.PARAMETER Type
    Type of the object.

.PARAMETER Status
    Operational status.

.PARAMETER Tenant
    Tenant assigned to this object (database ID).

.PARAMETER Description
    Brief description.

.PARAMETER Comments
    Detailed comments (Markdown is supported).

.PARAMETER Import_Targets
    Import Targets.

.PARAMETER Export_Targets
    Export Targets.

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBVPNL2VPN

    Creates a new VPN L2VPN object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBVPNL2VPN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true)][string]$Name,[Parameter(Mandatory = $true)][string]$Slug,
        [uint64]$Identifier,[string]$Type,[string]$Status,[uint64]$Tenant,[string]$Description,[string]$Comments,
        [uint64[]]$Import_Targets,[uint64[]]$Export_Targets,[hashtable]$Custom_Fields,[object[]]$Tags,[switch]$Raw)
    process {
        Write-Verbose "Creating VPN L2VPN"
        $s = [System.Collections.ArrayList]::new(@('vpn','l2vpns')); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create L2VPN')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method POST -Body $u.Parameters -Raw:$Raw }
    }
}
