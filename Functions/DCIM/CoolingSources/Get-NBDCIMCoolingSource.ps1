<#
.SYNOPSIS
    Retrieves Cooling Source objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Cooling Source objects from Netbox DCIM module (NetBox 4.7+).
    A cooling source is a facility-level piece of cooling equipment (chiller,
    cooling tower, dry cooler, CRAC or CRAH) installed at a site, analogous
    to a power panel for the power distribution model.

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
    Supports nested field selection (e.g., 'site.name', 'location.name').

.PARAMETER Omit
    Specify which fields to exclude from the response.
    Requires Netbox 4.5.0 or later.

.PARAMETER Id
    One or more database IDs to retrieve.

.PARAMETER Name
    Filter by name. Accepts multiple values.

.PARAMETER Site_Id
    Filter by site database ID. Accepts multiple values.

.PARAMETER Site
    Filter by site slug. Accepts multiple values.

.PARAMETER Location_Id
    Filter by location database ID. Accepts multiple values.

.PARAMETER Location
    Filter by location slug. Accepts multiple values.

.PARAMETER Region_Id
    Filter by region database ID. Accepts multiple values.

.PARAMETER Region
    Filter by region slug. Accepts multiple values.

.PARAMETER Site_Group_Id
    Filter by site group database ID. Accepts multiple values.

.PARAMETER Type
    Filter by cooling source type (chiller, cooling-tower, dry-cooler, crac, crah).
    Accepts multiple values.

.PARAMETER Status
    Filter by operational status (offline, active, planned, failed).
    Accepts multiple values.

.PARAMETER Fluid_Type
    Filter by cooling fluid type (water, water-glycol, dielectric, refrigerant).
    Accepts multiple values.

.PARAMETER Cooling_Capacity
    Filter by total rated cooling capacity in kW. Accepts multiple values.

.PARAMETER Description
    Filter by description. Accepts multiple values.

.PARAMETER Owner_Id
    Filter by owner database ID. Accepts multiple values.

.PARAMETER Tag
    Filter by tag slug. Accepts multiple values.
.PARAMETER Tag_Id
        Filter by tag ID(s); combines like -Tag.


.PARAMETER Query
    Free-text search across the object (NetBox 'q' parameter).

.PARAMETER Limit
    Maximum number of results to return per request (1-1000).

.PARAMETER Offset
    Number of results to skip (pagination offset).

.EXAMPLE
    Get-NBDCIMCoolingSource

    Returns all cooling sources.

.EXAMPLE
    Get-NBDCIMCoolingSource -Site_Id 1 -Type chiller

    Returns all chillers at site ID 1.

.EXAMPLE
    Get-NBDCIMCoolingSource -Id 5 -Brief

    Returns the brief representation of cooling source ID 5.

.NOTES
    AddedInVersion: v4.7.0.1
    Requires NetBox 4.7.0 or later.
    The -Brief, -Fields, and -Omit parameters are mutually exclusive.
.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMCoolingSource {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [switch]$Brief,

        [string[]]$Fields,

        [string[]]$Omit,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string[]]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [uint64[]]$Site_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string[]]$Site,

        [Parameter(ParameterSetName = 'Query')]
        [uint64[]]$Location_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string[]]$Location,

        [Parameter(ParameterSetName = 'Query')]
        [uint64[]]$Region_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string[]]$Region,

        [Parameter(ParameterSetName = 'Query')]
        [uint64[]]$Site_Group_Id,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('chiller', 'cooling-tower', 'dry-cooler', 'crac', 'crah')]
        [string[]]$Type,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('offline', 'active', 'planned', 'failed')]
        [string[]]$Status,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('water', 'water-glycol', 'dielectric', 'refrigerant')]
        [string[]]$Fluid_Type,

        [Parameter(ParameterSetName = 'Query')]
        [decimal[]]$Cooling_Capacity,

        [Parameter(ParameterSetName = 'Query')]
        [string[]]$Description,

        [Parameter(ParameterSetName = 'Query')]
        [uint64[]]$Owner_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string[]]$Tag,


        [Parameter(ParameterSetName = 'Query')]

        [uint64[]]$Tag_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint32]$Offset,

        [switch]$Raw
    )
    process {
        AssertNBMutualExclusiveParam `
            -BoundParameters $PSBoundParameters `
            -Parameters 'Brief', 'Fields', 'Omit'
        Write-Verbose "Retrieving DCIM Cooling Source"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cooling-sources', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'All', 'PageSize'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cooling-sources'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
