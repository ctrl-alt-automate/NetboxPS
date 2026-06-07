<#
.SYNOPSIS
    Removes a CIMMACAddress from Netbox DCIM module.

.DESCRIPTION
    Removes a CIMMACAddress from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to delete.

.EXAMPLE
    Remove-NBDCIMMACAddress

    Deletes a DCIM MAC Address object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Remove-NBDCIMMACAddress {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing DCIM MAC Address"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete MAC address')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim','mac-addresses',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
