
function Get-NBIPAMPrefix {
<#
    .SYNOPSIS
        Retrieves IP prefixes from Netbox IPAM module.

    .DESCRIPTION
        Retrieves IP prefix objects from Netbox. Prefixes represent IP network ranges
        (IPv4 or IPv6) and can be organized hierarchically within VRFs.

    .PARAMETER Query
        General search query to match prefixes.

    .PARAMETER Id
        Database ID of the prefix.

    .PARAMETER Limit
        Maximum number of results to return (1-1000).

    .PARAMETER Offset
        Number of results to skip for pagination.

    .PARAMETER Family
        IP address family (4 for IPv4, 6 for IPv6).

    .PARAMETER Is_Pool
        Filter for prefixes marked as IP pools.

    .PARAMETER Within
        Return prefixes within a parent prefix (CIDR notation, e.g., '10.0.0.0/16').

    .PARAMETER Within_Include
        Return prefixes within or equal to a prefix (CIDR notation, e.g., '10.0.0.0/16').

    .PARAMETER Contains
        Return prefixes containing an IP or subnet.

    .PARAMETER Mask_Length
        CIDR mask length value.

    .PARAMETER VRF
        Filter by VRF name.

    .PARAMETER VRF_Id
        Filter by VRF database ID.

    .PARAMETER Tenant
        Filter by tenant name.

    .PARAMETER Tenant_Id
        Filter by tenant database ID.

    .PARAMETER Scope_Type
        Filter by scope type (e.g., 'dcim.site', 'dcim.region', 'dcim.sitegroup', 'dcim.location').

    .PARAMETER Scope_Id
        Filter by scope object database ID.

    .PARAMETER Vlan_VId
        Filter by VLAN ID number.

    .PARAMETER Vlan_Id
        Filter by VLAN database ID.

    .PARAMETER Status
        Filter by prefix status (e.g., 'active', 'reserved', 'deprecated').

    .PARAMETER Role
        Filter by IPAM role name.

    .PARAMETER Role_Id
        Filter by IPAM role database ID.

    .PARAMETER Omit
        Specify which fields to exclude from the response.
        Requires Netbox 4.5.0 or later.

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

    .PARAMETER Prefix
        Filter by prefix (name or slug).

    .EXAMPLE
        PS C:\> Get-NBIPAMPrefix

    .EXAMPLE
        PS C:\> Get-NBIPAMPrefix -Omit 'description','comments'
        Returns prefixes without description and comments fields (Netbox 4.5+).
.NOTES
    AddedInVersion: v1.0.4
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

        [Parameter(ParameterSetName = 'Query',
                   Position = 0)]
        [string]$Prefix,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'ByID',
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet(4, 6)]
        [int]$Family,

        [Parameter(ParameterSetName = 'Query')]
        [boolean]$Is_Pool,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Within,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Within_Include,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Contains,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateRange(0, 127)]
        [byte]$Mask_Length,

        [Parameter(ParameterSetName = 'Query')]
        [string]$VRF,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$VRF_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Tenant,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Tenant_Id,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('dcim.region', 'dcim.sitegroup', 'dcim.site', 'dcim.location', IgnoreCase = $true)]
        [string]$Scope_Type,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Scope_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Vlan_VId,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Vlan_Id,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('container', 'active', 'reserved', 'deprecated', IgnoreCase = $true)]
        [string]$Status,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Role,

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
        Write-Verbose "Retrieving IPAM Prefix"

        switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($Prefix_ID in $Id) {
                $Segments = [System.Collections.ArrayList]::new(@('ipam', 'prefixes', $Prefix_ID))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'All', 'PageSize'

                $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $uri -Raw:$Raw -All:$All -PageSize $PageSize
            }

            break
        }

        default {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'prefixes'))

            $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'

            $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $uri -Raw:$Raw -All:$All -PageSize $PageSize
            break
        }
    }
    }
}