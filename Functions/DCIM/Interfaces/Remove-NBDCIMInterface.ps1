function Remove-NBDCIMInterface {
    <#
    .SYNOPSIS
        Removes an interface

    .DESCRIPTION
        Removes an interface by ID from a device

    .PARAMETER Id
        Database ID of the interface to delete.

    .PARAMETER Force
        Skip confirmation prompts.

    .PARAMETER Raw
        Return the raw API response object instead of the .results collection.

    .EXAMPLE
        PS C:\> Remove-NBDCIMInterface -Id 123
.NOTES
    AddedInVersion: v1.0.4

#>

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
        Write-Verbose "Removing DCIM Interface"
        foreach ($InterfaceId in $Id) {

            if ($Force -or $PSCmdlet.ShouldProcess("ID $InterfaceId", "Remove")) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'interfaces', $InterfaceId))

                $URI = BuildNewURI -Segments $Segments

                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}
