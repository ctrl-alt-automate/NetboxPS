<#
.SYNOPSIS
    Creates one or more network interfaces on virtual machines in Netbox.

.DESCRIPTION
    Creates new network interfaces on specified virtual machines. Supports both
    single interface creation with individual parameters and bulk creation via
    pipeline input.

    For bulk operations, use the -BatchSize parameter to control how many
    interfaces are sent per API request. This significantly improves performance
    when creating many VM interfaces.

.PARAMETER Name
    The name of the interface (e.g., 'eth0', 'ens192', 'Ethernet0').

.PARAMETER Virtual_Machine
    The database ID of the virtual machine to add the interface to.

.PARAMETER Enabled
    Whether the interface is enabled. Defaults to $true if not specified.

.PARAMETER MAC_Address
    The MAC address of the interface in format XX:XX:XX:XX:XX:XX.

.PARAMETER MTU
    Maximum Transmission Unit size. Common values: 1500 (standard), 9000 (jumbo).

.PARAMETER Description
    A description of the interface.

.PARAMETER Mode
    VLAN mode for the interface: 'access', 'tagged', or 'tagged-all'.

.PARAMETER Untagged_VLAN
    The database ID of the untagged/native VLAN.

.PARAMETER Tagged_VLANs
    Array of database IDs for tagged VLANs (for trunk ports).

.PARAMETER VRF
    The database ID of the VRF for this interface.

.PARAMETER Tags
    Array of tag IDs to assign to this interface.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER InputObject
    Pipeline input for bulk operations. Each object should contain
    the required properties: Name, Virtual_Machine.

.PARAMETER BatchSize
    Number of interfaces to create per API request in bulk mode.
    Default: 50, Range: 1-1000

.PARAMETER Background
    Netbox 4.7+: queue each bulk batch as a background job (?background=true) instead of processing it
    synchronously; the returned items are the job objects (check them with Get-NBJob). Ignored with a
    warning on older Netbox versions. Only meaningful together with -BatchSize pipeline input.
.PARAMETER Force
    Skip confirmation prompts for bulk operations.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBVirtualMachineInterface -Name "eth0" -Virtual_Machine 42

    Creates a new enabled interface named 'eth0' on VM ID 42.

.EXAMPLE
    $vms = Get-NBVirtualMachine -Cluster 1
    $interfaces = $vms | ForEach-Object {
        [PSCustomObject]@{
            Virtual_Machine = $_.id
            Name = "eth0"
            Enabled = $true
            Description = "Primary interface"
        }
    }
    $interfaces | New-NBVirtualMachineInterface -BatchSize 50 -Force

    Creates primary interfaces for all VMs in a cluster in bulk.

.EXAMPLE
    # Create multiple interfaces per VM
    $vmId = 123
    $interfaces = @(
        [PSCustomObject]@{Virtual_Machine=$vmId; Name="eth0"; Description="Management"}
        [PSCustomObject]@{Virtual_Machine=$vmId; Name="eth1"; Description="Production"}
        [PSCustomObject]@{Virtual_Machine=$vmId; Name="eth2"; Description="Backup"}
    )
    $interfaces | New-NBVirtualMachineInterface -Force

    Creates multiple interfaces on a single VM.

.LINK
    https://netbox.readthedocs.io/en/stable/models/virtualization/vminterface/
.NOTES
    AddedInVersion: v1.0.4

#>
function New-NBVirtualMachineInterface {
    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'Low',
        DefaultParameterSetName = 'Single')]
    [OutputType([PSCustomObject])]
    param(
        # Single mode parameters
        [Parameter(ParameterSetName = 'Single', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(ParameterSetName = 'Single', Mandatory = $true)]
        [uint64]$Virtual_Machine,

        [Parameter(ParameterSetName = 'Single')]
        [bool]$Enabled = $true,

        [Parameter(ParameterSetName = 'Single')]
        [ValidatePattern('^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$')]
        [string]$MAC_Address,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateRange(1, 65535)]
        [uint16]$MTU,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Description,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('access', 'tagged', 'tagged-all', 'q-in-q', IgnoreCase = $true)]
        [string]$Mode,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Untagged_VLAN,

        [Parameter(ParameterSetName = 'Single')]
        [uint64[]]$Tagged_VLANs,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$VRF,

        [Parameter(ParameterSetName = 'Single')]
        [uint64[]]$Tags,

        [Parameter(ParameterSetName = 'Single')]
        [hashtable]$Custom_Fields,

        # Bulk mode parameters
        [Parameter(ParameterSetName = 'Bulk', Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]$InputObject,

        [Parameter(ParameterSetName = 'Bulk')]
        [ValidateRange(1, 1000)]
        [int]$BatchSize = 100,

        [switch]$Background,

        [Parameter(ParameterSetName = 'Bulk')]
        [switch]$Force,

        # Common parameters
        [Parameter()]
        [switch]$Raw
    )

    begin {
        $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'interfaces'))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ParameterSetName -eq 'Bulk') {
            $bulkItems = [System.Collections.ArrayList]::new()
        }
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Single') {
            # Ensure Enabled is always included in the body (defaults to true)
            $PSBoundParameters['Enabled'] = $Enabled

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

            if ($PSCmdlet.ShouldProcess("VM $Virtual_Machine", "Create interface '$Name'")) {
                InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
            }
        }
        else {
            # Bulk mode - collect items
            if ($InputObject) {
                $item = @{}
                foreach ($prop in $InputObject.PSObject.Properties) {
                    $key = $prop.Name.ToLower()
                    $value = $prop.Value

                    $item[$key] = $value
                }

                # Default enabled to true if not specified
                if (-not $item.ContainsKey('enabled')) {
                    $item['enabled'] = $true
                }

                [void]$bulkItems.Add([PSCustomObject]$item)
            }
        }
    }

    end {
        if ($PSCmdlet.ParameterSetName -eq 'Bulk' -and $bulkItems.Count -gt 0) {
            $target = "$($bulkItems.Count) interface(s)"

            if ($Force -or $PSCmdlet.ShouldProcess($target, 'Create VM interfaces (bulk)')) {
                Write-Verbose "Processing $($bulkItems.Count) VM interfaces in bulk mode with batch size $BatchSize"

                $useBackground = $Background -and -not (Test-NBMinimumVersion -ParameterName 'Background' -MinimumVersion '4.7.0' -BoundParameters $PSBoundParameters -FeatureName 'Background bulk processing (-Background)')
                $bulkParams = @{
                    URI          = $URI
                    Items        = $bulkItems.ToArray()
                    Method       = 'POST'
                    BatchSize    = $BatchSize
                    ShowProgress = $true
                    ActivityName = 'Creating VM interfaces'
                    Background   = $useBackground
                }
                $result = Send-NBBulkRequest @bulkParams

                # Output succeeded items to pipeline
                foreach ($item in $result.Succeeded) {
                    Write-Output $item
                }

                # Write errors for failed items
                foreach ($failure in $result.Failed) {
                    Write-Error "Failed to create VM interface: $($failure.Error)" -TargetObject $failure.Item
                }

                # Write summary
                if ($result.HasErrors) {
                    Write-Warning $result.GetSummary()
                }
                else {
                    Write-Verbose $result.GetSummary()
                }
            }
        }
    }
}
