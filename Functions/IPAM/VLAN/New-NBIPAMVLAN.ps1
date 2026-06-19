<#
.SYNOPSIS
    Creates one or more VLANs in Netbox IPAM module.

.DESCRIPTION
    Creates new VLANs in Netbox IPAM module. Supports both single VLAN
    creation with individual parameters and bulk creation via pipeline input.

    For bulk operations, use the -BatchSize parameter to control how many
    VLANs are sent per API request. This significantly improves performance
    when creating many VLANs.

.PARAMETER VID
    The VLAN ID (1-4094). Required for single VLAN creation.

.PARAMETER Name
    The name of the VLAN. Required for single VLAN creation.

.PARAMETER Status
    Status of the VLAN. Defaults to 'Active'.

.PARAMETER Tenant
    The tenant ID.

.PARAMETER Site
    The site ID.

.PARAMETER Group
    The VLAN group ID.

.PARAMETER Role
    The role ID.

.PARAMETER Description
    A description of the VLAN.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Owner
    The owner ID for object ownership (Netbox 4.5+ only).

.PARAMETER InputObject
    Pipeline input for bulk operations. Each object should contain
    the required properties: VID, Name.

.PARAMETER BatchSize
    Number of VLANs to create per API request in bulk mode.
    Default: 50, Range: 1-1000

.PARAMETER Force
    Skip confirmation prompts for bulk operations.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBIPAMVLAN -VID 100 -Name "Production" -Site 1

    Creates a single VLAN.

.EXAMPLE
    $vlans = 100..199 | ForEach-Object {
        [PSCustomObject]@{VID=$_; Name="VLAN$_"; Status="active"; Site=1}
    }
    $vlans | New-NBIPAMVLAN -BatchSize 50 -Force

    Creates 100 VLANs in bulk using 2 API calls.

.EXAMPLE
    Import-Csv vlans.csv | New-NBIPAMVLAN -BatchSize 100 -Force

    Bulk import VLANs from CSV file.

.LINK
    https://netbox.readthedocs.io/en/stable/models/ipam/vlan/
.NOTES
    AddedInVersion: v1.0.4

#>

function New-NBIPAMVLAN {
    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'Low',
        DefaultParameterSetName = 'Single')]
    [OutputType([PSCustomObject])]
    param(
        # Single mode parameters
        [Parameter(ParameterSetName = 'Single', Mandatory = $true)]
        [ValidateRange(1, 4094)]
        [uint16]$VID,

        [Parameter(ParameterSetName = 'Single', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('active', 'reserved', 'deprecated', IgnoreCase = $true)]
        [string]$Status = 'active',

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Tenant,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Site,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Group,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Role,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Description,

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
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'vlans'))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ParameterSetName -eq 'Bulk') {
            $bulkItems = [System.Collections.ArrayList]::new()
        }
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Single') {
            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

            if ($PSCmdlet.ShouldProcess("VLAN $VID ($Name)", 'Create new VLAN')) {
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

                    # Validate VID range in bulk mode
                    if ($key -eq 'vid') {
                        if ($value -lt 1 -or $value -gt 4094) {
                            Write-Warning "VLAN ID $value is invalid (must be 1-4094), skipping"
                            return
                        }
                    }

                    $item[$key] = $value
                }
                [void]$bulkItems.Add([PSCustomObject]$item)
            }
        }
    }

    end {
        if ($PSCmdlet.ParameterSetName -eq 'Bulk' -and $bulkItems.Count -gt 0) {
            $target = "$($bulkItems.Count) VLAN(s)"

            if ($Force -or $PSCmdlet.ShouldProcess($target, 'Create VLANs (bulk)')) {
                Write-Verbose "Processing $($bulkItems.Count) VLANs in bulk mode with batch size $BatchSize"

                $bulkParams = @{
                    URI          = $URI
                    Items        = $bulkItems.ToArray()
                    Method       = 'POST'
                    BatchSize    = $BatchSize
                    ShowProgress = $true
                    ActivityName = 'Creating VLANs'
                }
                $result = Send-NBBulkRequest @bulkParams

                # Output succeeded items to pipeline
                foreach ($item in $result.Succeeded) {
                    Write-Output $item
                }

                # Write errors for failed items
                foreach ($failure in $result.Failed) {
                    Write-Error "Failed to create VLAN: $($failure.Error)" -TargetObject $failure.Item
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
