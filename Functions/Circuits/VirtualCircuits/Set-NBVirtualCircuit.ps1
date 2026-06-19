<#
.SYNOPSIS
    Updates an existing virtual circuit in Netbox.

.DESCRIPTION
    Updates an existing virtual circuit in Netbox.

.PARAMETER Id
    The ID of the virtual circuit to update.

.PARAMETER Cid
    Circuit ID string.

.PARAMETER Provider_Network
    Provider network ID.

.PARAMETER Provider_Account
    Provider account ID.

.PARAMETER Type
    Virtual circuit type ID.

.PARAMETER Status
    Status (planned, provisioning, active, offline, deprovisioning, decommissioned).

.PARAMETER Tenant
    Tenant ID.

.PARAMETER Description
    Description.

.PARAMETER Comments
    Comments.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    Set-NBVirtualCircuit -Id 1 -Status "active"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBVirtualCircuit {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Cid,

        [uint64]$Provider_Network,

        [uint64]$Provider_Account,

        [uint64]$Type,

        [ValidateSet('planned', 'provisioning', 'active', 'offline', 'deprovisioning', 'decommissioned')]
        [string]$Status,

        [uint64]$Tenant,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating Virtual Circuit"
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'virtual-circuits', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Virtual Circuit')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
