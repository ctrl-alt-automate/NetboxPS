<#
.SYNOPSIS
    Removes a IPAM VLANGroup from Netbox IPAM module.

.DESCRIPTION
    Removes a IPAM VLANGroup from Netbox IPAM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to delete.

.EXAMPLE
    Remove-NBIPAMVLANGroup

    Deletes an IPAM VLAN Group object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Remove-NBIPAMVLANGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing IPAM VLAN Group"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete VLAN group')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','vlan-groups',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
