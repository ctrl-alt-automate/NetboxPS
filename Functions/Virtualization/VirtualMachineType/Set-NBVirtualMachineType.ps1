<#
.SYNOPSIS
    Updates a virtual machine type in Netbox Virtualization.

.DESCRIPTION
    Updates an existing VirtualMachineType (NetBox 4.6+).

.PARAMETER Id
    The ID of the VM type to update.

.PARAMETER Name
    The name of the VM type.

.PARAMETER Slug
    URL-friendly unique identifier.

.PARAMETER Default_vCPUs
    Default number of vCPUs for VMs of this type.

.PARAMETER Default_Memory
    Default memory (MB) for VMs of this type.

.PARAMETER Default_Platform
    Default platform ID for VMs of this type. Pass $null to clear.

.PARAMETER Description
    A description of the VM type.

.PARAMETER Comments
    Additional comments.

.PARAMETER Owner
    The owner ID for object ownership.

.PARAMETER Tags
    Tags to assign to this VM type.

.PARAMETER Custom_Fields
    A hashtable of custom field values.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBVirtualMachineType -Id 1 -Default_Memory 8192

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.6.0.1

#>
function Set-NBVirtualMachineType {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Slug,

        [decimal]$Default_vCPUs,

        [uint64]$Default_Memory,

        [Nullable[uint64]]$Default_Platform,

        [string]$Description,

        [string]$Comments,

        [uint64]$Owner,

        [object[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating Virtual Machine Type"
        $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'virtual-machine-types', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update virtual machine type')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
