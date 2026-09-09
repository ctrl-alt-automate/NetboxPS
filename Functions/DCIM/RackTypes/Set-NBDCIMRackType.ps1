<#
.SYNOPSIS
    Updates an existing DCIM RackType in Netbox DCIM module.

.DESCRIPTION
    Updates an existing DCIM RackType in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to update.

.PARAMETER Manufacturer
    Manufacturer assigned to this object (database ID).

.PARAMETER Model
    Model name.

.PARAMETER Slug
    URL-friendly unique identifier (slug).

.PARAMETER Form_Factor
    Form Factor.

.PARAMETER Width
    Width.

.PARAMETER U_Height
    Height in rack units

.PARAMETER Starting_Unit
    Starting unit for rack

.PARAMETER Outer_Width
    Outer dimension of rack (width)

.PARAMETER Outer_Depth
    Outer dimension of rack (depth)

.PARAMETER Outer_Unit
    Outer Unit.

.PARAMETER Weight
    Numeric weight value.

.PARAMETER Max_Weight
    Maximum load capacity for the rack

.PARAMETER Weight_Unit
    Unit of measurement for the weight.

.PARAMETER Mounting_Depth
    Maximum depth of a mounted device, in millimeters. For four-post racks, this is the distance between the front and rear rails.

.PARAMETER Description
    Brief description.

.PARAMETER Comments
    Detailed comments (Markdown is supported).

.PARAMETER Cooling_Capability
    Cooling capability. One of: 'air-only', 'hybrid', 'liquid-only'.
    Pass '' to clear the field server-side (sent as JSON null).
    Requires NetBox 4.7.0 or later; ignored with a warning on older servers.

.PARAMETER Cooling_Capacity
    Cooling capacity in kW. Pass $null to clear. Requires NetBox 4.7.0 or
    later; ignored with a warning on older servers.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.EXAMPLE
    Set-NBDCIMRackType

    Updates an existing DCIM RackType object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBDCIMRackType {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Manufacturer,
        [string]$Model,
        [string]$Slug,
        [string]$Form_Factor,
        [uint16]$Width,
        [uint16]$U_Height,
        [uint16]$Starting_Unit,
        [uint16]$Outer_Width,
        [uint16]$Outer_Depth,
        [string]$Outer_Unit,
        [uint16]$Weight,
        [uint16]$Max_Weight,
        [string]$Weight_Unit,
        [string]$Mounting_Depth,
        [string]$Description,
        [string]$Comments,
        [AllowEmptyString()]
        [ValidateSet('air-only', 'hybrid', 'liquid-only', '', IgnoreCase = $true)]
        [string]$Cooling_Capability,
        [Nullable[decimal]]$Cooling_Capacity,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Updating DCIM Rack Type"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','rack-types',$Id))

        # Translate '' -> $null for clearable enum params BEFORE BuildURIComponents,
        # so the PATCH body carries JSON null (NetBox rejects "" for nullable enums).
        foreach ($p in @('Cooling_Capability')) {
            if ($PSBoundParameters.ContainsKey($p) -and $PSBoundParameters[$p] -eq '') {
                $PSBoundParameters[$p] = $null
            }
        }

        # NetBox 4.7+ only fields: drop them with a warning on older servers.
        $skipParams = @('Id', 'Raw')
        foreach ($p in @('Cooling_Capability', 'Cooling_Capacity')) {
            if (Test-NBMinimumVersion -ParameterName $p -MinimumVersion '4.7.0' -BoundParameters $PSBoundParameters -FeatureName "The -$p parameter") {
                $skipParams += $p
            }
        }

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName $skipParams
        if ($PSCmdlet.ShouldProcess($Id, 'Update rack type')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
