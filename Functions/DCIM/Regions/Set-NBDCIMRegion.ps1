function Set-NBDCIMRegion {
<#
    .SYNOPSIS
        Update a region in Netbox

    .DESCRIPTION
        Updates an existing region object in Netbox.

    .PARAMETER Id
        The ID of the region to update (required)

    .PARAMETER Name
        The name of the region

    .PARAMETER Slug
        The URL-friendly slug

    .PARAMETER Parent
        The parent region ID for nested regions

    .PARAMETER Description
        A description of the region

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .PARAMETER Tags
        One or more tags to assign to this object (tag names or IDs).

    .EXAMPLE
        Set-NBDCIMRegion -Id 1 -Name "Western Europe"

        Updates the name of region 1

    .EXAMPLE
        Set-NBDCIMRegion -Id 1 -Description "Western European countries"

        Updates the description of region 1
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
        Write-Verbose "Updating DCIM Region"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'regions', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update region')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
