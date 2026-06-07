<#
.SYNOPSIS
    Removes a IPAM VLANTranslationRule from Netbox IPAM module.

.DESCRIPTION
    Removes a IPAM VLANTranslationRule from Netbox IPAM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to delete.

.EXAMPLE
    Remove-NBIPAMVLANTranslationRule

    Deletes an IPAM VLAN Translation Rule object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Remove-NBIPAMVLANTranslationRule {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing IPAM VLAN Translation Rule"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete VLAN translation rule')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','vlan-translation-rules',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
