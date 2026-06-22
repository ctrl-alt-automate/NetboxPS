<#
.SYNOPSIS
    Updates an existing IPAM VLANGroup in Netbox IPAM module.

.DESCRIPTION
    Updates an existing IPAM VLANGroup in Netbox IPAM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Id
    The database Id of the VLAN group to update. (Mandatory)

.PARAMETER Name
    The name of the VLAN group.

.PARAMETER Slug
    The slug of the VLAN group.

.PARAMETER Scope_Type
    The type of the scope to which this VLAN group belongs.

.PARAMETER Scope_Id
    The database Id of the site, rack, cluster, etc. to which this VLAN group belongs.

.PARAMETER Min_Vid
    The minimum VLAN ID in this group. Valid values are 1-4094.

.PARAMETER Max_Vid
    The maximum VLAN ID in this group. Valid values are 1-4094.

.PARAMETER Description
    The description of the VLAN group.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.EXAMPLE
    Set-NBIPAMVLANGroup -Id 1 -Name 'UpdatedGroup'

    Updates an existing IPAM VLAN Group object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBIPAMVLANGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Name,
        [string]$Slug,
        [ValidateSet('dcim.rack','dcim.rackgroup','dcim.location','dcim.region','dcim.sitegroup','dcim.site','virtualization.clustergroup','virtualization.cluster')]
        [string]$Scope_Type,
        [uint64]$Scope_Id,
        [ValidateRange(1, 4094)][uint16]$Min_Vid,
        [ValidateRange(1, 4094)][uint16]$Max_Vid,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Updating IPAM VLAN Group"
        $Segments = [System.Collections.ArrayList]::new(@('ipam','vlan-groups',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update VLAN group')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
