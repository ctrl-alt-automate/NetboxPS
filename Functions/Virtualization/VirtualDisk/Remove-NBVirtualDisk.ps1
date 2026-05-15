<#
.SYNOPSIS
    Deletes a virtual disk from Netbox Virtualization.

.DESCRIPTION
    Deletes an existing VirtualDisk (NetBox 4.0+).

.PARAMETER Id
    The ID of the virtual disk to delete.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Remove-NBVirtualDisk -Id 1

.EXAMPLE
    Get-NBVirtualDisk -Virtual_Machine_Id 42 | Remove-NBVirtualDisk

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.6.0.1

#>
function Remove-NBVirtualDisk {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [switch]$Raw
    )

    process {
        Write-Verbose "Deleting Virtual Disk"
        $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'virtual-disks', $Id))

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Delete virtual disk')) {
            InvokeNetboxRequest -URI $URI -Method DELETE -Raw:$Raw
        }
    }
}
