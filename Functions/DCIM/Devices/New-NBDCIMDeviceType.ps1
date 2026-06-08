<#
.SYNOPSIS
    Creates a new DCIM DeviceType in Netbox DCIM module.

.DESCRIPTION
    Creates a new DCIM DeviceType in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

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

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.EXAMPLE
    New-NBDCIMDeviceType

    Creates a new DCIM DeviceType object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBDCIMDeviceType {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Manufacturer,
        [Parameter(Mandatory = $true)][string]$Model,
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
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating DCIM Device Type"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','device-types'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Model, 'Create device type')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
