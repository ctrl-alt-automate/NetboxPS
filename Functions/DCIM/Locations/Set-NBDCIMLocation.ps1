function Set-NBDCIMLocation {
<#
    .SYNOPSIS
        Update a location in Netbox

    .DESCRIPTION
        Updates an existing location object in Netbox.

    .PARAMETER Id
        The ID of the location to update (required)

    .PARAMETER Name
        The name of the location

    .PARAMETER Slug
        The URL-friendly slug

    .PARAMETER Site
        The site ID where the location exists

    .PARAMETER Parent
        The parent location ID for nested locations

    .PARAMETER Status
        The operational status (planned, staging, active, decommissioning, retired)

    .PARAMETER Tenant
        The tenant ID that owns this location

    .PARAMETER Facility
        The facility identifier

    .PARAMETER Description
        A description of the location

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .PARAMETER Tags
        One or more tags to assign to this object (tag names or IDs).

    .EXAMPLE
        Set-NBDCIMLocation -Id 1 -Name "Server Room A"

        Updates the name of location 1

    .EXAMPLE
        Set-NBDCIMLocation -Id 1 -Status retired

        Marks location 1 as retired
.NOTES
    AddedInVersion: v4.4.10.0

#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Slug,

        [uint64]$Site,

        [uint64]$Parent,

        [ValidateSet('planned', 'staging', 'active', 'decommissioning', 'retired')]
        [string]$Status,

        [uint64]$Tenant,

        [string]$Facility,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating DCIM Location"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'locations', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update location')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
