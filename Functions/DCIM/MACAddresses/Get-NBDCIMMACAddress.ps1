<#
.SYNOPSIS
    Retrieves MACAddresses objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves MACAddresses objects from Netbox DCIM module.

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

.PARAMETER Mac_Address
    Filter by MAC address.

.PARAMETER Assigned_Object_Id
    Filter by assigned object database ID.

.PARAMETER Assigned_Object_Type
    Filter by assigned object type.

.PARAMETER Device_Id
    Filter by device database ID.

.PARAMETER Virtual_Machine_Id
    Filter by virtual machine database ID.

.PARAMETER Query
    Free-text search across the object (NetBox 'q' parameter).

.PARAMETER Limit
    Maximum number of results to return per request (1-1000).

.PARAMETER Offset
    Number of results to skip (pagination offset).

.EXAMPLE
    Get-NBDCIMMACAddress

.NOTES
    AddedInVersion: v4.4.10.0
    The -Brief, -Fields, and -Omit parameters are mutually exclusive.
.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMMACAddress {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param(
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [switch]$Brief,

        [string[]]$Fields,

        [string[]]$Omit,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)][uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')][string]$Mac_Address,
        [Parameter(ParameterSetName = 'Query')][uint64]$Assigned_Object_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Assigned_Object_Type,
        [Parameter(ParameterSetName = 'Query')][uint64]$Device_Id,
        [Parameter(ParameterSetName = 'Query')][uint64]$Virtual_Machine_Id,
        [Parameter(ParameterSetName = 'Query')][string]$Query,
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
        Write-Verbose "Retrieving DCIM MAC Address"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','mac-addresses',$i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim','mac-addresses'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'
                InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}