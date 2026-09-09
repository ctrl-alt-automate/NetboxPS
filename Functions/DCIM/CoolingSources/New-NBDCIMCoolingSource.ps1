<#
.SYNOPSIS
    Creates a new Cooling Source in Netbox DCIM module.

.DESCRIPTION
    Creates a new Cooling Source in Netbox DCIM module (NetBox 4.7+).
    A cooling source is a facility-level piece of cooling equipment
    (chiller, cooling tower, dry cooler, CRAC or CRAH) installed at a site.
    Cooling feeds are then provisioned from a cooling source to racks.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Site
    Site this cooling source is installed at (database ID). Required.

.PARAMETER Location
    Location within the site (database ID).

.PARAMETER Name
    Name of the cooling source. Required.

.PARAMETER Type
    Type of cooling equipment: chiller, cooling-tower, dry-cooler, crac or crah. Required.

.PARAMETER Status
    Operational status: offline, active, planned or failed. Defaults to active server-side.

.PARAMETER Fluid_Type
    Cooling fluid type: water, water-glycol, dielectric or refrigerant.

.PARAMETER Cooling_Capacity
    Total rated cooling capacity in kW.

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
    New-NBDCIMCoolingSource -Site 1 -Name 'CH-01' -Type chiller -Fluid_Type water -Cooling_Capacity 500

    Creates a 500 kW water chiller at site ID 1.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.7.1.0
    Requires NetBox 4.7.0 or later.

#>
function New-NBDCIMCoolingSource {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [uint64]$Site,

        [uint64]$Location,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('chiller', 'cooling-tower', 'dry-cooler', 'crac', 'crah')]
        [string]$Type,

        [ValidateSet('offline', 'active', 'planned', 'failed')]
        [string]$Status,

        [ValidateSet('water', 'water-glycol', 'dielectric', 'refrigerant')]
        [string]$Fluid_Type,

        [decimal]$Cooling_Capacity,

        [string]$Description,

        [uint64]$Owner,

        [string]$Comments,

        [object[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )
    process {
        Write-Verbose "Creating DCIM Cooling Source"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cooling-sources'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create cooling source')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
