<#
.SYNOPSIS
    Retrieves Tunnel objects from Netbox VPN module.

.DESCRIPTION
    Retrieves Tunnel objects from Netbox VPN module.

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

.PARAMETER Id
    One or more database IDs to retrieve.

.PARAMETER Name
    Filter by name.

.PARAMETER Query
    Free-text search across the object (NetBox 'q' parameter).

.PARAMETER Status
    Filter by operational status.

.PARAMETER Group_Id
    Filter by group database ID.

.PARAMETER Encapsulation
    Filter by encapsulation.

.PARAMETER Limit
    Maximum number of results to return per request (1-1000).

.PARAMETER Offset
    Number of results to skip (pagination offset).

.EXAMPLE
    Get-NBVPNTunnel

.NOTES
    AddedInVersion: v4.4.10.0
    The -Brief, -Fields, and -Omit parameters are mutually exclusive.
.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBVPNTunnel {
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

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Name,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
        [Parameter(ParameterSetName = 'Query')][string]$Status,
        [Parameter(ParameterSetName = 'Query')][uint64]$Group_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Encapsulation,
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

        Write-Verbose "Retrieving VPN Tunnel"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($TunnelId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('vpn', 'tunnels', $TunnelId))
                    $URI = BuildNewURI -Segments $Segments
                    InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('vpn', 'tunnels'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
