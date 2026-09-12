function New-NBDCIMRack {
<#
    .SYNOPSIS
        Create a new rack in Netbox

    .DESCRIPTION
        Creates a new rack object in Netbox.

    .PARAMETER Name
        The name of the rack (required)

    .PARAMETER Site
        The site ID where the rack is located (required)

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

    .PARAMETER Form_Factor
        The rack form factor (NetBox 4.6+), e.g. '2-post-frame', '4-post-cabinet', 'wall-cabinet'.
        Deprecated in NetBox 4.7 in favour of the rack type; removed in NetBox 5.0.

    .PARAMETER Width
        The rack width (10 or 19 inches)
        Deprecated in NetBox 4.7 in favour of the rack type; removed in NetBox 5.0.

    .PARAMETER U_Height
        The height in rack units (default: 42)

    .PARAMETER Starting_Unit
        The starting unit number (default: 1)

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
        Requires NetBox 4.7.0 or later; ignored with a warning on older servers.

    .PARAMETER Cooling_Capacity
        Cooling capacity in kW. Requires NetBox 4.7.0 or later; ignored with a
        warning on older servers.
        When -Rack_Type is set, NetBox derives this value from the rack type
        and ignores the rack-level value.

    .PARAMETER Raw
        Return the raw API response

    .PARAMETER Tags
        One or more tags to assign to this object (tag names or IDs).

    .EXAMPLE
        New-NBDCIMRack -Name "Rack-01" -Site 1

        Creates a new rack named "Rack-01" at site 1

    .EXAMPLE
        New-NBDCIMRack -Name "Rack-02" -Site 1 -U_Height 48 -Status active

        Creates a 48U active rack at site 1
.NOTES
    AddedInVersion: v4.4.10.0

#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [uint64]$Site,

        [uint64]$Location,

        [uint64]$Tenant,

        [ValidateSet('active', 'planned', 'reserved', 'deprecated', 'available')]
        [string]$Status,

        [uint64]$Role,

        [string]$Serial,

        [string]$Asset_Tag,

        [uint64]$Rack_Type,

        [ValidateSet('front-to-rear', 'rear-to-front', IgnoreCase = $true)]
        [string]$Airflow,

        [ValidateSet('2-post-frame', '4-post-frame', '4-post-cabinet', 'wall-frame', 'wall-frame-vertical', 'wall-cabinet', 'wall-cabinet-vertical', IgnoreCase = $true)]
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

        [ValidateSet('air-only', 'hybrid', 'liquid-only', IgnoreCase = $true)]
        [string]$Cooling_Capability,

        [decimal]$Cooling_Capacity,

        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating DCIM Rack"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'racks'))

        # Rack-level geometry is now inferred from the rack type (Netbox 4.7); these params
        # still work but go away in Netbox 5.0. Version-gated: on 4.6 and older the rack type
        # does not carry the geometry, so these fields are the only way to express it.
        foreach ($p in @('Form_Factor', 'Width', 'Outer_Width', 'Outer_Depth', 'Outer_Height')) {
            $null = Test-NBDeprecatedParameter -ParameterName $p -DeprecatedInVersion '4.7.0' `
                -RemovedInVersion '5.0' -BoundParameters $PSBoundParameters `
                -ReplacementMessage 'Set the geometry on the rack type instead.'
        }

        # NetBox 4.7+ only fields: drop them with a warning on older servers.
        $skipParams = @('Raw')
        foreach ($p in @('Cooling_Capability', 'Cooling_Capacity')) {
            if (Test-NBMinimumVersion -ParameterName $p -MinimumVersion '4.7.0' -BoundParameters $PSBoundParameters -FeatureName "The -$p parameter") {
                $skipParams += $p
            }
        }

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName $skipParams

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create new rack')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
