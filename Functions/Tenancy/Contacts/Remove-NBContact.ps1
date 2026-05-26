<#
.SYNOPSIS
    Removes a contact from Netbox.

.DESCRIPTION
    Removes a contact from the Netbox tenancy module.
    Supports pipeline input from Get-NBContact.

.PARAMETER Id
    The database ID(s) of the contact(s) to remove. Accepts pipeline input.

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBContact -Id 1

    Removes contact ID 1 (with confirmation prompt).

.EXAMPLE
    Remove-NBContact -Id 1, 2, 3 -Force

    Removes multiple contacts without confirmation.

.EXAMPLE
    Get-NBContact -Group_Id 5 | Remove-NBContact

    Removes all contacts in a specific group via pipeline.

.LINK
    https://netbox.readthedocs.io/en/stable/models/tenancy/contact/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Remove-NBContact {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [switch]$Force,

        [switch]$Raw
    )

    process {
        Write-Verbose "Removing Contact"
        foreach ($ContactId in $Id) {

            $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contacts', $ContactId))

            $URI = BuildNewURI -Segments $Segments

            if ($Force -or $PSCmdlet.ShouldProcess("ID $ContactId", 'Delete contact')) {
                InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
            }
        }
    }
}
