<#
.SYNOPSIS
    Removes a DCIM Site from Netbox.

.DESCRIPTION
    Removes a DCIM Site from Netbox.
    Supports pipeline input for Id parameter.

.PARAMETER Id
    Database ID of the object to delete.

.PARAMETER Raw
    Return the raw API response object instead of the .results collection.

.EXAMPLE
    Remove-NBDCIMSite -Id 1

.EXAMPLE
    Get-NBDCIMSite -Name 'My Site' | Remove-NBDCIMSite -Confirm:$false

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v1.7.1

#>
function Remove-NBDCIMSite {

    [CmdletBinding(ConfirmImpact = 'High',
        SupportsShouldProcess = $true)]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing DCIM Site"

        if ($PSCmdlet.ShouldProcess("ID $Id", "Remove Site")) {
            $Segments = [System.Collections.ArrayList]::new(@('dcim', 'sites', $Id))

            $URI = BuildNewURI -Segments $Segments

            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
