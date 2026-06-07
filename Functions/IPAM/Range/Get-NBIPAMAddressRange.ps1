<#
.SYNOPSIS
    Retrieves Range objects from Netbox IPAM module.

.DESCRIPTION
    Retrieves Range objects from Netbox IPAM module.

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
    Supports nested field selection (e.g., 'site.name', 'device_type.model').

.PARAMETER Omit
    Specify which fields to exclude from the response.
    Requires Netbox 4.5.0 or later.

.PARAMETER Range
    Filter by range.

.PARAMETER Id
    One or more database IDs to retrieve.

.PARAMETER Query
    Free-text search across the object (NetBox 'q' parameter).

.PARAMETER Family
    Filter by family.

.PARAMETER VRF
    Filter by VRF (name or slug).

.PARAMETER VRF_Id
    Filter by vrf database ID.

.PARAMETER Tenant
    Filter by tenant (name or slug).

.PARAMETER Tenant_Id
    Filter by tenant database ID.

.PARAMETER Status
    Filter by operational status.

.PARAMETER Role
    Filter by role (name or slug).

.PARAMETER Parent
    Filter by parent object (name or slug).

.PARAMETER Mark_Utilized
    Filter by mark utilized.

.PARAMETER Mark_Populated
    Prevent the creation of IP addresses within this range

.PARAMETER Limit
    Maximum number of results to return per request (1-1000).

.PARAMETER Offset
    Number of results to skip (pagination offset).

.EXAMPLE
    Get-NBIPAMAddressRange

.NOTES
    AddedInVersion: v1.0.4
    The -Brief, -Fields, and -Omit parameters are mutually exclusive.
.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBIPAMAddressRange {
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

        [Parameter(ParameterSetName = 'Query',
                   Position = 0)]
        [string]$Range,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet(4, 6)]
        [int]$Family,

        [Parameter(ParameterSetName = 'Query')]
        [string]$VRF,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$VRF_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Tenant,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Tenant_Id,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('active', 'reserved', 'deprecated', IgnoreCase = $true)]
        [string]$Status,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Role,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Parent,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Mark_Utilized,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Mark_Populated,

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
        Write-Verbose "Retrieving IPAM Address Range"
        switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($Range_ID in $Id) {
                $Segments = [System.Collections.ArrayList]::new(@('ipam', 'ip-ranges', $Range_ID))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'All', 'PageSize'

                $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $uri -Raw:$Raw -All:$All -PageSize $PageSize
            }

            break
        }

        default {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'ip-ranges'))

            $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'

            $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $uri -Raw:$Raw -All:$All -PageSize $PageSize
            break
        }
    }
    }
}