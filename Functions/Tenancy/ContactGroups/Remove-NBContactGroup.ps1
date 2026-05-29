<#
    .SYNOPSIS
        Removes a contactgroup from Netbox.

    .DESCRIPTION
        Removes a contactgroup from the Netbox tenancy module.
        Supports pipeline input from Get-NBContactGroup.

    .PARAMETER Id
        The database ID(s) of the contactgroup(s) to remove. Accepts pipeline input.

    .PARAMETER Force
        Skip confirmation prompts.

    .PARAMETER Raw
        Return the raw API response instead of the results array.

    .EXAMPLE
        Remove-NBContactGroup -Id 1
        Removes contactgroup ID 1 (with confirmation prompt).

    .EXAMPLE
        Remove-NBContactGroup -Id 1 -Force
        Removes contactgroup ID 1 without confirmation.

    .EXAMPLE
        Get-NBContactGroup -Id 5 | Remove-NBContactGroup -Force
        Removes all contact groups in a specific group via pipeline.

    .LINK
        https://netbox.readthedocs.io/en/stable/models/tenancy/contactgroup/

    .NOTES

#>
function Remove-NBContactGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
        [uint64[]]$Id,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing Contact Group"
        foreach ($ContactgroupId in $Id) {

            $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contact-groups', $ContactgroupId))

            $URI = BuildNewURI -Segments $Segments

            if ($Force -or $PSCmdlet.ShouldProcess("ID $ContactgroupId", 'Delete contact group')) {
                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}
