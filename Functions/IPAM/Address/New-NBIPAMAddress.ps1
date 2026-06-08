<#
.SYNOPSIS
    Creates one or more IP addresses in Netbox IPAM module.

.DESCRIPTION
    Creates new IP addresses in Netbox IPAM module. Supports both single IP
    creation with individual parameters and bulk creation via pipeline input.

    For bulk operations, use the -BatchSize parameter to control how many
    addresses are sent per API request. This significantly improves performance
    when creating many IP addresses.

.PARAMETER Address
    IP address in CIDR notation: 192.168.1.1/24. Required for single mode.

.PARAMETER Status
    Status of the IP. Defaults to 'Active'.

.PARAMETER Tenant
    Tenant ID.

.PARAMETER VRF
    VRF ID.

.PARAMETER Role
    Role such as anycast, loopback, etc.

.PARAMETER NAT_Inside
    ID of IP for NAT.

.PARAMETER Custom_Fields
    Custom field hash table. Will be validated by the API service.

.PARAMETER Interface
    ID of interface to apply IP (deprecated, use Assigned_Object_Id).

.PARAMETER Description
    Description of IP address.

.PARAMETER Dns_name
    DNS Name of IP address (example: netbox.example.com).

.PARAMETER Assigned_Object_Type
    Assigned Object Type: 'dcim.interface' or 'virtualization.vminterface'.

.PARAMETER Assigned_Object_Id
    Assigned Object ID.

.PARAMETER Owner
    The owner ID for object ownership (Netbox 4.5+ only).

.PARAMETER InputObject
    Pipeline input for bulk operations. Each object should contain
    at minimum the Address property.

.PARAMETER BatchSize
    Number of IP addresses to create per API request in bulk mode.
    Default: 50, Range: 1-1000

.PARAMETER Force
    Skip confirmation prompts for bulk operations.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBIPAMAddress -Address "192.168.1.1/24"

    Creates a single IP address with status active.

.EXAMPLE
    New-NBIPAMAddress -Address "10.0.0.1/24" -Status active -Description "Gateway"

    Creates an IP address with description.

.EXAMPLE
    1..254 | ForEach-Object {
        [PSCustomObject]@{
            Address = "192.168.1.$_/24"
            Status = "active"
            Description = "Host $_"
        }
    } | New-NBIPAMAddress -BatchSize 100 -Force

    Bulk create 254 IP addresses in a subnet.

.EXAMPLE
    Import-Csv ips.csv | New-NBIPAMAddress -BatchSize 50 -Force

    Bulk import IP addresses from CSV file.

.LINK
    https://netbox.readthedocs.io/en/stable/models/ipam/ipaddress/
.NOTES
    AddedInVersion: v1.0.4

#>

function New-NBIPAMAddress {
    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'Low',
        DefaultParameterSetName = 'Single')]
    [OutputType([PSCustomObject])]
    param(
        # Single mode parameters
        [Parameter(ParameterSetName = 'Single', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Address,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('active', 'reserved', 'deprecated', 'dhcp', 'slaac', IgnoreCase = $true)]
        [string]$Status = 'active',

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Tenant,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$VRF,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('loopback', 'secondary', 'anycast', 'vip', 'vrrp', 'hsrp', 'glbp', 'carp', IgnoreCase = $true)]
        [string]$Role,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$NAT_Inside,

        [Parameter(ParameterSetName = 'Single')]
        [hashtable]$Custom_Fields,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Interface,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Description,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Dns_name,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('dcim.interface', 'virtualization.vminterface', IgnoreCase = $true)]
        [string]$Assigned_Object_Type,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Assigned_Object_Id,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Owner,

        # Bulk mode parameters
        [Parameter(ParameterSetName = 'Bulk', Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]$InputObject,

        [Parameter(ParameterSetName = 'Bulk')]
        [ValidateRange(1, 1000)]
        [int]$BatchSize = 100,

        [Parameter(ParameterSetName = 'Bulk')]
        [switch]$Force,

        # Common parameters
        [Parameter()]

        [object[]]$Tags,

        [switch]$Raw
    )

    begin {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'ip-addresses'))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ParameterSetName -eq 'Bulk') {
            $bulkItems = [System.Collections.ArrayList]::new()
        }
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Single') {
            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

            if ($PSCmdlet.ShouldProcess($Address, 'Create new IP address')) {
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

                # Validate address is present
                if (-not $item.ContainsKey('address') -or [string]::IsNullOrWhiteSpace($item['address'])) {
                    Write-Error "InputObject must have an 'Address' property" -TargetObject $InputObject
                    return
                }

                [void]$bulkItems.Add([PSCustomObject]$item)
            }
        }
    }

    end {
        if ($PSCmdlet.ParameterSetName -eq 'Bulk' -and $bulkItems.Count -gt 0) {
            $target = "$($bulkItems.Count) IP address(es)"

            if ($Force -or $PSCmdlet.ShouldProcess($target, 'Create IP addresses (bulk)')) {
                Write-Verbose "Processing $($bulkItems.Count) IP addresses in bulk mode with batch size $BatchSize"

                $bulkParams = @{
                    URI          = $URI
                    Items        = $bulkItems.ToArray()
                    Method       = 'POST'
                    BatchSize    = $BatchSize
                    ShowProgress = $true
                    ActivityName = 'Creating IP addresses'
                }
                $result = Send-NBBulkRequest @bulkParams

                # Output succeeded items to pipeline
                foreach ($item in $result.Succeeded) {
                    Write-Output $item
                }

                # Write errors for failed items
                foreach ($failure in $result.Failed) {
                    Write-Error "Failed to create IP address: $($failure.Error)" -TargetObject $failure.Item
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
