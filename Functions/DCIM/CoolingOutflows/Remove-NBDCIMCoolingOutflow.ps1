<#
.SYNOPSIS
    Removes a DCIM CoolingOutflow from Netbox DCIM module.

.DESCRIPTION
    Removes a Cooling Outflow (NetBox 4.7+).
    Supports pipeline input for the Id parameter.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to delete.

.EXAMPLE
    Remove-NBDCIMCoolingOutflow -Id 5

    Deletes the cooling outflow with ID 5.

.EXAMPLE
    Get-NBDCIMCoolingOutflow -Device_Id 12 | Remove-NBDCIMCoolingOutflow -Confirm:$false

    Deletes every cooling outflow of device 12 without prompting.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.7.0.1
#>
function Remove-NBDCIMCoolingOutflow {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Cooling Outflow ID $Id"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete cooling outflow')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim', 'cooling-outflows', $Id)) -Method DELETE -Raw:$Raw
        }
    }
}
