<#
.SYNOPSIS
    Updates one or more IP addresses in Netbox IPAM module.

.DESCRIPTION
    Updates existing IP addresses in Netbox IPAM module. Supports both
    single IP address updates with individual parameters and bulk updates via pipeline input.

    For bulk operations, use the -BatchSize parameter to control how many
    IP addresses are sent per API request. Each object must have an Id property.

.PARAMETER Id
    The database ID of the IP address to update. Required for single updates.

.PARAMETER Address
    The IP address with prefix (e.g., "192.168.1.1/24").

.PARAMETER Status
    Status of the IP address (e.g., "active", "reserved", "deprecated").

.PARAMETER Tenant
    The tenant ID.

.PARAMETER VRF
    The VRF ID.

.PARAMETER Role
    The role of the IP address.

.PARAMETER NAT_Inside
    The ID of the inside NAT IP address.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Assigned_Object_Type
    The type of object assigned to this IP (dcim.interface or virtualization.vminterface).

.PARAMETER Assigned_Object_Id
    The ID of the assigned object.

.PARAMETER Description
    Description of the IP address.

.PARAMETER Dns_name
    DNS name for the IP address.

.PARAMETER Owner
    The owner ID for object ownership (Netbox 4.5+ only).

.PARAMETER InputObject
    Pipeline input for bulk operations. Each object MUST have an Id property.

.PARAMETER BatchSize
    Number of IP addresses to update per API request in bulk mode.
    Default: 50, Range: 1-1000

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    Set-NBIPAMAddress -Id 123 -Status "active"

    Updates IP address 123 to active status.

.EXAMPLE
    Get-NBIPAMAddress -Status "deprecated" | ForEach-Object {
        [PSCustomObject]@{Id = $_.id; Status = "reserved"}
    } | Set-NBIPAMAddress -Force

    Bulk update all deprecated IP addresses to reserved status.

.EXAMPLE
    $updates = @(
        [PSCustomObject]@{Id = 100; Description = "Updated"; Dns_name = "server1.local"}
        [PSCustomObject]@{Id = 101; Description = "Updated"; Dns_name = "server2.local"}
    )
    $updates | Set-NBIPAMAddress -BatchSize 50 -Force

    Bulk update multiple IP addresses with different values.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v1.0.4

#>

function Set-NBIPAMAddress {
    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium',
        DefaultParameterSetName = 'Single')]
    [OutputType([PSCustomObject])]
    param
    (
        # Single mode parameters
        [Parameter(ParameterSetName = 'Single', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Address,

        [Parameter(ParameterSetName = 'Single', ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('active', 'reserved', 'deprecated', 'dhcp', 'slaac', IgnoreCase = $true)]
        [string]$Status,

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
        [ValidateSet('dcim.interface', 'virtualization.vminterface', IgnoreCase = $true)]
        [string]$Assigned_Object_Type,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Assigned_Object_Id,

        [Parameter(ParameterSetName = 'Single', ValueFromPipelineByPropertyName = $true)]
        [string]$Description,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Dns_name,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Owner,

        # Bulk mode parameters
        [Parameter(ParameterSetName = 'Bulk', Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]$InputObject,

        [Parameter(ParameterSetName = 'Bulk')]
        [ValidateRange(1, 1000)]
        [int]$BatchSize = 100,

        # Common parameters
        [Parameter()]
        [switch]$Force,

        [Parameter()]

        [object[]]$Tags,

        [switch]$Raw
    )

    begin {
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'ip-addresses'))
        $URI = BuildNewURI -Segments $Segments
        $Method = 'PATCH'

        if ($PSCmdlet.ParameterSetName -eq 'Bulk') {
            $bulkItems = [System.Collections.ArrayList]::new()
        }
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Single') {
            # Validate that Assigned_Object_Type and Assigned_Object_Id are used together
            if ($PSBoundParameters.ContainsKey('Assigned_Object_Type') -and -not $PSBoundParameters.ContainsKey('Assigned_Object_Id')) {
                throw "Assigned_Object_Id is required when specifying Assigned_Object_Type"
            }
            if ($PSBoundParameters.ContainsKey('Assigned_Object_Id') -and -not $PSBoundParameters.ContainsKey('Assigned_Object_Type')) {
                throw "Assigned_Object_Type is required when specifying Assigned_Object_Id"
            }

            foreach ($IPId in $Id) {
                $IPSegments = [System.Collections.ArrayList]::new(@('ipam', 'ip-addresses', $IPId))

                if ($Force -or $PSCmdlet.ShouldProcess($IPId, 'Update IP address')) {
                    $URIComponents = BuildURIComponents -URISegments $IPSegments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force', 'Raw'

                    $IPURI = BuildNewURI -Segments $URIComponents.Segments

                    InvokeNetboxRequest -URI $IPURI -Body $URIComponents.Parameters -Method $Method -Raw:$Raw
                }
            }
        }
        else {
            # Bulk mode - collect items
            if ($InputObject) {
                # Validate that Id is present
                $itemId = if ($InputObject.Id) { $InputObject.Id }
                          elseif ($InputObject.id) { $InputObject.id }
                          else { $null }

                if (-not $itemId) {
                    Write-Error "InputObject must have an 'Id' property for bulk updates" -TargetObject $InputObject
                    return
                }

                $item = @{}
                foreach ($prop in $InputObject.PSObject.Properties) {
                    $key = $prop.Name.ToLower()
                    $value = $prop.Value

                    $item[$key] = $value
                }
                [void]$bulkItems.Add([PSCustomObject]$item)
            }
        }
    }

    end {
        if ($PSCmdlet.ParameterSetName -eq 'Bulk' -and $bulkItems.Count -gt 0) {
            $target = "$($bulkItems.Count) IP address(es)"

            if ($Force -or $PSCmdlet.ShouldProcess($target, 'Update IP addresses (bulk)')) {
                Write-Verbose "Processing $($bulkItems.Count) IP addresses in bulk PATCH mode with batch size $BatchSize"

                $bulkParams = @{
                    URI          = $URI
                    Items        = $bulkItems.ToArray()
                    Method       = 'PATCH'
                    BatchSize    = $BatchSize
                    ShowProgress = $true
                    ActivityName = 'Updating IP addresses'
                }
                $result = Send-NBBulkRequest @bulkParams

                # Output succeeded items to pipeline
                foreach ($item in $result.Succeeded) {
                    Write-Output $item
                }

                # Write errors for failed items
                foreach ($failure in $result.Failed) {
                    Write-Error "Failed to update IP address: $($failure.Error)" -TargetObject $failure.Item
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
