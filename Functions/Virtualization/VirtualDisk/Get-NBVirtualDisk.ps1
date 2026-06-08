<#
.SYNOPSIS
    Retrieve virtual disks from Netbox Virtualization.

.DESCRIPTION
    Returns virtual disks (NetBox 4.0+). A VirtualDisk represents a
    disk attached to a virtual machine.

.PARAMETER Id
    One or more virtual disk database IDs (detail endpoint).

.PARAMETER Name
    Filter by name.

.PARAMETER Virtual_Machine_Id
    Filter by the parent virtual machine ID.

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

.PARAMETER All
    Retrieve all matching results, following pagination automatically.

.PARAMETER PageSize
    Page size to request while -All follows pagination.

.PARAMETER Limit
    Maximum number of results to return per request (1-1000).

.PARAMETER Offset
    Number of results to skip (pagination offset).

.EXAMPLE
    Get-NBVirtualDisk -Virtual_Machine_Id 42

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.6.0.1

#>
function Get-NBVirtualDisk {
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
        [uint64]$Virtual_Machine_Id,

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

        Write-Verbose "Retrieving Virtual Disk"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($VirtualDiskId in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'virtual-disks', $VirtualDiskId))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'All', 'PageSize'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'virtual-disks'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
