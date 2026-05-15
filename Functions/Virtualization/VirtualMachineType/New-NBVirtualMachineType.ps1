<#
.SYNOPSIS
    Creates a new virtual machine type in Netbox Virtualization.

.DESCRIPTION
    Creates a new VirtualMachineType (NetBox 4.6+). VM types categorize
    virtual machines by instance type (analogous to DeviceType), with
    optional default vCPU / memory / platform values.

.PARAMETER Name
    The name of the VM type.

.PARAMETER Slug
    URL-friendly unique identifier. Auto-generated from name if omitted.

.PARAMETER Default_vCPUs
    Default number of vCPUs for VMs of this type.

.PARAMETER Default_Memory
    Default memory (MB) for VMs of this type.

.PARAMETER Default_Platform
    Default platform ID for VMs of this type.

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
    New-NBVirtualMachineType -Name 't3.medium' -Default_vCPUs 2 -Default_Memory 4096

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.6.0.1

#>
function New-NBVirtualMachineType {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [string]$Slug,

        [decimal]$Default_vCPUs,

        [uint64]$Default_Memory,

        [uint64]$Default_Platform,

        [string]$Description,

        [string]$Comments,

        [uint64]$Owner,

        [object[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Virtual Machine Type"
        if (-not $PSBoundParameters.ContainsKey('Slug')) {
            $PSBoundParameters['Slug'] = ($Name -replace '\s+', '-').ToLower()
        }

        $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'virtual-machine-types'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create virtual machine type')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
