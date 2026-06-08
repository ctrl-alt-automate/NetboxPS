<#
.SYNOPSIS
    Removes a DCIM InventoryItemTemplate from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM InventoryItemTemplate from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to delete.

.EXAMPLE
    Remove-NBDCIMInventoryItemTemplate

    Deletes a DCIM InventoryItemTemplate object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Remove-NBDCIMInventoryItemTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Inventory Item Template"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete inventory item template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','inventory-item-templates',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
