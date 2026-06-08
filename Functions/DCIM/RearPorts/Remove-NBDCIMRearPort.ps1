<#
.SYNOPSIS
    Removes a DCIM RearPort from Netbox DCIM module.

.DESCRIPTION
    Removes a DCIM RearPort from Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to delete.

.PARAMETER Force
    Skip the confirmation prompt.

.EXAMPLE
    Remove-NBDCIMRearPort

    Deletes a DCIM RearPort object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.7

#>
function Remove-NBDCIMRearPort {

    [CmdletBinding(ConfirmImpact = 'High',
        SupportsShouldProcess = $true)]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing DCIM Rear Port"
        foreach ($RearPortID in $Id) {
            if ($Force -or $PSCmdlet.ShouldProcess("Rear Port ID $RearPortID", "Remove")) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'rear-ports', $RearPortID))

                $URI = BuildNewURI -Segments $Segments

                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}
