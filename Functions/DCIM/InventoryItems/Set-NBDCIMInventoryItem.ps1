<#
.SYNOPSIS
    Updates an existing DCIM InventoryItem in Netbox DCIM module.

.DESCRIPTION
    Updates an existing DCIM InventoryItem in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to update.

.PARAMETER Device
    Device assigned to this object (database ID).

.PARAMETER Name
    Name of the object.

.PARAMETER Parent
    Parent object assigned to this object (database ID).

.PARAMETER Label
    Physical label.

.PARAMETER Role
    Role assigned to this object (database ID).

.PARAMETER Manufacturer
    Manufacturer assigned to this object (database ID).

.PARAMETER Part_Id
    Database ID of the part.

.PARAMETER Serial
    Serial number assigned by the manufacturer.

.PARAMETER Asset_Tag
    Unique asset tag.

.PARAMETER Discovered
    This item was automatically discovered

.PARAMETER Description
    Brief description.

.PARAMETER Component_Type
    Component Type.

.PARAMETER Component_Id
    Database ID of the component.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.EXAMPLE
    Set-NBDCIMInventoryItem

    Updates an existing DCIM InventoryItem object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBDCIMInventoryItem {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device,
        [string]$Name,
        [uint64]$Parent,
        [string]$Label,
        [uint64]$Role,
        [uint64]$Manufacturer,
        [string]$Part_Id,
        [string]$Serial,
        [string]$Asset_Tag,
        [bool]$Discovered,
        [string]$Description,
        [uint64]$Component_Type,
        [uint64]$Component_Id,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Updating DCIM Inventory Item"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','inventory-items',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update inventory item')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
