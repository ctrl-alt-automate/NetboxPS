<#
.SYNOPSIS
    Updates an existing DCIM DeviceType in Netbox DCIM module.

.DESCRIPTION
    Updates an existing DCIM DeviceType in Netbox DCIM module.
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

.PARAMETER Part_Number
    Discrete part number (optional)

.PARAMETER U_Height
    Height in rack units

.PARAMETER Is_Full_Depth
    Device consumes both front and rear rack faces.

.PARAMETER Subdevice_Role
    Subdevice Role.

.PARAMETER Airflow
    Airflow.

.PARAMETER Weight
    Numeric weight value.

.PARAMETER Weight_Unit
    Unit of measurement for the weight.

.PARAMETER Description
    Brief description.

.PARAMETER Comments
    Detailed comments (Markdown is supported).

.PARAMETER Cooling_Method
    Cooling method. One of: 'air', 'liquid', 'hybrid', 'immersion'.
    Pass '' to clear the field server-side (sent as JSON null).
    Requires NetBox 4.7.0 or later; ignored with a warning on older servers.

.PARAMETER End_Of_Life
    Date after which this device type is no longer supported by the manufacturer.
    Sent as yyyy-MM-dd. Pass $null to clear. Requires NetBox 4.7.0 or later;
    ignored with a warning on older servers.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.EXAMPLE
    Set-NBDCIMDeviceType

    Updates an existing DCIM DeviceType object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBDCIMDeviceType {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Manufacturer,
        [string]$Model,
        [string]$Slug,
        [string]$Part_Number,
        [uint16]$U_Height,
        [bool]$Is_Full_Depth,
        [string]$Subdevice_Role,
        [string]$Airflow,
        [uint16]$Weight,
        [string]$Weight_Unit,
        [string]$Description,
        [string]$Comments,
        [AllowEmptyString()]
        [ValidateSet('air', 'liquid', 'hybrid', 'immersion', '', IgnoreCase = $true)]
        [string]$Cooling_Method,
        [Nullable[datetime]]$End_Of_Life,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Updating DCIM Device Type"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','device-types',$Id))

        # Translate '' -> $null for clearable enum params BEFORE BuildURIComponents,
        # so the PATCH body carries JSON null (NetBox rejects "" for nullable enums).
        foreach ($p in @('Cooling_Method')) {
            if ($PSBoundParameters.ContainsKey($p) -and $PSBoundParameters[$p] -eq '') {
                $PSBoundParameters[$p] = $null
            }
        }

        # NetBox DateField wants yyyy-MM-dd, not the ISO datetime ConvertTo-Json emits.
        if ($PSBoundParameters.ContainsKey('End_Of_Life') -and $null -ne $PSBoundParameters['End_Of_Life']) {
            $PSBoundParameters['End_Of_Life'] = ([datetime]$PSBoundParameters['End_Of_Life']).ToString('yyyy-MM-dd')
        }

        # NetBox 4.7+ only fields: drop them with a warning on older servers.
        $skipParams = @('Id', 'Raw')
        foreach ($p in @('Cooling_Method', 'End_Of_Life')) {
            if (Test-NBMinimumVersion -ParameterName $p -MinimumVersion '4.7.0' -BoundParameters $PSBoundParameters -FeatureName "The -$p parameter") {
                $skipParams += $p
            }
        }

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName $skipParams
        if ($PSCmdlet.ShouldProcess($Id, 'Update device type')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
