<#
.SYNOPSIS
    Removes a Module Bay Type from Netbox DCIM module.

.DESCRIPTION
    Removes a Module Bay Type from Netbox DCIM module (NetBox 4.7+).
    Supports pipeline input for Id parameter.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to delete.

.EXAMPLE
    Remove-NBDCIMModuleBayType -Id 4

    Deletes module bay type 4.

.EXAMPLE
    Get-NBDCIMModuleBayType -Name 'SFP Cage' | Remove-NBDCIMModuleBayType -Confirm:$false

    Deletes the module bay type named 'SFP Cage' via the pipeline.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.7.0.1
    Requires NetBox 4.7.0 or later.
#>
function Remove-NBDCIMModuleBayType {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM Module Bay Type"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete module bay type')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim', 'module-bay-types', $Id)) -Method DELETE -Raw:$Raw
        }
    }
}
