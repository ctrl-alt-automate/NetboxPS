function Get-NBDCIMManufacturer {
<#
    .SYNOPSIS
        Get manufacturers from Netbox

    .DESCRIPTION
        Retrieves manufacturer objects from Netbox with optional filtering.

    .PARAMETER Id
        The ID of the manufacturer to retrieve

    .PARAMETER Name
        Filter by manufacturer name

    .PARAMETER Slug
        Filter by slug

    .PARAMETER Query
        A general search query

    .PARAMETER Tag
        Filter by tag slug(s). Several values are combined with AND (object must carry all of them);
        use Set-NBQueryOption -TagMatch Any (Netbox 4.6.6+) for OR semantics.

    .PARAMETER Tag_Id
        Filter by tag ID(s); combines like -Tag.

    .PARAMETER Limit
        Limit the number of results

    .PARAMETER Offset
        Offset for pagination

    .PARAMETER Raw
        Return the raw API response

    .PARAMETER All
        Automatically fetch all pages of results. Uses the API's pagination
        to retrieve all items across multiple requests.

    .PARAMETER PageSize
        Number of items per page when using -All. Default: 100.
        Range: 1-1000.

    .PARAMETER Brief
        Return a minimal representation of objects (id, url, display, name only).
        Reduces response size by ~90%. Ideal for dropdowns and reference lists.

    .PARAMETER Fields
        Specify which fields to include in the response.
        Supports nested field selection (e.g., 'site.name', 'device_type.model').

    .PARAMETER Omit
        Specify which fields to exclude from the response.
        Requires Netbox 4.5.0 or later.

    .EXAMPLE
        Get-NBDCIMManufacturer

        Returns all manufacturers

    .EXAMPLE
        Get-NBDCIMManufacturer -Name "Cisco"

        Returns manufacturers matching the name "Cisco"
.NOTES
    AddedInVersion: v4.4.10.0
    The -Brief, -Fields, and -Omit parameters are mutually exclusive.
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [switch]$Brief,

        [string[]]$Fields,

        [string[]]$Omit,

        [Parameter(ParameterSetName = 'ByID',
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Slug,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [string[]]$Tag,

        [Parameter(ParameterSetName = 'Query')]
        [uint64[]]$Tag_Id,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        AssertNBMutualExclusiveParam `
            -BoundParameters $PSBoundParameters `
            -Parameters 'Brief', 'Fields', 'Omit'
        Write-Verbose "Retrieving DCIM Manufacturer"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($ManufacturerId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('dcim', 'manufacturers', $ManufacturerId))

                    $URI = BuildNewURI -Segments $Segments

                    InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'manufacturers'))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}