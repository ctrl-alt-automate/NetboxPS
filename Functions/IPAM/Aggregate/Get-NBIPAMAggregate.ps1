<#
.SYNOPSIS
    Retrieves Aggregate objects from Netbox IPAM module.

.DESCRIPTION
    Retrieves Aggregate objects from Netbox IPAM module.

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

.PARAMETER Query
    Free-text search across the object (NetBox 'q' parameter).

.PARAMETER Id
    One or more database IDs to retrieve.

.PARAMETER Prefix
    Filter by prefix (name or slug).

.PARAMETER Family
    Filter by family.

.PARAMETER RIR_Id
    Filter by rir database ID.

.PARAMETER RIR
    Filter by rir.

.PARAMETER Date_Added
    Filter by date added.

.PARAMETER Limit
    Maximum number of results to return per request (1-1000).

.PARAMETER Offset
    Number of results to skip (pagination offset).

.EXAMPLE
    Get-NBIPAMAggregate

.NOTES
    AddedInVersion: v1.0.4
    The -Brief, -Fields, and -Omit parameters are mutually exclusive.
.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBIPAMAggregate {
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

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Prefix,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet(4, 6)]
        [int]$Family,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$RIR_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$RIR,

        [Parameter(ParameterSetName = 'Query')]
        [datetime]$Date_Added,

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

        Write-Verbose "Retrieving IPAM Aggregate"

        switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($IP_ID in $Id) {
                $Segments = [System.Collections.ArrayList]::new(@('ipam', 'aggregates', $IP_ID))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'All', 'PageSize'

                $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $uri -Raw:$Raw -All:$All -PageSize $PageSize
            }
            break
        }

        default {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'aggregates'))

            $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'

            $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $uri -Raw:$Raw -All:$All -PageSize $PageSize
            break
        }
    }
    }
}
