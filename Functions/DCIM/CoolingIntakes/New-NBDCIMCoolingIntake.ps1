<#
.SYNOPSIS
    Creates a new DCIM CoolingIntake in Netbox DCIM module.

.DESCRIPTION
    Creates a new Cooling Intake (NetBox 4.7+).
    Supports pipeline input for bulk creation.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Device
    Device this component belongs to (database ID).

.PARAMETER Module
    Installed module this component belongs to (database ID).

.PARAMETER Name
    Name of the component.

.PARAMETER Label
    Physical label.

.PARAMETER Type
    Connector type: 'uqd', 'uqdb', 'qdc', 'camlock', 'npt', 'bsp'
    or 'proprietary'.

.PARAMETER Diameter
    Connector diameter (number, 0.01 - 1000000).

.PARAMETER Diameter_Unit
    Unit for -Diameter: 'mm', 'cm' or 'in'.

.PARAMETER Max_Flow
    Maximum coolant flow rate (number, 0.01 - 1000000).

.PARAMETER Max_Flow_Unit
    Unit for -Max_Flow: 'lpm', 'm3ph' or 'gpm'.

.PARAMETER Cooling_Outflow
    Upstream cooling outflow that serves this intake (database ID).

.PARAMETER Description
    Brief description.

.PARAMETER Owner
    Owner for object ownership (database ID).

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set.

.EXAMPLE
    New-NBDCIMCoolingIntake -Device 12 -Name 'Coolant In' -Type 'uqd' -Diameter 12.7 -Diameter_Unit 'mm' -Max_Flow 8 -Max_Flow_Unit 'lpm' -Cooling_Outflow 3

    Creates a UQD coolant intake on device 12 fed by cooling outflow 3.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.7.1.0
#>
function New-NBDCIMCoolingIntake {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [uint64]$Device,

        [uint64]$Module,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [string]$Label,

        [ValidateSet('uqd', 'uqdb', 'qdc', 'camlock', 'npt', 'bsp', 'proprietary', IgnoreCase = $true)]
        [string]$Type,

        [ValidateRange(0.01, 1000000)]
        [decimal]$Diameter,

        [ValidateSet('mm', 'cm', 'in', IgnoreCase = $true)]
        [string]$Diameter_Unit,

        [ValidateRange(0.01, 1000000)]
        [decimal]$Max_Flow,

        [ValidateSet('lpm', 'm3ph', 'gpm', IgnoreCase = $true)]
        [string]$Max_Flow_Unit,

        [uint64]$Cooling_Outflow,

        [string]$Description,

        [uint64]$Owner,

        [object[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )
    process {
        Write-Verbose "Creating DCIM Cooling Intake"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cooling-intakes'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create cooling intake')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
