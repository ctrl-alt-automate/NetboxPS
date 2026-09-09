<#
.SYNOPSIS
    Updates an existing DCIM CoolingOutflow in Netbox DCIM module.

.DESCRIPTION
    Updates an existing Cooling Outflow (NetBox 4.7+) via PATCH.
    Supports pipeline input for the Id parameter.
    Nullable numeric and FK parameters accept $null to clear the field;
    clearable enum parameters accept '' (empty string) to clear the field.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to update.

.PARAMETER Device
    Device this component belongs to (database ID).

.PARAMETER Module
    Installed module this component belongs to (database ID). Pass $null to clear.

.PARAMETER Name
    Name of the component.

.PARAMETER Label
    Physical label.

.PARAMETER Type
    Connector type: 'uqd', 'uqdb', 'qdc', 'camlock', 'npt', 'bsp'
    or 'proprietary'.
    Pass '' to clear the field server-side (sent as JSON null).

.PARAMETER Diameter
    Connector diameter (number, 0.01 - 1000000). Pass $null to clear.

.PARAMETER Diameter_Unit
    Unit for -Diameter: 'mm', 'cm' or 'in'.
    Pass '' to clear the field server-side (sent as JSON null).
    NetBox requires a unit whenever -Diameter is set, so clear both
    together: -Diameter $null -Diameter_Unit ''.

.PARAMETER Cooling_Intake
    Cooling intake on the same device that this outflow is paired with (database ID). Pass $null to clear.

.PARAMETER Description
    Brief description.

.PARAMETER Owner
    Owner for object ownership (database ID).

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set.

.EXAMPLE
    Set-NBDCIMCoolingOutflow -Id 5 -Label 'OUT-1' -Cooling_Intake 7

    Sets the label and pairs cooling outflow 5 with intake 7.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.7.0.1
#>
function Set-NBDCIMCoolingOutflow {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [uint64]$Device,

        [Nullable[uint64]]$Module,

        [string]$Name,

        [string]$Label,

        [AllowEmptyString()]
        [ValidateSet('uqd', 'uqdb', 'qdc', 'camlock', 'npt', 'bsp', 'proprietary', '', IgnoreCase = $true)]
        [string]$Type,

        [Nullable[decimal]]$Diameter,

        [AllowEmptyString()]
        [ValidateSet('mm', 'cm', 'in', '', IgnoreCase = $true)]
        [string]$Diameter_Unit,

        [Nullable[uint64]]$Cooling_Intake,

        [string]$Description,

        [uint64]$Owner,

        [object[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )
    process {
        # Translate '' -> $null for clearable enum params BEFORE
        # BuildURIComponents, so the PATCH body carries JSON null
        # (NetBox rejects "" for these nullable enum fields).
        foreach ($p in @('Type', 'Diameter_Unit')) {
            if ($PSBoundParameters.ContainsKey($p) -and $PSBoundParameters[$p] -eq '') {
                $PSBoundParameters[$p] = $null
            }
        }

        Write-Verbose "Updating DCIM Cooling Outflow ID $Id"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cooling-outflows', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update cooling outflow')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
