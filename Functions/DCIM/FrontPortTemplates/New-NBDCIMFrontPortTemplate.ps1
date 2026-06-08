<#
.SYNOPSIS
    Creates a new DCIM FrontPortTemplate in Netbox DCIM module.

.DESCRIPTION
    Creates a new DCIM FrontPortTemplate in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Device_Type
    Device type assigned to this object (database ID).

.PARAMETER Module_Type
    Module type assigned to this object (database ID).

.PARAMETER Name
    Name of the object.

.PARAMETER Label
    Physical label.

.PARAMETER Type
    Type of the object.

.PARAMETER Color
    Color as a 6-digit hex code (RRGGBB).

.PARAMETER Rear_Port
    Rear port assigned to this object (database ID).

.PARAMETER Rear_Port_Position
    Rear Port Position.

.PARAMETER Description
    Brief description.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBDCIMFrontPortTemplate

    Creates a new DCIM FrontPortTemplate object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBDCIMFrontPortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [uint64]$Device_Type,
        [uint64]$Module_Type,
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Label,
        [Parameter(Mandatory = $true)][string]$Type,
        [string]$Color,
        [Parameter(Mandatory = $true)][uint64]$Rear_Port,
        [uint16]$Rear_Port_Position,
        [string]$Description,

        [object[]]$Tags,

        [switch]$Raw
    )
    process {
        Write-Verbose "Creating DCIM Front Port Template"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','front-port-templates'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create front port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
