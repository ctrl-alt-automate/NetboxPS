
function Get-NBVirtualMachine {
    <#
    .SYNOPSIS
        Obtains virtual machines from Netbox.

    .DESCRIPTION
        Obtains one or more virtual machines based on provided filters.

        By default, config_context is excluded from the response for performance.
        Use -IncludeConfigContext to include it when needed.

    .PARAMETER All
        Automatically fetch all pages of results.

    .PARAMETER PageSize
        Number of items per page when using -All. Default: 100.

    .PARAMETER Brief
        Return a minimal representation of objects (id, url, display, name only).
        Reduces response size by ~90%. Ideal for dropdowns and reference lists.

    .PARAMETER Fields
        Specify which fields to include in the response.
        Supports nested field selection (e.g., 'site.name', 'cluster.name').

    .PARAMETER Omit
        Specify which fields to exclude from the response.
        Requires Netbox 4.5.0 or later.

    .PARAMETER IncludeConfigContext
        Include config_context in the response. By default, config_context is
        excluded for performance (can be 10-100x faster without it).

    .PARAMETER Limit
        Number of results to return per page

    .PARAMETER Offset
        The initial index from which to return the results

    .PARAMETER Query
        Search query (maps to the 'q' API filter). Matches against VM name
        and primary IP address. Note: in Netbox 4.5.3+, this only matches the
        primary IP, not all assigned IPs.

    .PARAMETER Name
        Name of the VM

    .PARAMETER Id
        Database ID of the VM

    .PARAMETER Status
        Status of the VM

    .PARAMETER Tenant
        String value of tenant

    .PARAMETER Tenant_ID
        Database ID of the tenant.

    .PARAMETER Platform
        String value of the platform

    .PARAMETER Platform_ID
        Database ID of the platform

    .PARAMETER Cluster_Group
        String value of the cluster group.

    .PARAMETER Cluster_Group_Id
        Database ID of the cluster group.

    .PARAMETER Cluster_Type
        String value of the Cluster type.

    .PARAMETER Cluster_Type_Id
        Database ID of the cluster type.

    .PARAMETER Cluster_Id
        Database ID of the cluster.

    .PARAMETER Device
        The string value of the device the VMs are are attached to. (Netbox 4.6+).

    .PARAMETER Device_Id
        The device Id of the device the VMs are attached to. (Netbox 4.6+).

    .PARAMETER Site
        String value of the site.

    .PARAMETER Site_Id
        Database ID of the site.

    .PARAMETER Role
        String value of the role.

    .PARAMETER Role_Id
        Database ID of the role.

    .PARAMETER Serial
        Serial number of the VM. You can query multiple serial numbers by separating them with commas (e.g., "12345","67890").

    .PARAMETER Virtual_Machine_Type
        String value of the virtual machine type (Slug). (Netbox 4.6+)

    .PARAMETER Virtual_Machine_Type_Id
        Database ID of the virtual machine type. (Netbox 4.6+)
    .PARAMETER Raw
        Return the raw API response instead of extracting the results array.

    .EXAMPLE
        Get-NBVirtualMachine
        Returns VMs with config_context excluded by default.

    .EXAMPLE
        Get-NBVirtualMachine -Brief
        Returns minimal VM representations for dropdowns.

    .EXAMPLE
        Get-NBVirtualMachine -IncludeConfigContext
        Returns VMs with config_context included.

    .EXAMPLE
        Get-NBVirtualMachine -Fields 'id','name','status','site.name'
        Returns only the specified fields.

    .EXAMPLE
        Get-NBVirtualMachine -Omit 'comments','description'
        Returns VMs without comments and description fields (Netbox 4.5+).
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

        [switch]$IncludeConfigContext,

        [Parameter(ParameterSetName = 'Query')]
        [Alias('q')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [string[]]$Name,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('offline', 'active', 'planned', 'staged', 'failed', 'decommissioning', 'paused', IgnoreCase = $true)]
        [string[]]$Status,

        [Parameter(ParameterSetName = 'Query')]
        [string[]]$Tenant,

        [Parameter(ParameterSetName = 'Query')]
        [uint64[]]$Tenant_ID,

        [Parameter(ParameterSetName = 'Query')]
        [string[]]$Platform,

        [Parameter(ParameterSetName = 'Query')]
        [uint64[]]$Platform_ID,

        [Parameter(ParameterSetName = 'Query')]
        [string[]]$Cluster_Group,

        [Parameter(ParameterSetName = 'Query')]
        [uint64[]]$Cluster_Group_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string[]]$Cluster_Type,

        [Parameter(ParameterSetName = 'Query')]
        [uint64[]]$Cluster_Type_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64[]]$Cluster_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string[]]$Device,

        [Parameter(ParameterSetName = 'Query')]
        [uint64[]]$Device_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string[]]$Site,

        [Parameter(ParameterSetName = 'Query')]
        [uint64[]]$Site_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string[]]$Role,

        [Parameter(ParameterSetName = 'Query')]
        [uint64[]]$Role_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string[]]$Virtual_Machine_Type,

        [Parameter(ParameterSetName = 'Query')]
        [uint64[]]$Virtual_Machine_Type_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string[]]$Serial,

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

        Write-Verbose "Retrieving Virtual Machine"

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
                    $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'virtual-machines', $i))
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
                $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'virtual-machines'))
                $paramsToPass = @{} + $PSBoundParameters
                if ($omitFields.Count -gt 0) {
                    $paramsToPass['Omit'] = $omitFields | Select-Object -Unique
                }
                [void]$paramsToPass.Remove('IncludeConfigContext')
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $paramsToPass -SkipParameterByName 'Raw', 'All', 'PageSize'
                $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                InvokeNetboxRequest -URI $uri -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
