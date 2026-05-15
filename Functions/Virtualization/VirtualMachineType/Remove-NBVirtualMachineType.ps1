<#
.SYNOPSIS
    Deletes a virtual machine type from Netbox Virtualization.

.DESCRIPTION
    Deletes an existing VirtualMachineType (NetBox 4.6+).

.PARAMETER Id
    The ID of the VM type to delete.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVirtualMachineType -Id 1

.EXAMPLE
    Get-NBVirtualMachineType -Name 't3.medium' | Remove-NBVirtualMachineType

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.6.0.1

#>
function Remove-NBVirtualMachineType {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        Write-Verbose "Deleting Virtual Machine Type"
        $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'virtual-machine-types', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete virtual machine type')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
