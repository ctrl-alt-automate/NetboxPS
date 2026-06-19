function Set-NBDCIMSiteGroup {
<#
    .SYNOPSIS
        Update a site group in Netbox

    .DESCRIPTION
        Updates an existing site group object in Netbox.

    .PARAMETER Id
        The ID of the site group to update (required)

    .PARAMETER Name
        The name of the site group

    .PARAMETER Slug
        The URL-friendly slug

    .PARAMETER Parent
        The parent site group ID for nested groups

    .PARAMETER Description
        A description of the site group

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .PARAMETER Tags
        One or more tags to assign to this object (tag names or IDs).

    .EXAMPLE
        Set-NBDCIMSiteGroup -Id 1 -Name "Production Sites"

        Updates the name of site group 1

    .EXAMPLE
        Set-NBDCIMSiteGroup -Id 1 -Description "All production sites"

        Updates the description of site group 1
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

        [uint64]$Parent,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating DCIM Site Group"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'site-groups', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update site group')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
