<#
.SYNOPSIS
    Updates an existing DCIM PowerFeed in Netbox DCIM module.

.DESCRIPTION
    Updates an existing DCIM PowerFeed in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to update.

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
    Set-NBDCIMPowerFeed

    Updates an existing DCIM PowerFeed object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBDCIMPowerFeed {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Power_Panel,
        [string]$Name,
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
        Write-Verbose "Updating DCIM Power Feed"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','power-feeds',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update power feed')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
