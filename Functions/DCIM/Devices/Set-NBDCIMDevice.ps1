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

.PARAMETER Location
    The location ID within the site. Pass $null to clear.

.PARAMETER Airflow
    Airflow direction. One of: front-to-rear, rear-to-front, left-to-right,
    right-to-left, side-to-rear, rear-to-side, bottom-to-top, top-to-bottom,
    passive, mixed. Pass an empty string ('') to clear (Airflow is
    enum-nullable, same idiom as Set-NBDCIMInterface -Duplex '').

.PARAMETER OOB_IP
    Out-of-band IP address ID. Pass $null to clear.

.PARAMETER Latitude
    GPS latitude in decimal degrees (-90 to 90). Pass $null to clear.

.PARAMETER Longitude
    GPS longitude in decimal degrees (-180 to 180). Pass $null to clear.

.PARAMETER Config_Template
    Config template ID assigned to the device. Pass $null to clear.

.PARAMETER Local_Context_Data
    Local config context data (free-form JSON; hashtable or object). Takes
    precedence over source contexts. Pass $null to clear.

.PARAMETER Virtual_Chassis
    Virtual Chassis.

.PARAMETER VC_Priority
    Virtual chassis master election priority

.PARAMETER VC_Position
    VC Position.

.PARAMETER Primary_IP4
    Primary IPv4 address assigned to this object (database ID).

.PARAMETER Primary_IP6
    Primary IPv6 address assigned to this object (database ID).

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    Set-NBDCIMDevice -Id 123 -Cluster $null

    Clears the Cluster assignment on device 123. Also works for Platform,
    Tenant, Rack, Position, Virtual_Chassis, VC_Position, VC_Priority,
    Primary_IP4, Primary_IP6, Owner, Location, OOB_IP, Config_Template,
    Latitude, Longitude, and Local_Context_Data. Clear Airflow with -Airflow ''.

.EXAMPLE
    Set-NBDCIMDevice -Id 123 -Airflow front-to-rear -Latitude 52.37 -Longitude 4.89

    Sets airflow direction and GPS coordinates. Pass -Airflow '' to clear
    airflow; pass -Latitude $null / -Longitude $null to clear coordinates.

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

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[uint64]]$Location,

        [Parameter(ParameterSetName = 'Single')]
        [AllowEmptyString()]
        [ValidateSet('front-to-rear', 'rear-to-front', 'left-to-right', 'right-to-left',
            'side-to-rear', 'rear-to-side', 'bottom-to-top', 'top-to-bottom',
            'passive', 'mixed', '', IgnoreCase = $true)]
        [string]$Airflow,

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[uint64]]$OOB_IP,

        [Parameter(ParameterSetName = 'Single')]
        # [Nullable[double]] with no [ValidateRange]: latitude is a nullable
        # float and -Latitude $null clears it. [ValidateRange] fires before
        # [Nullable[T]] binding, so the range check would throw on $null
        # (see #398, #412). Server enforces the -90..90 bound; New- keeps
        # [ValidateRange] since its Latitude is non-nullable. Refs #411.
        [Nullable[double]]$Latitude,

        [Parameter(ParameterSetName = 'Single')]
        # See Latitude: nullable float, no [ValidateRange] (#398/#412).
        # Server enforces -180..180. Refs #411.
        [Nullable[double]]$Longitude,

        [Parameter(ParameterSetName = 'Single')]
        [Nullable[uint64]]$Config_Template,

        [Parameter(ParameterSetName = 'Single')]
        [object]$Local_Context_Data,

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
        # Translate the empty-string sentinel to $null so -Airflow '' clears
        # the field server-side: BuildURIComponents + ConvertTo-Json emit
        # "airflow": null on the wire, which NetBox PATCH accepts (airflow is
        # enum-nullable). Same idiom as Set-NBDCIMInterface -Duplex '' (#401).
        if ($PSBoundParameters.ContainsKey('Airflow') -and $PSBoundParameters['Airflow'] -eq '') {
            $PSBoundParameters['Airflow'] = $null
        }

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
