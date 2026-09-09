<#
.SYNOPSIS
    Removes a DCIM CoolingOutflowTemplate from Netbox DCIM module.

.DESCRIPTION
    Removes a Cooling Outflow Template (NetBox 4.7+).
    Supports pipeline input for the Id parameter.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to delete.

.EXAMPLE
    Remove-NBDCIMCoolingOutflowTemplate -Id 5

    Deletes the cooling outflow template with ID 5.

.EXAMPLE
    Get-NBDCIMCoolingOutflowTemplate -Device_Type_Id 12 | Remove-NBDCIMCoolingOutflowTemplate -Confirm:$false

    Deletes every cooling outflow template of device type 12 without prompting.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.7.1.0
#>
function Remove-NBDCIMCoolingOutflowTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Cooling Outflow Template ID $Id"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete cooling outflow template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim', 'cooling-outflow-templates', $Id)) -Method DELETE -Raw:$Raw
        }
    }
}
