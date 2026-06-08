<#
.SYNOPSIS
    Creates a new DCIM PowerOutletTemplate in Netbox DCIM module.

.DESCRIPTION
    Creates a new DCIM PowerOutletTemplate in Netbox DCIM module.
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

.PARAMETER Power_Port
    Power port assigned to this object (database ID).

.PARAMETER Feed_Leg
    Feed Leg.

.PARAMETER Description
    Brief description.

.PARAMETER Color
    Color as a 6-digit hex code (RRGGBB).

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBDCIMPowerOutletTemplate

    Creates a new DCIM PowerOutletTemplate object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBDCIMPowerOutletTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [uint64]$Device_Type,
        [uint64]$Module_Type,
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Label,
        [string]$Type,
        [uint64]$Power_Port,
        [string]$Feed_Leg,
        [string]$Description,
        [string]$Color,

        [object[]]$Tags,

        [switch]$Raw
    )
    process {
        Write-Verbose "Creating DCIM Power Outlet Template"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','power-outlet-templates'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create power outlet template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
