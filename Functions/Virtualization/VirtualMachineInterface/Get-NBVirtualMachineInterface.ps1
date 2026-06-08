
function Get-NBVirtualMachineInterface {
    <#
    .SYNOPSIS
        Gets VM interfaces

    .DESCRIPTION
        Obtains the interface objects for one or more VMs

    .PARAMETER Limit
        Number of results to return per page.

    .PARAMETER Offset
        The initial index from which to return the results.

    .PARAMETER Id
        Database ID of the interface

    .PARAMETER Name
        Name of the interface

    .PARAMETER Enabled
        True/False if the interface is enabled

    .PARAMETER MTU
        Maximum Transmission Unit size. Generally 1500 or 9000

    .PARAMETER Virtual_Machine_Id
        ID of the virtual machine to which the interface(s) are assigned.

    .PARAMETER Virtual_Machine
        Name of the virtual machine to get interfaces

    .PARAMETER MAC_Address
        MAC address assigned to the interface

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

    .PARAMETER Query
        Free-text search across the object (NetBox 'q' parameter).

    .EXAMPLE
        PS C:\> Get-NBVirtualMachineInterface
.NOTES
    AddedInVersion: v1.0.4

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

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [boolean]$Enabled,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$MTU,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Virtual_Machine_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Virtual_Machine,

        [Parameter(ParameterSetName = 'Query')]
        [string]$MAC_Address,

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
        Write-Verbose "Retrieving Virtual Machine Interface"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('virtualization', 'interfaces', $i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'interfaces'))
                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'
                $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $uri -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}