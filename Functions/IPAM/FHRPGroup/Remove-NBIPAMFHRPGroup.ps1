<#
.SYNOPSIS
    Removes a IPAM FHRPGroup from Netbox IPAM module.

.DESCRIPTION
    Removes a IPAM FHRPGroup from Netbox IPAM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to delete.

.EXAMPLE
    Remove-NBIPAMFHRPGroup

    Deletes an IPAM FHRP Group object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Remove-NBIPAMFHRPGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing IPAM FHRP Group"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete FHRP group')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments @('ipam','fhrp-groups',$Id)) -Method DELETE -Raw:$Raw
        }
    }
}
