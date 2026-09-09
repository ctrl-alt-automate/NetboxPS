function Set-NBDCIMRack {
<#
    .SYNOPSIS
        Update a rack in Netbox

    .DESCRIPTION
        Updates an existing rack object in Netbox.

    .PARAMETER Id
        The ID of the rack to update

    .PARAMETER Name
        The name of the rack

    .PARAMETER Site
        The site ID where the rack is located

    .PARAMETER Location
        The location ID within the site

    .PARAMETER Tenant
        The tenant ID that owns this rack

    .PARAMETER Status
        The operational status (active, planned, reserved, deprecated)

    .PARAMETER Role
        The rack role ID

    .PARAMETER Serial
        The serial number

    .PARAMETER Asset_Tag
        The asset tag

    .PARAMETER Rack_Type
        The rack type ID

    .PARAMETER Airflow
        The rack airflow direction (NetBox 4.6+): 'front-to-rear' or 'rear-to-front'.
        Pass '' to clear the field server-side (sent as JSON null).

    .PARAMETER Form_Factor
        The rack form factor (NetBox 4.6+), e.g. '2-post-frame', '4-post-cabinet'.
        Pass '' to clear the field server-side (sent as JSON null).
        Deprecated in NetBox 4.7 in favour of the rack type; removed in NetBox 5.0.

    .PARAMETER Width
        The rack width (10 or 19 inches)
        Deprecated in NetBox 4.7 in favour of the rack type; removed in NetBox 5.0.

    .PARAMETER U_Height
        The height in rack units

    .PARAMETER Starting_Unit
        The starting unit number

    .PARAMETER Desc_Units
        Whether units are numbered top-to-bottom

    .PARAMETER Outer_Width
        The outer width in millimeters
        Deprecated in NetBox 4.7 in favour of the rack type; removed in NetBox 5.0.

    .PARAMETER Outer_Depth
        The outer depth in millimeters
        Deprecated in NetBox 4.7 in favour of the rack type; removed in NetBox 5.0.

    .PARAMETER Outer_Height
        The outer height in millimeters
        Deprecated in NetBox 4.7 in favour of the rack type; removed in NetBox 5.0.

    .PARAMETER Mounting_Depth
        The mounting depth in millimeters

    .PARAMETER Max_Weight
        The maximum weight capacity

    .PARAMETER Weight_Unit
        The weight unit (kg, g, lb, oz)

    .PARAMETER Facility_Id
        The facility identifier

    .PARAMETER Description
        A description of the rack

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Owner
        The owner ID for object ownership (Netbox 4.5+ only).

    .PARAMETER Cooling_Capability
        Cooling capability. One of: 'air-only', 'hybrid', 'liquid-only'.
        When -Rack_Type is set, NetBox derives this value from the rack type
        and ignores the rack-level value.
        Pass '' to clear the field server-side (sent as JSON null).
        Requires NetBox 4.7.0 or later; ignored with a warning on older servers.

    .PARAMETER Cooling_Capacity
        Cooling capacity in kW. Pass $null to clear. Requires NetBox 4.7.0 or
        later; ignored with a warning on older servers.
        When -Rack_Type is set, NetBox derives this value from the rack type
        and ignores the rack-level value.

    .PARAMETER Force
        Skip confirmation prompts

    .PARAMETER Tags
        One or more tags to assign to this object (tag names or IDs).

    .PARAMETER Raw
        Return the raw API response object instead of the .results collection.

    .EXAMPLE
        Set-NBDCIMRack -Id 1 -Description "Updated description"

    .EXAMPLE
        Get-NBDCIMRack -Name "Rack-01" | Set-NBDCIMRack -Status deprecated
.NOTES
    AddedInVersion: v4.4.10.0

#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [uint64]$Site,

        [uint64]$Location,

        [uint64]$Tenant,

        [ValidateSet('active', 'planned', 'reserved', 'deprecated', 'available')]
        [string]$Status,

        [uint64]$Role,

        [string]$Serial,

        [string]$Asset_Tag,

        [uint64]$Rack_Type,

        [AllowEmptyString()]
        [ValidateSet('front-to-rear', 'rear-to-front', '', IgnoreCase = $true)]
        [string]$Airflow,

        [AllowEmptyString()]
        [ValidateSet('2-post-frame', '4-post-frame', '4-post-cabinet', 'wall-frame', 'wall-frame-vertical', 'wall-cabinet', 'wall-cabinet-vertical', '', IgnoreCase = $true)]
        [string]$Form_Factor,

        [ValidateSet(10, 19, 21, 23)]
        [uint16]$Width,

        [ValidateRange(1, 100)]
        [uint16]$U_Height,

        [ValidateRange(1, 100)]
        [uint16]$Starting_Unit,

        [bool]$Desc_Units,

        [uint16]$Outer_Width,

        [uint16]$Outer_Depth,

        [uint16]$Outer_Height,

        [uint16]$Mounting_Depth,

        [uint32]$Max_Weight,

        [ValidateSet('kg', 'g', 'lb', 'oz')]
        [string]$Weight_Unit,

        [string]$Facility_Id,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [uint64]$Owner,

        [AllowEmptyString()]
        [ValidateSet('air-only', 'hybrid', 'liquid-only', '', IgnoreCase = $true)]
        [string]$Cooling_Capability,

        [Nullable[decimal]]$Cooling_Capacity,

        [switch]$Force,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating DCIM Rack"

        # Translate '' -> $null for clearable enum params BEFORE
        # BuildURIComponents, so the PATCH body carries JSON null
        # (NetBox rejects "" for these nullable enum fields).
        foreach ($p in @('Airflow', 'Form_Factor', 'Cooling_Capability')) {
            if ($PSBoundParameters.ContainsKey($p) -and $PSBoundParameters[$p] -eq '') {
                $PSBoundParameters[$p] = $null
            }
        }

        # Rack-level geometry is now inferred from the rack type (NetBox 4.7);
        # these params still work but go away in NetBox 5.0.
        foreach ($p in @('Form_Factor', 'Width', 'Outer_Width', 'Outer_Depth', 'Outer_Height')) {
            if ($PSBoundParameters.ContainsKey($p)) {
                Write-Verbose "-$p is deprecated in NetBox 4.7 in favour of the rack type and will be removed in NetBox 5.0."
            }
        }

        # NetBox 4.7+ only fields: drop them with a warning on older servers.
        $skipParams = @('Id', 'Raw', 'Force')
        foreach ($p in @('Cooling_Capability', 'Cooling_Capacity')) {
            if (Test-NBMinimumVersion -ParameterName $p -MinimumVersion '4.7.0' -BoundParameters $PSBoundParameters -FeatureName "The -$p parameter") {
                $skipParams += $p
            }
        }

        foreach ($RackId in $Id) {

            if ($Force -or $PSCmdlet.ShouldProcess("ID $RackId", "Update rack")) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'racks', $RackId))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName $skipParams

                $URI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method PATCH -Raw:$Raw
            }
        }
    }
}
