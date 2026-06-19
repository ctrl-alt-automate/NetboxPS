<#
.SYNOPSIS
    Retrieves Devices objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Devices objects from Netbox DCIM module.

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

.PARAMETER Offset
    Number of results to skip (pagination offset).

.PARAMETER Limit
    Maximum number of results to return per request (1-1000).

.PARAMETER Id
    One or more database IDs to retrieve.

.PARAMETER Query
    Free-text search across the object (NetBox 'q' parameter).

.PARAMETER Slug
    Filter by URL slug.

.PARAMETER Manufacturer
    Filter by manufacturer (name or slug).

.PARAMETER Manufacturer_Id
    Filter by manufacturer database ID.

.PARAMETER Model
    Filter by model.

.PARAMETER Part_Number
    Discrete part number (optional)

.PARAMETER U_Height
    Height in rack units

.PARAMETER Is_Full_Depth
    Device consumes both front and rear rack faces.

.PARAMETER Is_Console_Server
    Filter by is console server.

.PARAMETER Is_PDU
    Filter by is pdu.

.PARAMETER Is_Network_Device
    Filter by is network device.

.PARAMETER Subdevice_Role
    Filter by subdevice role.

.EXAMPLE
    Get-NBDCIMDeviceType

.NOTES
    AddedInVersion: v1.0.4
    The -Brief, -Fields, and -Omit parameters are mutually exclusive.
.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMDeviceType {
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

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Slug,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Manufacturer,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Manufacturer_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Model,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Part_Number,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$U_Height,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Is_Full_Depth,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Is_Console_Server,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Is_PDU,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Is_Network_Device,

        [Parameter(ParameterSetName = 'Query')]
        [uint16]$Subdevice_Role,

        [switch]$Raw
    )

    #endregion Parameters

    process {
        AssertNBMutualExclusiveParam `
            -BoundParameters $PSBoundParameters `
            -Parameters 'Brief', 'Fields', 'Omit'
        Write-Verbose "Retrieving DCIM Device Type"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim', 'device-types', $i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'device-types'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}