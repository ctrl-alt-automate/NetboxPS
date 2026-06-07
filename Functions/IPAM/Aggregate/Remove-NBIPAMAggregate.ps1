<#
.SYNOPSIS
    Removes a IPAM Aggregate from Netbox IPAM module.

.DESCRIPTION
    Removes a IPAM Aggregate from Netbox IPAM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to delete.

.EXAMPLE
    Remove-NBIPAMAggregate

    Deletes an IPAM Aggregate object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Remove-NBIPAMAggregate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Removing IPAM Aggregate"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete aggregate')) {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'aggregates', $Id))
            $URI = BuildNewURI -Segments $Segments
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
