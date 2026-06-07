<#
.SYNOPSIS
    Creates a new DCIM RackReservation in Netbox DCIM module.

.DESCRIPTION
    Creates a new DCIM RackReservation in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Rack
    Rack assigned to this object (database ID).

.PARAMETER Units
    Units.

.PARAMETER User
    User.

.PARAMETER Tenant
    Tenant assigned to this object (database ID).

.PARAMETER Description
    Brief description.

.PARAMETER Comments
    Detailed comments (Markdown is supported).

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.EXAMPLE
    New-NBDCIMRackReservation

    Creates a new DCIM RackReservation object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBDCIMRackReservation {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Rack,
        [Parameter(Mandatory = $true)][uint16[]]$Units,
        [Parameter(Mandatory = $true)][uint64]$User,
        [uint64]$Tenant,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating DCIM Rack Reservation"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','rack-reservations'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess("Rack $Rack", 'Create rack reservation')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
