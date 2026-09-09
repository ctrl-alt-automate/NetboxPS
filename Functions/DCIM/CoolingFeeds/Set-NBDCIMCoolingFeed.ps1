<#
.SYNOPSIS
    Updates an existing Cooling Feed in Netbox DCIM module.

.DESCRIPTION
    Updates an existing Cooling Feed in Netbox DCIM module (NetBox 4.7+)
    via a PATCH request. Only the parameters you supply are sent.
    Supports pipeline input for the Id parameter.

    Nullable fields can be cleared server-side:
    - Pass $null to -Rack, -Tenant, -Cooling_Capacity or -Max_Flow.
    - Pass '' (empty string) to -Max_Flow_Unit.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the cooling feed to update.

.PARAMETER Cooling_Source
    Cooling source this feed is provisioned from (database ID).

.PARAMETER Rack
    Rack this feed supplies (database ID). Pass $null to clear.

.PARAMETER Name
    Name of the cooling feed.

.PARAMETER Status
    Operational status: offline, active, planned or failed.

.PARAMETER Cooling_Capacity
    Rated cooling capacity in kW. Pass $null to clear.

.PARAMETER Max_Flow
    Maximum flow rate, expressed in the unit given by -Max_Flow_Unit. Pass $null to clear.

.PARAMETER Max_Flow_Unit
    Unit for -Max_Flow: lpm (liters per minute), m3ph (cubic meters per hour) or gpm (gallons per minute).
    Pass '' (empty string) to clear the field server-side.

.PARAMETER Description
    Brief description.

.PARAMETER Tenant
    Tenant assigned to this object (database ID). Pass $null to clear.

.PARAMETER Owner
    Owner of this object (database ID).

.PARAMETER Comments
    Detailed comments (Markdown is supported).

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.EXAMPLE
    Set-NBDCIMCoolingFeed -Id 7 -Status offline

    Marks cooling feed ID 7 as offline.

.EXAMPLE
    Set-NBDCIMCoolingFeed -Id 7 -Rack $null -Max_Flow_Unit ''

    Detaches cooling feed ID 7 from its rack and clears the flow unit.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.7.0.1
    Requires NetBox 4.7.0 or later.

#>
function Set-NBDCIMCoolingFeed {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [uint64]$Cooling_Source,

        [Nullable[uint64]]$Rack,

        [string]$Name,

        [ValidateSet('offline', 'active', 'planned', 'failed')]
        [string]$Status,

        [Nullable[decimal]]$Cooling_Capacity,

        [Nullable[decimal]]$Max_Flow,

        [AllowEmptyString()]
        [ValidateSet('lpm', 'm3ph', 'gpm', '')]
        [string]$Max_Flow_Unit,

        [string]$Description,

        [Nullable[uint64]]$Tenant,

        [uint64]$Owner,

        [string]$Comments,

        [object[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )
    process {
        Write-Verbose "Updating DCIM Cooling Feed"

        # Translate '' -> $null for clearable enum params BEFORE
        # BuildURIComponents, so the PATCH body carries JSON null
        # (NetBox rejects "" for these nullable enum fields).
        foreach ($p in @('Max_Flow_Unit')) {
            if ($PSBoundParameters.ContainsKey($p) -and $PSBoundParameters[$p] -eq '') {
                $PSBoundParameters[$p] = $null
            }
        }

        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cooling-feeds', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update cooling feed')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
