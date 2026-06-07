<#
.SYNOPSIS
    Retrieves Devices objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves Devices objects from Netbox DCIM module.
    Supports automatic pagination with the -All switch.

    By default, config_context is excluded from the response for performance.
    Use -IncludeConfigContext to include it when needed.

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

.PARAMETER IncludeConfigContext
    Include config_context in the response. By default, config_context is
    excluded for performance (can be 10-100x faster without it).

.PARAMETER Query
    Search query (maps to the 'q' API filter). Matches against device name
    and primary IP address. Note: in Netbox 4.5.3+, this only matches the
    primary IP, not all assigned IPs.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Limit
    Maximum number of results to return per request (1-1000).

.PARAMETER Offset
    Number of results to skip (pagination offset).

.PARAMETER Id
    One or more database IDs to retrieve.

.PARAMETER Name
    Filter by name.

.PARAMETER Manufacturer_Id
    Filter by manufacturer database ID.

.PARAMETER Manufacturer
    Filter by manufacturer (name or slug).

.PARAMETER Device_Type_Id
    Filter by device type database ID.

.PARAMETER Role_Id
    Filter by role database ID.

.PARAMETER Role
    Filter by role (name or slug).

.PARAMETER Tenant_Id
    Filter by tenant database ID.

.PARAMETER Tenant
    Filter by tenant (name or slug).

.PARAMETER Platform_Id
    Filter by platform database ID.

.PARAMETER Platform
    Filter by platform (name or slug).

.PARAMETER Asset_Tag
    Filter by asset tag.

.PARAMETER Site_Id
    Filter by site database ID.

.PARAMETER Site
    Filter by site (name or slug).

.PARAMETER Rack_Group_Id
    Filter by rack group database ID.

.PARAMETER Rack_Id
    Filter by rack database ID.

.PARAMETER Cluster_Id
    Filter by cluster database ID.

.PARAMETER Model
    Filter by model.

.PARAMETER Status
    Filter by operational status.

.PARAMETER Is_Full_Depth
    Device consumes both front and rear rack faces.

.PARAMETER Is_Console_Server
    Filter by is console server.

.PARAMETER Is_PDU
    Filter by is pdu.

.PARAMETER Is_Network_Device
    Filter by is network device.

.PARAMETER MAC_Address
    Filter by MAC address.

.PARAMETER Has_Primary_IP
    Filter by has primary ip.

.PARAMETER Virtual_Chassis_Id
    Filter by virtual chassis database ID.

.PARAMETER Position
    Filter by position.

.PARAMETER Serial
    Filter by serial number.

.EXAMPLE
    Get-NBDCIMDevice
    Returns the first page of devices (config_context excluded by default).

.EXAMPLE
    Get-NBDCIMDevice -All
    Returns all devices with automatic pagination.

.EXAMPLE
    Get-NBDCIMDevice -Brief
    Returns minimal device representations for dropdowns.

.EXAMPLE
    Get-NBDCIMDevice -Fields 'id','name','status','site.name'
    Returns only the specified fields.

.EXAMPLE
    Get-NBDCIMDevice -IncludeConfigContext
    Returns devices with config_context included.

.EXAMPLE
    Get-NBDCIMDevice -Omit 'comments','description'
    Returns devices without comments and description fields (Netbox 4.5+).

.EXAMPLE
    Get-NBDCIMDevice -All -PageSize 200 -Verbose
    Returns all devices with 200 items per request, showing progress.

.NOTES
    AddedInVersion: v1.0.4
    The -Brief, -Fields, and -Omit parameters are mutually exclusive.
.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMDevice {
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

        [switch]$IncludeConfigContext,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Manufacturer_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Manufacturer,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Device_Type_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Role_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Role,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Tenant_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Tenant,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Platform_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Platform,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Asset_Tag,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Site_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Site,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Rack_Group_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Rack_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Cluster_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Model,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('offline', 'active', 'planned', 'staged', 'failed', 'inventory', 'decommissioning', IgnoreCase = $true)]
        [string]$Status,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Is_Full_Depth,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Is_Console_Server,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Is_PDU,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Is_Network_Device,

        [Parameter(ParameterSetName = 'Query')]
        [string]$MAC_Address,

        [Parameter(ParameterSetName = 'Query')]
        [bool]$Has_Primary_IP,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Virtual_Chassis_Id,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateRange(0.5, 999.99)]
        [double]$Position,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Serial,

        [switch]$Raw
    )

    #endregion Parameters

    process {
        AssertNBMutualExclusiveParam `
            -BoundParameters $PSBoundParameters `
            -Parameters 'Brief', 'Fields', 'Omit'

        Write-Verbose "Retrieving DCIM Device"

        # Auto-omit config_context only when the user has not otherwise
        # restricted the projection. -Brief returns a minimal representation
        # (config_context is never included). -Fields explicitly selects the
        # returned shape, so the user owns that choice.
        $inProjectionMode = $PSBoundParameters.ContainsKey('Brief') -or
                            $PSBoundParameters.ContainsKey('Fields')

        $omitFields = @()
        if ($PSBoundParameters.ContainsKey('Omit')) {
            $omitFields += $Omit
        }
        if (-not $IncludeConfigContext -and -not $inProjectionMode) {
            $omitFields += 'config_context'
        }

        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('dcim', 'devices', $i))
                    $paramsToPass = @{}
                    if ($omitFields.Count -gt 0) {
                        $paramsToPass['Omit'] = $omitFields | Select-Object -Unique
                    }
                    if ($PSBoundParameters.ContainsKey('Brief')) { $paramsToPass['Brief'] = $Brief }
                    if ($PSBoundParameters.ContainsKey('Fields')) { $paramsToPass['Fields'] = $Fields }
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $paramsToPass -SkipParameterByName 'Id', 'Raw', 'All', 'PageSize'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'devices'))
                $paramsToPass = @{} + $PSBoundParameters
                if ($omitFields.Count -gt 0) {
                    $paramsToPass['Omit'] = $omitFields | Select-Object -Unique
                }
                [void]$paramsToPass.Remove('IncludeConfigContext')
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $paramsToPass -SkipParameterByName 'Raw', 'All', 'PageSize'
                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
