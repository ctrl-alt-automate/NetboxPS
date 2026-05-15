<#
.SYNOPSIS
    Retrieve cable bundles from Netbox DCIM.

.DESCRIPTION
    Returns cable bundles (NetBox 4.6+). A CableBundle groups individual
    cables that are managed as a single physical run (e.g. a bundle of
    48 CAT6 cables between two patch panels). It is NOT for modeling
    individual fiber strands within one cable.

.PARAMETER Id
    One or more cable bundle database IDs (detail endpoint).

.PARAMETER Name
    Filter by name.

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
    Get-NBDCIMCableBundle -Name 'PP1-PP2 trunk'

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.6.0.1

#>
function Get-NBDCIMCableBundle {
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

        Write-Verbose "Retrieving DCIM Cable Bundle"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($CableBundleId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cable-bundles', $CableBundleId))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'All', 'PageSize'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cable-bundles'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
