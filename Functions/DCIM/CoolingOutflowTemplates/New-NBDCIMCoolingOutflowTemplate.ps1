<#
.SYNOPSIS
    Creates a new DCIM CoolingOutflowTemplate in Netbox DCIM module.

.DESCRIPTION
    Creates a new Cooling Outflow Template (NetBox 4.7+).
    Supports pipeline input for bulk creation.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Device_Type
    Device type this template belongs to (database ID). Mutually exclusive with -Module_Type.

.PARAMETER Module_Type
    Module type this template belongs to (database ID). Mutually exclusive with -Device_Type.

.PARAMETER Name
    Name of the template. Use {module} as a placeholder for the module bay position on module type templates.

.PARAMETER Label
    Physical label.

.PARAMETER Type
    Connector type: 'uqd', 'uqdb', 'qdc', 'camlock', 'npt', 'bsp'
    or 'proprietary'.

.PARAMETER Diameter
    Connector diameter (number, 0.01 - 1000000).

.PARAMETER Diameter_Unit
    Unit for -Diameter: 'mm', 'cm' or 'in'.

.PARAMETER Cooling_Intake
    Cooling intake template on the same device type that this outflow template is paired with (database ID).

.PARAMETER Description
    Brief description.

.EXAMPLE
    New-NBDCIMCoolingOutflowTemplate -Device_Type 4 -Name 'Coolant Out' -Type 'uqd' -Cooling_Intake 9

    Creates a cooling outflow template on device type 4 paired with intake template 9.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.7.1.0
#>
function New-NBDCIMCoolingOutflowTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [uint64]$Device_Type,

        [uint64]$Module_Type,

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

        [uint64]$Cooling_Intake,

        [string]$Description,

        [switch]$Raw
    )
    process {
        Write-Verbose "Creating DCIM Cooling Outflow Template"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cooling-outflow-templates'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create cooling outflow template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
