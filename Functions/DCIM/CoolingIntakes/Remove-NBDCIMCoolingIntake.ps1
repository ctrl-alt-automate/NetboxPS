<#
.SYNOPSIS
    Removes a DCIM CoolingIntake from Netbox DCIM module.

.DESCRIPTION
    Removes a Cooling Intake (NetBox 4.7+).
    Supports pipeline input for the Id parameter.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to delete.

.EXAMPLE
    Remove-NBDCIMCoolingIntake -Id 5

    Deletes the cooling intake with ID 5.

.EXAMPLE
    Get-NBDCIMCoolingIntake -Device_Id 12 | Remove-NBDCIMCoolingIntake -Confirm:$false

    Deletes every cooling intake of device 12 without prompting.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.7.1.0
#>
function Remove-NBDCIMCoolingIntake {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Cooling Intake ID $Id"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete cooling intake')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim', 'cooling-intakes', $Id)) -Method DELETE -Raw:$Raw
        }
    }
}
