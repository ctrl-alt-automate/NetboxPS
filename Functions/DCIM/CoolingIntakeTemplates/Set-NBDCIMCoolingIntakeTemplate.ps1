<#
.SYNOPSIS
    Updates an existing DCIM CoolingIntakeTemplate in Netbox DCIM module.

.DESCRIPTION
    Updates an existing Cooling Intake Template (NetBox 4.7+) via PATCH.
    Supports pipeline input for the Id parameter.
    Nullable numeric and FK parameters accept $null to clear the field;
    clearable enum parameters accept '' (empty string) to clear the field.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to update.

.PARAMETER Device_Type
    Device type this template belongs to (database ID). Mutually exclusive with -Module_Type. Pass $null to clear.

.PARAMETER Module_Type
    Module type this template belongs to (database ID). Mutually exclusive with -Device_Type. Pass $null to clear.

.PARAMETER Name
    Name of the template. Use {module} as a placeholder for the module bay position on module type templates.

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

.PARAMETER Max_Flow
    Maximum coolant flow rate (number, 0.01 - 1000000). Pass $null to clear.

.PARAMETER Max_Flow_Unit
    Unit for -Max_Flow: 'lpm', 'm3ph' or 'gpm'.
    Pass '' to clear the field server-side (sent as JSON null).
    NetBox requires a unit whenever -Max_Flow is set, so clear both
    together: -Max_Flow $null -Max_Flow_Unit ''.

.PARAMETER Description
    Brief description.

.EXAMPLE
    Set-NBDCIMCoolingIntakeTemplate -Id 5 -Label 'IN-1' -Type ''

    Sets the label and clears the connector type of cooling intake template 5.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.7.1.0
#>
function Set-NBDCIMCoolingIntakeTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [Nullable[uint64]]$Device_Type,

        [Nullable[uint64]]$Module_Type,

        [string]$Name,

        [string]$Label,

        [AllowEmptyString()]
        [ValidateSet('uqd', 'uqdb', 'qdc', 'camlock', 'npt', 'bsp', 'proprietary', '', IgnoreCase = $true)]
        [string]$Type,

        [Nullable[decimal]]$Diameter,

        [AllowEmptyString()]
        [ValidateSet('mm', 'cm', 'in', '', IgnoreCase = $true)]
        [string]$Diameter_Unit,

        [Nullable[decimal]]$Max_Flow,

        [AllowEmptyString()]
        [ValidateSet('lpm', 'm3ph', 'gpm', '', IgnoreCase = $true)]
        [string]$Max_Flow_Unit,

        [string]$Description,

        [switch]$Raw
    )
    process {
        # Translate '' -> $null for clearable enum params BEFORE
        # BuildURIComponents, so the PATCH body carries JSON null
        # (NetBox rejects "" for these nullable enum fields).
        foreach ($p in @('Type', 'Diameter_Unit', 'Max_Flow_Unit')) {
            if ($PSBoundParameters.ContainsKey($p) -and $PSBoundParameters[$p] -eq '') {
                $PSBoundParameters[$p] = $null
            }
        }

        Write-Verbose "Updating DCIM Cooling Intake Template ID $Id"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cooling-intake-templates', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update cooling intake template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
