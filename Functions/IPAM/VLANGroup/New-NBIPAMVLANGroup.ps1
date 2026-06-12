<#
.SYNOPSIS
    Creates a new IPAM VLANGroup in Netbox IPAM module.

.DESCRIPTION
    Creates a new IPAM VLANGroup in Netbox IPAM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

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
    New-NBIPAMVLANGroup

    Creates a new IPAM VLAN Group object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBIPAMVLANGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][string]$Name,
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
        Write-Verbose "Creating IPAM VLAN Group"
        $Segments = [System.Collections.ArrayList]::new(@('ipam','vlan-groups'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create VLAN group')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
