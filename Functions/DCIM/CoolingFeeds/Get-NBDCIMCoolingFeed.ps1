<#
.SYNOPSIS
    Retrieves Cooling Feed objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Cooling Feed objects from Netbox DCIM module (NetBox 4.7+).
    A cooling feed delivers cooling capacity from a cooling source to a
    rack, analogous to a power feed in the power distribution model.

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
    Supports nested field selection (e.g., 'cooling_source.name', 'rack.name').

.PARAMETER Omit
    Specify which fields to exclude from the response.
    Requires Netbox 4.5.0 or later.

.PARAMETER Id
    One or more database IDs to retrieve.

.PARAMETER Name
    Filter by name. Accepts multiple values.

.PARAMETER Cooling_Source_Id
    Filter by cooling source database ID. Accepts multiple values.

.PARAMETER Rack_Id
    Filter by rack database ID. Accepts multiple values.

.PARAMETER Site_Id
    Filter by site database ID (via the cooling source). Accepts multiple values.

.PARAMETER Site
    Filter by site slug (via the cooling source). Accepts multiple values.

.PARAMETER Region_Id
    Filter by region database ID. Accepts multiple values.

.PARAMETER Tenant_Id
    Filter by tenant database ID. Accepts multiple values.

.PARAMETER Tenant
    Filter by tenant slug. Accepts multiple values.

.PARAMETER Status
    Filter by operational status (offline, active, planned, failed).
    Accepts multiple values.

.PARAMETER Max_Flow_Unit
    Filter by maximum flow unit (lpm, m3ph, gpm). Accepts multiple values.

.PARAMETER Cooling_Capacity
    Filter by rated cooling capacity in kW. Accepts multiple values.

.PARAMETER Max_Flow
    Filter by maximum flow rate. Accepts multiple values.

.PARAMETER Description
    Filter by description. Accepts multiple values.

.PARAMETER Tag
    Filter by tag slug. Accepts multiple values.

.PARAMETER Query
    Free-text search across the object (NetBox 'q' parameter).

.PARAMETER Limit
    Maximum number of results to return per request (1-1000).

.PARAMETER Offset
    Number of results to skip (pagination offset).

.EXAMPLE
    Get-NBDCIMCoolingFeed

    Returns all cooling feeds.

.EXAMPLE
    Get-NBDCIMCoolingFeed -Cooling_Source_Id 3 -Status active

    Returns all active cooling feeds provisioned from cooling source ID 3.

.EXAMPLE
    Get-NBDCIMCoolingFeed -Rack_Id 12

    Returns the cooling feeds attached to rack ID 12.

.NOTES
    AddedInVersion: v4.7.1.0
    Requires NetBox 4.7.0 or later.
    The -Brief, -Fields, and -Omit parameters are mutually exclusive.
.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMCoolingFeed {
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
        [uint64[]]$Cooling_Source_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64[]]$Rack_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64[]]$Site_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string[]]$Site,

        [Parameter(ParameterSetName = 'Query')]
        [uint64[]]$Region_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64[]]$Tenant_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string[]]$Tenant,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('offline', 'active', 'planned', 'failed')]
        [string[]]$Status,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('lpm', 'm3ph', 'gpm')]
        [string[]]$Max_Flow_Unit,

        [Parameter(ParameterSetName = 'Query')]
        [decimal[]]$Cooling_Capacity,

        [Parameter(ParameterSetName = 'Query')]
        [decimal[]]$Max_Flow,

        [Parameter(ParameterSetName = 'Query')]
        [string[]]$Description,

        [Parameter(ParameterSetName = 'Query')]
        [string[]]$Tag,

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
        Write-Verbose "Retrieving DCIM Cooling Feed"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cooling-feeds', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'All', 'PageSize'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cooling-feeds'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
