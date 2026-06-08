<#
.SYNOPSIS
    Creates a new DCIM PowerFeed in Netbox DCIM module.

.DESCRIPTION
    Creates a new DCIM PowerFeed in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Power_Panel
    Power Panel.

.PARAMETER Name
    Name of the object.

.PARAMETER Rack
    Rack assigned to this object (database ID).

.PARAMETER Status
    Operational status.

.PARAMETER Type
    Type of the object.

.PARAMETER Supply
    Supply.

.PARAMETER Phase
    Phase.

.PARAMETER Voltage
    Voltage.

.PARAMETER Amperage
    Amperage.

.PARAMETER Max_Utilization
    Maximum permissible draw (percentage)

.PARAMETER Mark_Connected
    Treat the endpoint as connected even without a cable.

.PARAMETER Description
    Brief description.

.PARAMETER Comments
    Detailed comments (Markdown is supported).

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.EXAMPLE
    New-NBDCIMPowerFeed

    Creates a new DCIM PowerFeed object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBDCIMPowerFeed {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Power_Panel,
        [Parameter(Mandatory = $true)][string]$Name,
        [uint64]$Rack,
        [string]$Status,
        [string]$Type,
        [string]$Supply,
        [string]$Phase,
        [uint16]$Voltage,
        [uint16]$Amperage,
        [uint16]$Max_Utilization,
        [bool]$Mark_Connected,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating DCIM Power Feed"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','power-feeds'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create power feed')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
