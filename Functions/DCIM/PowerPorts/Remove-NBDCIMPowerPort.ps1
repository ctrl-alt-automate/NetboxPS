<#
.SYNOPSIS
    Removes a DCIM PowerPort from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM PowerPort from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to delete.

.EXAMPLE
    Remove-NBDCIMPowerPort

    Deletes a DCIM PowerPort object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Remove-NBDCIMPowerPort {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Power Port"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete power port')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','power-ports',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
