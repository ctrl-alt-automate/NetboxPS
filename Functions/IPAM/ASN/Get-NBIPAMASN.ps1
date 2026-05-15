function Get-NBIPAMASN {
<#
    .SYNOPSIS
        Get ASNs from Netbox

    .DESCRIPTION
        Retrieves ASN (Autonomous System Number) objects from Netbox with optional filtering.

    .PARAMETER Id
        The ID of the ASN to retrieve

    .PARAMETER ASN
        Filter by ASN number

    .PARAMETER Query
        A general search query

    .PARAMETER RIR_Id
        Filter by RIR ID

    .PARAMETER Tenant_Id
        Filter by tenant ID

    .PARAMETER Site_Id
        Filter by site ID

    .PARAMETER Role_Id
        Filter by role ID (NetBox 4.6+)

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
        Get-NBIPAMASN

        Returns all ASNs

    .EXAMPLE
        Get-NBIPAMASN -ASN 65001

        Returns ASN 65001
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
        [uint64]$ASN,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$RIR_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Tenant_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Site_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Role_Id,

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
        Write-Verbose "Retrieving IPAM ASN"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($ASNId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('ipam', 'asns', $ASNId))

                    $URI = BuildNewURI -Segments $Segments

                    InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('ipam', 'asns'))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}