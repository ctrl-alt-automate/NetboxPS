<#
.SYNOPSIS
    Updates a virtual disk in Netbox Virtualization.

.DESCRIPTION
    Updates an existing VirtualDisk (NetBox 4.0+).

.PARAMETER Id
    The ID of the virtual disk to update.

.PARAMETER Name
    The name of the virtual disk.

.PARAMETER Virtual_Machine
    The ID of the parent virtual machine.

.PARAMETER Size
    The disk size in GB.

.PARAMETER Description
    A description of the virtual disk.

.PARAMETER Owner
    The owner ID for object ownership.

.PARAMETER Tags
    Tags to assign to this virtual disk.

.PARAMETER Custom_Fields
    A hashtable of custom field values.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBVirtualDisk -Id 1 -Size 200

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.6.0.1

#>
function Set-NBVirtualDisk {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [uint64]$Virtual_Machine,

        [uint64]$Size,

        [string]$Description,

        [uint64]$Owner,

        [object[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating Virtual Disk"
        $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'virtual-disks', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update virtual disk')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
