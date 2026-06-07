<#
.SYNOPSIS
    Retrieves Address objects from Netbox IPAM module.

.DESCRIPTION
    Retrieves Address objects from Netbox IPAM module.

.PARAMETER Omit
    Specify which fields to exclude from the response.
    Requires Netbox 4.5.0 or later.

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

.PARAMETER Address
    Filter by address.

.PARAMETER Id
    One or more database IDs to retrieve.

.PARAMETER Query
    Free-text search across the object (NetBox 'q' parameter).

.PARAMETER Family
    Filter by family.

.PARAMETER Parent
    Filter by parent object (name or slug).

.PARAMETER Mask_Length
    Filter by mask length.

.PARAMETER VRF
    Filter by VRF (name or slug).

.PARAMETER VRF_Id
    Filter by vrf database ID.

.PARAMETER Tenant
    Filter by tenant (name or slug).

.PARAMETER Tenant_Id
    Filter by tenant database ID.

.PARAMETER Device
    Filter by device (name or slug).

.PARAMETER Device_ID
    Filter by device database ID.

.PARAMETER Virtual_Machine
    Filter by virtual machine (name or slug).

.PARAMETER Virtual_Machine_Id
    Filter by virtual machine database ID.

.PARAMETER Interface_Id
    Filter by interface database ID.

.PARAMETER Status
    Filter by operational status.

.PARAMETER Role
    Filter by role (name or slug).

.PARAMETER Limit
    Maximum number of results to return per request (1-1000).

.PARAMETER Offset
    Number of results to skip (pagination offset).

.EXAMPLE
    Get-NBIPAMAddress

.EXAMPLE
    Get-NBIPAMAddress -Omit 'comments','description'
    Returns addresses without comments and description fields (Netbox 4.5+).

.NOTES
    AddedInVersion: v1.0.4
    The -Brief, -Fields, and -Omit parameters are mutually exclusive.
.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBIPAMAddress {
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
        [string]$Address,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet(4, 6)]
        [int]$Family,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Parent,

        [Parameter(ParameterSetName = 'Query')]
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
        [string]$Device,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Device_ID,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Virtual_Machine,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Virtual_Machine_Id,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Interface_Id,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('active', 'reserved', 'deprecated', 'dhcp', 'slaac', IgnoreCase = $true)]
        [string]$Status,

        [Parameter(ParameterSetName = 'Query')]
        [ValidateSet('loopback', 'secondary', 'anycast', 'vip', 'vrrp', 'hsrp', 'glbp', 'carp', IgnoreCase = $true)]
        [string]$Role,

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

        Write-Verbose "Retrieving IPAM Address"
        switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            foreach ($IP_ID in $Id) {
                $Segments = [System.Collections.ArrayList]::new(@('ipam', 'ip-addresses', $IP_ID))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'All', 'PageSize'

                $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $uri -Raw:$Raw -All:$All -PageSize $PageSize
            }

            break
        }

        default {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'ip-addresses'))

            $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'

            $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

            InvokeNetboxRequest -URI $uri -Raw:$Raw -All:$All -PageSize $PageSize
            break
        }
    }
    }
}
