<#
.SYNOPSIS
    Retrieves Module Bay Type objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Module Bay Type objects from Netbox DCIM module.
    A module bay type describes which kinds of modules a module bay accepts
    (NetBox 4.7+). Module bays, module bay templates and module types reference
    one or more module bay types.

.PARAMETER Raw
    Return the raw API response instead of the results array.

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
    Supports nested field selection (e.g., 'manufacturer.name').

.PARAMETER Omit
    Specify which fields to exclude from the response.
    Requires Netbox 4.5.0 or later.

.PARAMETER Id
    One or more database IDs to retrieve.

.PARAMETER Name
    Filter by name. Accepts multiple values.

.PARAMETER Slug
    Filter by URL slug. Accepts multiple values.

.PARAMETER Color
    Filter by color (6-digit hex code, e.g. 'ff0000'). Accepts multiple values.

.PARAMETER Manufacturer_Id
    Filter by manufacturer database ID. Accepts multiple values.

.PARAMETER Manufacturer
    Filter by manufacturer slug. Accepts multiple values.

.PARAMETER Module_Bay_Id
    Filter by module bay database ID (module bay types assigned to that bay).
    Accepts multiple values.

.PARAMETER Module_Bay_Template_Id
    Filter by module bay template database ID. Accepts multiple values.

.PARAMETER Module_Type_Id
    Filter by module type database ID (module bay types accepted by that module type).
    Accepts multiple values.

.PARAMETER Description
    Filter by description. Accepts multiple values.

.PARAMETER Owner_Id
    Filter by owner database ID. Accepts multiple values.

.PARAMETER Tag
    Filter by tag slug. Accepts multiple values.

.PARAMETER Query
    Free-text search across the object (NetBox 'q' parameter).

.PARAMETER Limit
    Maximum number of results to return per request (1-1000).

.PARAMETER Offset
    Number of results to skip (pagination offset).

.EXAMPLE
    Get-NBDCIMModuleBayType

    Retrieves all module bay types.

.EXAMPLE
    Get-NBDCIMModuleBayType -Module_Type_Id 12

    Retrieves the module bay types accepted by module type 12.

.NOTES
    AddedInVersion: v4.7.1.0
    Requires NetBox 4.7.0 or later (the /api/dcim/module-bay-types/ endpoint).
    The -Brief, -Fields, and -Omit parameters are mutually exclusive.
.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMModuleBayType {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [switch]$Brief,

        [string[]]$Fields,

        [string[]]$Omit,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string[]]$Name,
        [Parameter(ParameterSetName = 'Query')][string[]]$Slug,
        [Parameter(ParameterSetName = 'Query')][string[]]$Color,
        [Parameter(ParameterSetName = 'Query')][uint64[]]$Manufacturer_Id,
        [Parameter(ParameterSetName = 'Query')][string[]]$Manufacturer,
        [Parameter(ParameterSetName = 'Query')][uint64[]]$Module_Bay_Id,
        [Parameter(ParameterSetName = 'Query')][uint64[]]$Module_Bay_Template_Id,
        [Parameter(ParameterSetName = 'Query')][uint64[]]$Module_Type_Id,
        [Parameter(ParameterSetName = 'Query')][string[]]$Description,
        [Parameter(ParameterSetName = 'Query')][uint64[]]$Owner_Id,
        [Parameter(ParameterSetName = 'Query')][string[]]$Tag,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [ValidateRange(1, 1000)]
        [uint16]$Limit,
        [uint32]$Offset,
        [switch]$Raw
    )
    process {
        AssertNBMutualExclusiveParam `
            -BoundParameters $PSBoundParameters `
            -Parameters 'Brief', 'Fields', 'Omit'
        Write-Verbose "Retrieving DCIM Module Bay Type"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('dcim', 'module-bay-types', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'All', 'PageSize'
                    InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'module-bay-types'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
