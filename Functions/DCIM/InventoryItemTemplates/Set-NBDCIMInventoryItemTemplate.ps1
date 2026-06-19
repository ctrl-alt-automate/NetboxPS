<#
.SYNOPSIS
    Updates an existing DCIM InventoryItemTemplate in Netbox DCIM module.

.DESCRIPTION
    Updates an existing DCIM InventoryItemTemplate in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to update.

.PARAMETER Device_Type
    Device type assigned to this object (database ID).

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

.PARAMETER Description
    Brief description.

.PARAMETER Component_Type
    Component Type.

.PARAMETER Component_Name
    Component Name.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    Set-NBDCIMInventoryItemTemplate

    Updates an existing DCIM InventoryItemTemplate object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBDCIMInventoryItemTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device_Type,
        [string]$Name,
        [uint64]$Parent,
        [string]$Label,
        [uint64]$Role,
        [uint64]$Manufacturer,
        [string]$Part_Id,
        [string]$Description,
        [uint64]$Component_Type,
        [string]$Component_Name,

        [object[]]$Tags,

        [switch]$Raw
    )
    process {
        Write-Verbose "Updating DCIM Inventory Item Template"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','inventory-item-templates',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update inventory item template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
