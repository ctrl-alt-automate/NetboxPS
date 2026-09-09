<#
.SYNOPSIS
    Removes a DCIM CoolingIntakeTemplate from Netbox DCIM module.

.DESCRIPTION
    Removes a Cooling Intake Template (NetBox 4.7+).
    Supports pipeline input for the Id parameter.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to delete.

.EXAMPLE
    Remove-NBDCIMCoolingIntakeTemplate -Id 5

    Deletes the cooling intake template with ID 5.

.EXAMPLE
    Get-NBDCIMCoolingIntakeTemplate -Device_Type_Id 12 | Remove-NBDCIMCoolingIntakeTemplate -Confirm:$false

    Deletes every cooling intake template of device type 12 without prompting.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.7.1.0
#>
function Remove-NBDCIMCoolingIntakeTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Cooling Intake Template ID $Id"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete cooling intake template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim', 'cooling-intake-templates', $Id)) -Method DELETE -Raw:$Raw
        }
    }
}
