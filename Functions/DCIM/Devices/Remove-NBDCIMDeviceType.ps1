<#
.SYNOPSIS
    Removes a DCIM DeviceType from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM DeviceType from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to delete.

.EXAMPLE
    Remove-NBDCIMDeviceType

    Deletes a DCIM DeviceType object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Remove-NBDCIMDeviceType {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Device Type"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete device type')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','device-types',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
