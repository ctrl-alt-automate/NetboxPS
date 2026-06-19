
function Get-NBCircuit {
    <#
    .SYNOPSIS
        Gets one or more circuits

    .DESCRIPTION
        Retrieves circuit objects from Netbox. Circuits represent physical or virtual
        connections between sites, typically provided by external carriers or ISPs.

    .PARAMETER Id
        Database ID of circuit. This will query for exactly the IDs provided

    .PARAMETER CID
        Circuit ID. Also accepts -Name alias for consistency with other Get- functions.

    .PARAMETER InstallDate
        Date of installation

    .PARAMETER CommitRate
        Committed rate in Kbps

    .PARAMETER Query
        A raw search query... As if you were searching the web site

    .PARAMETER Provider
        The name or database ID of the provider.
        - String: Searches by provider name (e.g., 'Comcast')
        - Integer: Searches by database ID (e.g., 1)

    .PARAMETER Type
        The name or database ID of the circuit type.
        - String: Searches by type name (e.g., 'Internet')
        - Integer: Searches by database ID (e.g., 1)

    .PARAMETER Site
        Location/site of circuit. Provide either [string] or [uint64]. String will search site names, integer will search database IDs

    .PARAMETER Tenant
        Tenant assigned to circuit. Provide either [string] or [uint64]. String will search tenant names, integer will search database IDs

    .PARAMETER Limit
        Maximum number of results to return (1-1000). Default is determined by Netbox server.

    .PARAMETER Offset
        Number of results to skip before returning. Use with Limit for pagination.

    .PARAMETER Raw
        Return the raw API response instead of extracting the results array.

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
        PS C:\> Get-NBCircuit
.NOTES
    AddedInVersion: v1.3.3


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

        [Parameter(ParameterSetName = 'ById')]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [Alias('Name')]
        [string]$CID,

        [Parameter(ParameterSetName = 'Query')]
        [datetime]$InstallDate,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$CommitRate,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [Alias('ProviderId', 'Provider_Id')]
        [object]$Provider,

        [Parameter(ParameterSetName = 'Query')]
        [Alias('TypeId', 'Type_Id')]
        [object]$Type,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Site,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Tenant,

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
        Write-Verbose "Retrieving Circuit"
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($i in $ID) {
                    $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuits', $i))

                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'All', 'PageSize'

                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                    InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuits'))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}