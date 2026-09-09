<#
.SYNOPSIS
    Updates an existing Cooling Source in Netbox DCIM module.

.DESCRIPTION
    Updates an existing Cooling Source in Netbox DCIM module (NetBox 4.7+)
    via a PATCH request. Only the parameters you supply are sent.
    Supports pipeline input for the Id parameter.

    Nullable fields can be cleared server-side:
    - Pass $null to -Location or -Cooling_Capacity.
    - Pass '' (empty string) to -Fluid_Type.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the cooling source to update.

.PARAMETER Site
    Site this cooling source is installed at (database ID).

.PARAMETER Location
    Location within the site (database ID). Pass $null to clear.

.PARAMETER Name
    Name of the cooling source.

.PARAMETER Type
    Type of cooling equipment: chiller, cooling-tower, dry-cooler, crac or crah.

.PARAMETER Status
    Operational status: offline, active, planned or failed.

.PARAMETER Fluid_Type
    Cooling fluid type: water, water-glycol, dielectric or refrigerant.
    Pass '' (empty string) to clear the field server-side.

.PARAMETER Cooling_Capacity
    Total rated cooling capacity in kW. Pass $null to clear.

.PARAMETER Description
    Brief description.

.PARAMETER Owner
    Owner of this object (database ID).

.PARAMETER Comments
    Detailed comments (Markdown is supported).

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.EXAMPLE
    Set-NBDCIMCoolingSource -Id 5 -Status offline

    Marks cooling source ID 5 as offline.

.EXAMPLE
    Set-NBDCIMCoolingSource -Id 5 -Fluid_Type '' -Cooling_Capacity $null

    Clears the fluid type and cooling capacity of cooling source ID 5.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.7.1.0
    Requires NetBox 4.7.0 or later.

#>
function Set-NBDCIMCoolingSource {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [uint64]$Site,

        [Nullable[uint64]]$Location,

        [string]$Name,

        [ValidateSet('chiller', 'cooling-tower', 'dry-cooler', 'crac', 'crah')]
        [string]$Type,

        [ValidateSet('offline', 'active', 'planned', 'failed')]
        [string]$Status,

        [AllowEmptyString()]
        [ValidateSet('water', 'water-glycol', 'dielectric', 'refrigerant', '')]
        [string]$Fluid_Type,

        [Nullable[decimal]]$Cooling_Capacity,

        [string]$Description,

        [uint64]$Owner,

        [string]$Comments,

        [object[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )
    process {
        Write-Verbose "Updating DCIM Cooling Source"

        # Translate '' -> $null for clearable enum params BEFORE
        # BuildURIComponents, so the PATCH body carries JSON null
        # (NetBox rejects "" for these nullable enum fields).
        foreach ($p in @('Fluid_Type')) {
            if ($PSBoundParameters.ContainsKey($p) -and $PSBoundParameters[$p] -eq '') {
                $PSBoundParameters[$p] = $null
            }
        }

        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cooling-sources', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update cooling source')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
