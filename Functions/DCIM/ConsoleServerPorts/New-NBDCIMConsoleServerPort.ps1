<#
.SYNOPSIS
    Creates a new DCIM ConsoleServerPort in Netbox DCIM module.

.DESCRIPTION
    Creates a new DCIM ConsoleServerPort in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Device
    Device assigned to this object (database ID).

.PARAMETER Name
    Name of the object.

.PARAMETER Module
    Module assigned to this object (database ID).

.PARAMETER Label
    Physical label.

.PARAMETER Type
    Type of the object.

.PARAMETER Speed
    Speed.

.PARAMETER Mark_Connected
    Treat the endpoint as connected even without a cable.

.PARAMETER Description
    Brief description.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.EXAMPLE
    New-NBDCIMConsoleServerPort

    Creates a new DCIM ConsoleServerPort object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBDCIMConsoleServerPort {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Device,
        [Parameter(Mandatory = $true)][string]$Name,
        [uint64]$Module,
        [string]$Label,
        [string]$Type,
        [uint16]$Speed,
        [bool]$Mark_Connected,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating DCIM Console Server Port"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','console-server-ports'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create console server port')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
