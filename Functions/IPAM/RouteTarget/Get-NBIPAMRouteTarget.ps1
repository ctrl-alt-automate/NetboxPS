function Get-NBIPAMRouteTarget {
<#
    .SYNOPSIS
        Get route targets from Netbox

    .DESCRIPTION
        Retrieves route target objects from Netbox with optional filtering.
        Route targets are used for VRF import/export policies.

    .PARAMETER Id
        The ID of the route target to retrieve

    .PARAMETER Name
        Filter by route target name (RFC 4360 format)

    .PARAMETER Query
        A general search query

    .PARAMETER Tenant_Id
        Filter by tenant ID

    .PARAMETER Tenant
        Filter by tenant name

    .PARAMETER Importing_VRF_Id
        Filter by VRF ID that imports this target

    .PARAMETER Exporting_VRF_Id
        Filter by VRF ID that exports this target

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
        Get-NBIPAMRouteTarget

        Returns all route targets

    .EXAMPLE
        Get-NBIPAMRouteTarget -Name "65001:100"

        Returns route targets matching the specified value
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
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Tenant_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Tenant,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Importing_VRF_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Exporting_VRF_Id,

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
        Write-Verbose "Retrieving IPAM Route Target"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($RTId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('ipam', 'route-targets', $RTId))

                    $URI = BuildNewURI -Segments $Segments

                    InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('ipam', 'route-targets'))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}