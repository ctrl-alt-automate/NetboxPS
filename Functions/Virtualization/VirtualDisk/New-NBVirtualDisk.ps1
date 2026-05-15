<#
.SYNOPSIS
    Creates a new virtual disk in Netbox Virtualization.

.DESCRIPTION
    Creates a new VirtualDisk (NetBox 4.0+) attached to a virtual machine.

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
    New-NBVirtualDisk -Name 'disk0' -Virtual_Machine 42 -Size 100

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.6.0.1

#>
function New-NBVirtualDisk {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [uint64]$Virtual_Machine,

        [Parameter(Mandatory = $true)]
        [uint64]$Size,

        [string]$Description,

        [uint64]$Owner,

        [object[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Virtual Disk"
        $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'virtual-disks'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create virtual disk')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
