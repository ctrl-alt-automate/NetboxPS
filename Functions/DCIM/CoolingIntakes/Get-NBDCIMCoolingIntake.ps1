<#
.SYNOPSIS
    Retrieves Cooling Intakes objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Cooling Intakes objects from Netbox DCIM module (NetBox 4.7+).
    Array-typed filters accept multiple values and are sent as repeated query keys.

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
    Supports nested field selection (e.g., 'device.name', 'module.display').

.PARAMETER Omit
    Specify which fields to exclude from the response.
    Requires Netbox 4.5.0 or later.

.PARAMETER Id
    One or more database IDs to retrieve.

.PARAMETER Name
    Filter by name (one or more values).

.PARAMETER Label
    Filter by physical label (one or more values).

.PARAMETER Device_Id
    Filter by device database ID.

.PARAMETER Device
    Filter by device name.

.PARAMETER Device_Type_Id
    Filter by the device type database ID of the parent device.

.PARAMETER Module_Id
    Filter by module database ID.

.PARAMETER Site_Id
    Filter by site database ID.

.PARAMETER Site
    Filter by site slug.

.PARAMETER Location_Id
    Filter by location database ID.

.PARAMETER Rack_Id
    Filter by rack database ID.

.PARAMETER Type
    Filter by connector type ('uqd', 'uqdb', 'qdc', 'camlock', 'npt', 'bsp', 'proprietary').

.PARAMETER Diameter
    Filter by connector diameter.

.PARAMETER Diameter_Unit
    Filter by diameter unit ('mm', 'cm', 'in').

.PARAMETER Max_Flow
    Filter by maximum flow rate.

.PARAMETER Max_Flow_Unit
    Filter by maximum flow unit ('lpm', 'm3ph', 'gpm').

.PARAMETER Cooling_Outflow_Id
    Filter by the upstream cooling outflow database ID.

.PARAMETER Description
    Filter by description (one or more values).

.PARAMETER Tag
    Filter by tag slug (one or more values).
.PARAMETER Tag_Id
        Filter by tag ID(s); combines like -Tag.


.PARAMETER Query
    Free-text search across the object (NetBox 'q' parameter).

.PARAMETER Limit
    Maximum number of results to return per request (1-1000).

.PARAMETER Offset
    Number of results to skip (pagination offset).

.EXAMPLE
    Get-NBDCIMCoolingIntake

    Retrieves all cooling intakes.

.EXAMPLE
    Get-NBDCIMCoolingIntake -Device_Id 12 -Type 'uqd'

    Lists the UQD cooling intakes on device 12.

.EXAMPLE
    Get-NBDCIMCoolingIntake -Id 5

    Retrieves the cooling intake with ID 5.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.7.0.1
    The -Brief, -Fields, and -Omit parameters are mutually exclusive.
#>
function Get-NBDCIMCoolingIntake {
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
        [string[]]$Label,

        [Parameter(ParameterSetName = 'Query')]
        [uint64[]]$Device_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string[]]$Device,

        [Parameter(ParameterSetName = 'Query')]
        [uint64[]]$Device_Type_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64[]]$Module_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64[]]$Site_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string[]]$Site,

        [Parameter(ParameterSetName = 'Query')]
        [uint64[]]$Location_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64[]]$Rack_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string[]]$Type,

        [Parameter(ParameterSetName = 'Query')]
        [decimal[]]$Diameter,

        [Parameter(ParameterSetName = 'Query')]
        [string[]]$Diameter_Unit,

        [Parameter(ParameterSetName = 'Query')]
        [decimal[]]$Max_Flow,

        [Parameter(ParameterSetName = 'Query')]
        [string[]]$Max_Flow_Unit,

        [Parameter(ParameterSetName = 'Query')]
        [uint64[]]$Cooling_Outflow_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string[]]$Description,

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
        Write-Verbose "Retrieving DCIM Cooling Intake"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cooling-intakes', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'All', 'PageSize'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cooling-intakes'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
