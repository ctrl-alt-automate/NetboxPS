<#
.SYNOPSIS
    Retrieve rack groups from Netbox DCIM.

.DESCRIPTION
    Returns rack groups (NetBox 4.6+). A RackGroup is a flat,
    location-independent grouping axis for racks (e.g. by row or aisle).

.PARAMETER Id
    One or more rack group database IDs (detail endpoint).

.PARAMETER Name
    Filter by name.

.PARAMETER Slug
    Filter by slug.

.PARAMETER Query
    Free-text search filter (NetBox ?q= parameter).

.PARAMETER Brief
    Return the brief representation.

.PARAMETER Fields
    Return only the specified fields.

.PARAMETER Omit
    Return all fields except the specified ones.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Get-NBDCIMRackGroup -Name 'Row A'

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.6.0.1

#>
function Get-NBDCIMRackGroup {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [Parameter(ParameterSetName = 'ByID',
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Slug,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Brief,

        [string[]]$Fields,

        [string[]]$Omit,

        [switch]$Raw
    )

    process {
        AssertNBMutualExclusiveParam -BoundParameters $PSBoundParameters -Parameters 'Brief', 'Fields', 'Omit'

        Write-Verbose "Retrieving DCIM Rack Group"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($RackGroupId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('dcim', 'rack-groups', $RackGroupId))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'All', 'PageSize'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'rack-groups'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
