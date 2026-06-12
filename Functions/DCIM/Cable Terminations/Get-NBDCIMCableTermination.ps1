<#
.SYNOPSIS
    Retrieves Cable Terminations objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Cable Terminations objects from Netbox DCIM module.

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

.PARAMETER Limit
    Maximum number of results to return per request (1-1000).

.PARAMETER Offset
    Number of results to skip (pagination offset).

.PARAMETER Id
    One or more database IDs to retrieve.

.PARAMETER Cable
    Filter by cable.

.PARAMETER Cable_End
    Filter by cable end.

.PARAMETER Termination_Type
    Filter by termination type.

.PARAMETER Termination_ID
    Filter by termination database ID.

.EXAMPLE
    Get-NBDCIMCableTermination

.NOTES
    AddedInVersion: v4.4.7
    The -Brief, -Fields, and -Omit parameters are mutually exclusive.
.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMCableTermination {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    #region Parameters
    param
    (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [switch]$Brief,

        [string[]]$Fields,

        [string[]]$Omit,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Cable,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Cable_End,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Termination_Type,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Termination_ID,

        [switch]$Raw
    )

    #endregion Parameters

    process {
        AssertNBMutualExclusiveParam `
            -BoundParameters $PSBoundParameters `
            -Parameters 'Brief', 'Fields', 'Omit'
        Write-Verbose "Retrieving DCIM Cable Termination"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cable-terminations'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'

        $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
    }
}