<#
.SYNOPSIS
    Updates an existing IPAM VLANGroup in Netbox IPAM module.

.DESCRIPTION
    Updates an existing IPAM VLANGroup in Netbox IPAM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to update.

.PARAMETER Name
    Name of the object.

.PARAMETER Slug
    URL-friendly unique identifier (slug).

.PARAMETER Scope_Type
    Scope Type.

.PARAMETER Scope_Id
    Database ID of the scope.

.PARAMETER Min_Vid
    Min Vid.

.PARAMETER Max_Vid
    Max Vid.

.PARAMETER Description
    Brief description.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.EXAMPLE
    Set-NBIPAMVLANGroup

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
        [uint64]$Scope_Type,
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
