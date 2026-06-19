<#
.SYNOPSIS
    Removes a DCIM Cable from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM Cable from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to delete.

.EXAMPLE
    Remove-NBDCIMCable

    Deletes a DCIM Cable object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Remove-NBDCIMCable {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Cable"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete cable')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','cables',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
