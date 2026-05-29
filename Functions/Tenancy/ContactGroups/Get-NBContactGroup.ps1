
function Get-NBContactGroup {
<#
    .SYNOPSIS
        Get one or more contact groups from Netbox

    .DESCRIPTION
        Retrieves contact groups from Netbox. Contact groups are hierarchical
        organizational containers for grouping related contacts.

    .PARAMETER Id
        The database ID of the contact group.

    .PARAMETER Name
        The specific name of the contact group.

    .PARAMETER Slug
        Filter by the contact group's slug.

    .PARAMETER Parent_Id
        Filter by parent contact group database ID (returns its direct children).

    .PARAMETER Offset
        Start the search at this index in results

    .PARAMETER Raw
        Return the unparsed data from the HTTP request

    .PARAMETER All
        Automatically fetch all pages of results. Uses the API's pagination
        to retrieve all items across multiple requests.

    .PARAMETER Brief
    Return a minimal representation of objects (id, url, display, name only).
    Reduces response size by ~90%. Ideal for dropdowns and reference lists.

    .PARAMETER Fields
    Specify which fields to include in the response.
    Supports nested field selection (e.g., 'site.name', 'device_type.model').

    .PARAMETER Omit
    Specify which fields to exclude from the response.
    Requires Netbox 4.5.0 or later.

    .PARAMETER PageSize
        Number of items per page when using -All. Default: 100.
        Range: 1-1000.

    .PARAMETER Limit
        Limit the number of results to this number

    .EXAMPLE
        PS C:\> Get-NBContactGroup

    .EXAMPLE
        PS C:\> Get-NBContactGroup -Id 5

    .NOTES
        The -Brief, -Fields, and -Omit parameters are mutually exclusive.
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query',
                   Position = 0)]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Slug,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Parent_Id,

        [switch]$All,

        [switch]$Brief,

        [string[]]$Fields,

        [string[]]$Omit,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [uint16]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        AssertNBMutualExclusiveParam `
            -BoundParameters $PSBoundParameters `
            -Parameters 'Brief', 'Fields', 'Omit'
        Write-Verbose "Retrieving Contact Group"
        switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($ContactGroup_ID in $Id) {
                $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contact-groups', $ContactGroup_ID))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'All', 'PageSize'

                $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $uri -Raw:$Raw -All:$All -PageSize $PageSize
            }
            return
        }

        default {
            $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contact-groups'))

            $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'

            $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $uri -Raw:$Raw -All:$All -PageSize $PageSize
        }
    }
    }
}