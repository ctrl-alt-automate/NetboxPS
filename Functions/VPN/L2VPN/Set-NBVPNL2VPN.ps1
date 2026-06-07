<#
.SYNOPSIS
    Updates an existing VPN L2VPN in Netbox VPN module.

.DESCRIPTION
    Updates an existing VPN L2VPN in Netbox VPN module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to update.

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
    Set-NBVPNL2VPN

    Updates an existing VPN L2VPN object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBVPNL2VPN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Name,[string]$Slug,[uint64]$Identifier,[string]$Type,[string]$Status,[uint64]$Tenant,
        [string]$Description,[string]$Comments,[uint64[]]$Import_Targets,[uint64[]]$Export_Targets,[hashtable]$Custom_Fields,[object[]]$Tags,[switch]$Raw)
    process {
        Write-Verbose "Updating VPN L2VPN"
        $s = [System.Collections.ArrayList]::new(@('vpn','l2vpns',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update L2VPN')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}
