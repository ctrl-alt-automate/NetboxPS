<#
.SYNOPSIS
    Creates a new Cooling Feed in Netbox DCIM module.

.DESCRIPTION
    Creates a new Cooling Feed in Netbox DCIM module (NetBox 4.7+).
    A cooling feed delivers cooling capacity from a cooling source to a
    rack, analogous to a power feed in the power distribution model.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Cooling_Source
    Cooling source this feed is provisioned from (database ID). Required.

.PARAMETER Rack
    Rack this feed supplies (database ID).

.PARAMETER Name
    Name of the cooling feed. Required.

.PARAMETER Status
    Operational status: offline, active, planned or failed. Defaults to active server-side.

.PARAMETER Cooling_Capacity
    Rated cooling capacity in kW.

.PARAMETER Max_Flow
    Maximum flow rate, expressed in the unit given by -Max_Flow_Unit.

.PARAMETER Max_Flow_Unit
    Unit for -Max_Flow: lpm (liters per minute), m3ph (cubic meters per hour) or gpm (gallons per minute).

.PARAMETER Description
    Brief description.

.PARAMETER Tenant
    Tenant assigned to this object (database ID).

.PARAMETER Owner
    Owner of this object (database ID).

.PARAMETER Comments
    Detailed comments (Markdown is supported).

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.EXAMPLE
    New-NBDCIMCoolingFeed -Cooling_Source 3 -Name 'CF-01' -Rack 12 -Cooling_Capacity 25 -Max_Flow 40 -Max_Flow_Unit lpm

    Creates a 25 kW cooling feed from cooling source ID 3 to rack ID 12 with a 40 L/min maximum flow.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.7.1.0
    Requires NetBox 4.7.0 or later.

#>
function New-NBDCIMCoolingFeed {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [uint64]$Cooling_Source,

        [uint64]$Rack,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [ValidateSet('offline', 'active', 'planned', 'failed')]
        [string]$Status,

        [decimal]$Cooling_Capacity,

        [decimal]$Max_Flow,

        [ValidateSet('lpm', 'm3ph', 'gpm')]
        [string]$Max_Flow_Unit,

        [string]$Description,

        [uint64]$Tenant,

        [uint64]$Owner,

        [string]$Comments,

        [object[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )
    process {
        Write-Verbose "Creating DCIM Cooling Feed"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cooling-feeds'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create cooling feed')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
