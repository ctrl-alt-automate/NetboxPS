<#
.SYNOPSIS
    Updates an existing IPAM VLAN in Netbox IPAM module.

.DESCRIPTION
    Updates an existing IPAM VLAN in Netbox IPAM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to update.

.PARAMETER VID
    Numeric VLAN ID (1-4094)

.PARAMETER Name
    Name of the object.

.PARAMETER Status
    Operational status.

.PARAMETER Site
    Site assigned to this object (database ID).

.PARAMETER Group
    Group assigned to this object (database ID).

.PARAMETER Tenant
    Tenant assigned to this object (database ID).

.PARAMETER Role
    Role assigned to this object (database ID).

.PARAMETER Description
    Brief description.

.PARAMETER Comments
    Detailed comments (Markdown is supported).

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.PARAMETER Owner
    Owner assigned to this object (database ID).

.EXAMPLE
    Set-NBIPAMVLAN

    Updates an existing IPAM VLAN object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBIPAMVLAN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [ValidateRange(1, 4094)][uint16]$VID,
        [string]$Name,
        [ValidateSet('active', 'reserved', 'deprecated', IgnoreCase = $true)]
        [string]$Status,
        [uint64]$Site,
        [uint64]$Group,
        [uint64]$Tenant,
        [uint64]$Role,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [uint64]$Owner,
        [switch]$Raw
    )
    process {
        Write-Verbose "Updating IPAM VLAN"
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'vlans', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments
        if ($PSCmdlet.ShouldProcess($Id, 'Update VLAN')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
