<#
.SYNOPSIS
    Creates one or more prefixes in Netbox IPAM module.

.DESCRIPTION
    Creates new IP prefixes in Netbox IPAM module. Supports both single prefix
    creation with individual parameters and bulk creation via pipeline input.

    For bulk operations, use the -BatchSize parameter to control how many
    prefixes are sent per API request. This significantly improves performance
    when creating many prefixes.

.PARAMETER Prefix
    The IP prefix in CIDR notation (e.g., '10.0.0.0/24').

.PARAMETER Status
    Status of the prefix. Defaults to 'Active'.

.PARAMETER Tenant
    The tenant ID for the prefix.

.PARAMETER Role
    The role ID for the prefix.

.PARAMETER IsPool
    Whether this prefix is a pool from which child prefixes can be allocated.

.PARAMETER Description
    A description of the prefix.

.PARAMETER Scope_Type
    The scope type for this prefix. Defines what kind of object the prefix is scoped to.
    Valid values: dcim.region, dcim.sitegroup, dcim.site, dcim.location.
    Must be used together with -Scope_Id.

.PARAMETER Scope_Id
    The database ID of the scope object. Must be used together with -Scope_Type.

.PARAMETER VRF
    The VRF ID for this prefix.

.PARAMETER VLAN
    The VLAN ID associated with this prefix.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Owner
    The owner ID for object ownership (Netbox 4.5+ only).

.PARAMETER InputObject
    Pipeline input for bulk operations. Each object should contain
    the required property: Prefix.

.PARAMETER BatchSize
    Number of prefixes to create per API request in bulk mode.
    Default: 50, Range: 1-1000

.PARAMETER Force
    Skip confirmation prompts for bulk operations.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBIPAMPrefix -Prefix "10.0.0.0/24" -Status "active" -Scope_Type "dcim.site" -Scope_Id 1

    Creates a single prefix scoped to site ID 1.

.EXAMPLE
    New-NBIPAMPrefix -Prefix "10.0.0.0/24" -Scope_Type "dcim.location" -Scope_Id 5

    Creates a prefix scoped to location ID 5.

.EXAMPLE
    $prefixes = 1..50 | ForEach-Object {
        [PSCustomObject]@{Prefix="10.$_.0.0/24"; Status="active"; Scope_Type="dcim.site"; Scope_Id=1}
    }
    $prefixes | New-NBIPAMPrefix -BatchSize 50 -Force

    Creates 50 prefixes in bulk using a single API call.

.EXAMPLE
    Import-Csv subnets.csv | New-NBIPAMPrefix -BatchSize 100 -Force

    Bulk import prefixes from CSV file.

.LINK
    https://netbox.readthedocs.io/en/stable/models/ipam/prefix/
.NOTES
    AddedInVersion: v1.0.4

#>

function New-NBIPAMPrefix {
    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'Low',
        DefaultParameterSetName = 'Single')]
    [OutputType([PSCustomObject])]
    param(
        # Single mode parameters
        [Parameter(ParameterSetName = 'Single', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Prefix,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('container', 'active', 'reserved', 'deprecated', IgnoreCase = $true)]
        [string]$Status = 'active',

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Tenant,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Role,

        [Parameter(ParameterSetName = 'Single')]
        [bool]$IsPool,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Description,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('dcim.region', 'dcim.sitegroup', 'dcim.site', 'dcim.location', IgnoreCase = $true)]
        [string]$Scope_Type,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Scope_Id,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$VRF,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$VLAN,

        [Parameter(ParameterSetName = 'Single')]
        [hashtable]$Custom_Fields,

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
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'prefixes'))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ParameterSetName -eq 'Bulk') {
            $bulkItems = [System.Collections.ArrayList]::new()
        }
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Single') {
            if ($PSBoundParameters.ContainsKey('Scope_Type') -xor $PSBoundParameters.ContainsKey('Scope_Id')) {
                throw 'Parameters -Scope_Type and -Scope_Id must be used together.'
            }

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

            if ($PSCmdlet.ShouldProcess($Prefix, 'Create new Prefix')) {
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

                    # Handle property name mappings
                    switch ($key) {
                        'ispool' { $key = 'is_pool' }
                        'site' {
                            # Backward compat: translate site to scope_type + scope_id
                            # Only if scope_type is not already explicitly provided
                            if (-not $InputObject.PSObject.Properties['scope_type']) {
                                $item['scope_type'] = 'dcim.site'
                                $item['scope_id'] = $value
                            }
                            $key = $null
                        }
                    }

                    if ($null -ne $key) {
                        $item[$key] = $value
                    }
                }
                [void]$bulkItems.Add([PSCustomObject]$item)
            }
        }
    }

    end {
        if ($PSCmdlet.ParameterSetName -eq 'Bulk' -and $bulkItems.Count -gt 0) {
            $target = "$($bulkItems.Count) prefix(es)"

            if ($Force -or $PSCmdlet.ShouldProcess($target, 'Create prefixes (bulk)')) {
                Write-Verbose "Processing $($bulkItems.Count) prefixes in bulk mode with batch size $BatchSize"

                $bulkParams = @{
                    URI          = $URI
                    Items        = $bulkItems.ToArray()
                    Method       = 'POST'
                    BatchSize    = $BatchSize
                    ShowProgress = $true
                    ActivityName = 'Creating prefixes'
                }
                $result = Send-NBBulkRequest @bulkParams

                # Output succeeded items to pipeline
                foreach ($item in $result.Succeeded) {
                    Write-Output $item
                }

                # Write errors for failed items
                foreach ($failure in $result.Failed) {
                    Write-Error "Failed to create prefix: $($failure.Error)" -TargetObject $failure.Item
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
