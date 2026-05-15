<#
.SYNOPSIS
    Updates one or more devices in Netbox DCIM module.

.DESCRIPTION
    Updates existing devices in Netbox DCIM module. Supports both single device
    updates with individual parameters and bulk updates via pipeline input.

    For bulk operations, use the -BatchSize parameter to control how many
    devices are sent per API request. Each object must have an Id property.

.PARAMETER Id
    The database ID of the device to update. Required for single updates.

.PARAMETER Name
    The new name for the device.

.PARAMETER Role
    The device role ID.
    Alias: Device_Role (backwards compatibility)

.PARAMETER Device_Type
    The device type ID.

.PARAMETER Site
    The site ID.

.PARAMETER Status
    Status of the device.

.PARAMETER Platform
    The platform ID.

.PARAMETER Tenant
    The tenant ID.

.PARAMETER Cluster
    The cluster ID.

.PARAMETER Rack
    The rack ID.

.PARAMETER Position
    Rack-unit position (U). Accepts fractional values for half-U devices
    (e.g. 1.5, 2.5). Pass $null to clear (unrack the device).

.PARAMETER Face
    Face of the device in the rack.

.PARAMETER Serial
    Serial number.

.PARAMETER Asset_Tag
    Asset tag.

.PARAMETER Comments
    Comments about the device.

.PARAMETER Description
    Short description of the device. Pass an empty string to clear the
    field in Netbox (Description is empty-string-compatible, not nullable).

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Owner
    The owner ID for object ownership (Netbox 4.5+ only).

.EXAMPLE
    Set-NBDCIMDevice -Id 123 -Cluster $null

    Clears the Cluster assignment on device 123. Also works for Platform,
    Tenant, Rack, Position, Virtual_Chassis, VC_Position, VC_Priority,
    Primary_IP4, Primary_IP6, and Owner.

.EXAMPLE
    Set-NBDCIMDevice -Id 123 -Description "Replaces legacy gateway"

    Sets the Description. Pass -Description '' to clear it server-side.

.PARAMETER InputObject
    Pipeline input for bulk operations. Each object MUST have an Id property.

.PARAMETER BatchSize
    Number of devices to update per API request in bulk mode.
    Default: 50, Range: 1-1000

.PARAMETER Force
    Skip confirmation prompts.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMDevice -Id 123 -Status "active"

    Updates device 123 to active status.

.EXAMPLE
    Get-NBDCIMDevice -Status "planned" | ForEach-Object {
        [PSCustomObject]@{Id = $_.id; Status = "active"}
    } | Set-NBDCIMDevice -Force

    Bulk update all planned devices to active status.

.EXAMPLE
    $updates = @(
        [PSCustomObject]@{Id = 100; Status = "active"; Comments = "Deployed"}
        [PSCustomObject]@{Id = 101; Status = "active"; Comments = "Deployed"}
    )
    $updates | Set-NBDCIMDevice -BatchSize 50 -Force

    Bulk update multiple devices with different values.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v1.0.4

#>

function Set-NBDCIMDevice {
    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium',
        DefaultParameterSetName = 'Single')]
    [OutputType([PSCustomObject])]
    param(
        # Single mode parameters
        [Parameter(ParameterSetName = 'Single', Mandatory = $true)]
        [uint64]$Id,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Name,

        [Parameter(ParameterSetName = 'Single')]
        [Alias('Device_Role')]
        [object]$Role,

        [Parameter(ParameterSetName = 'Single')]
        [object]$Device_Type,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Site,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('offline', 'active', 'planned', 'staged', 'failed', 'inventory', 'decommissioning', IgnoreCase = $true)]
        [string]$Status,

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[uint64]]$Platform,

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[uint64]]$Tenant,

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[uint64]]$Cluster,

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[uint64]]$Rack,

        [Parameter(ParameterSetName = 'Single')]
        # [double] not [uint16]: NetBox rack position is a float (half-U
        # devices at 1.5/2.5/...). No [ValidateRange] here -- it fires before
        # [Nullable[T]] binding, so -Position $null (clear) would throw
        # ValidationMetadataException (see #398). Server-side validation
        # handles the 0.5..<1000 bound. Refs #412.
        [Nullable[double]]$Position,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('front', 'rear', IgnoreCase = $true)]
        [string]$Face,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Serial,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Asset_Tag,

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[uint64]]$Virtual_Chassis,

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[uint64]]$VC_Priority,

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[uint64]]$VC_Position,

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[uint64]]$Primary_IP4,

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[uint64]]$Primary_IP6,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Comments,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Description,

        [Parameter(ParameterSetName = 'Single')]
        [hashtable]$Custom_Fields,

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[uint64]]$Owner,

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
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'devices'))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ParameterSetName -eq 'Bulk') {
            $bulkItems = [System.Collections.ArrayList]::new()
        }
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Single') {
            # Use Id directly - no need to fetch device first (saves an API call per update)
            if ($Force -or $PSCmdlet.ShouldProcess("Device ID $Id", "Update device")) {
                $DeviceSegments = [System.Collections.ArrayList]::new(@('dcim', 'devices', $Id))

                $URIComponents = BuildURIComponents -URISegments $DeviceSegments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Force', 'Raw'

                $DeviceURI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $DeviceURI -Body $URIComponents.Parameters -Method PATCH -Raw:$Raw
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

                    # Handle property name mappings
                    switch ($key) {
                        'device_role' { $key = 'role' }
                    }

                    $item[$key] = $value
                }
                [void]$bulkItems.Add([PSCustomObject]$item)
            }
        }
    }

    end {
        if ($PSCmdlet.ParameterSetName -eq 'Bulk' -and $bulkItems.Count -gt 0) {
            $target = "$($bulkItems.Count) device(s)"

            if ($Force -or $PSCmdlet.ShouldProcess($target, 'Update devices (bulk)')) {
                Write-Verbose "Processing $($bulkItems.Count) devices in bulk PATCH mode with batch size $BatchSize"

                $bulkParams = @{
                    URI          = $URI
                    Items        = $bulkItems.ToArray()
                    Method       = 'PATCH'
                    BatchSize    = $BatchSize
                    ShowProgress = $true
                    ActivityName = 'Updating devices'
                }
                $result = Send-NBBulkRequest @bulkParams

                # Output succeeded items to pipeline
                foreach ($item in $result.Succeeded) {
                    Write-Output $item
                }

                # Write errors for failed items
                foreach ($failure in $result.Failed) {
                    Write-Error "Failed to update device: $($failure.Error)" -TargetObject $failure.Item
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
