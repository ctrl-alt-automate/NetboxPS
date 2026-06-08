function Set-NBDCIMSite {
<#
    .SYNOPSIS
        Update a site in Netbox

    .DESCRIPTION
        Updates an existing site with the provided parameters.

    .PARAMETER Id
        The ID of the site to update

    .PARAMETER Name
        The name of the site

    .PARAMETER Slug
        The URL-friendly slug for the site

    .PARAMETER Status
        The operational status of the site (active, planned, staging, decommissioning, retired)

    .PARAMETER Region
        The region ID this site belongs to

    .PARAMETER Group
        The site group ID this site belongs to

    .PARAMETER Tenant
        The tenant ID that owns this site

    .PARAMETER Facility
        The facility identifier

    .PARAMETER Time_Zone
        The time zone for this site

    .PARAMETER Description
        A description of the site

    .PARAMETER Physical_Address
        The physical address of the site

    .PARAMETER Shipping_Address
        The shipping address for the site

    .PARAMETER Latitude
        The latitude coordinate

    .PARAMETER Longitude
        The longitude coordinate

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields and values

    .PARAMETER Owner
        The owner ID for object ownership (Netbox 4.5+ only).

    .PARAMETER Force
        Skip confirmation prompts

    .PARAMETER Tags
        One or more tags to assign to this object (tag names or IDs).

    .PARAMETER Raw
        Return the raw API response object instead of the .results collection.

    .EXAMPLE
        Set-NBDCIMSite -Id 1 -Description "Updated description"

    .EXAMPLE
        Get-NBDCIMSite -Name "Site1" | Set-NBDCIMSite -Status planned
.NOTES
    AddedInVersion: v4.4.10.0

#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Slug,

        [ValidateSet('active', 'planned', 'staging', 'decommissioning', 'retired')]
        [string]$Status,

        [uint64]$Region,

        [uint64]$Group,

        [uint64]$Tenant,

        [string]$Facility,

        [string]$Time_Zone,

        [string]$Description,

        [string]$Physical_Address,

        [string]$Shipping_Address,

        [double]$Latitude,

        [double]$Longitude,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [uint64]$Owner,

        [switch]$Force,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating DCIM Site"
        foreach ($SiteID in $Id) {
            if ($Force -or $PSCmdlet.ShouldProcess("Site ID $SiteID", "Update site")) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'sites', $SiteID))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'Force'

                $URI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method PATCH -Raw:$Raw
            }
        }
    }
}
