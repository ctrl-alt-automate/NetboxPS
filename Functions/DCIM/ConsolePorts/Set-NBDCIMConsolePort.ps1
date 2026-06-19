<#
.SYNOPSIS
    Updates an existing DCIM ConsolePort in Netbox DCIM module.

.DESCRIPTION
    Updates an existing DCIM ConsolePort in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to update.

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
    Set-NBDCIMConsolePort

    Updates an existing DCIM ConsolePort object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBDCIMConsolePort {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device,
        [string]$Name,
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
        Write-Verbose "Updating DCIM Console Port"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','console-ports',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update console port')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
