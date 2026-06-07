<#
.SYNOPSIS
    Removes a IPAM VLANTranslationPolicy from Netbox IPAM module.

.DESCRIPTION
    Removes a IPAM VLANTranslationPolicy from Netbox IPAM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to delete.

.EXAMPLE
    Remove-NBIPAMVLANTranslationPolicy

    Deletes an IPAM VLAN Translation Policy object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Remove-NBIPAMVLANTranslationPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing IPAM VLAN Translation Policy"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete VLAN translation policy')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','vlan-translation-policies',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
