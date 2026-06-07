<#
.SYNOPSIS
    Creates a new DCIM RackType in Netbox DCIM module.

.DESCRIPTION
    Creates a new DCIM RackType in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

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

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.EXAMPLE
    New-NBDCIMRackType

    Creates a new DCIM RackType object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBDCIMRackType {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Manufacturer,
        [Parameter(Mandatory = $true)][string]$Model,
        [string]$Slug,
        [Parameter(Mandatory = $true)][string]$Form_Factor,
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
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating DCIM Rack Type"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','rack-types'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Model, 'Create rack type')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
