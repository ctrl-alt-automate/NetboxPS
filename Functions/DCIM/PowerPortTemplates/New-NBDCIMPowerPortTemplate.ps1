<#
.SYNOPSIS
    Creates a new DCIM PowerPortTemplate in Netbox DCIM module.

.DESCRIPTION
    Creates a new DCIM PowerPortTemplate in Netbox DCIM module.
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

.PARAMETER Maximum_Draw
    Maximum power draw (watts)

.PARAMETER Allocated_Draw
    Allocated power draw (watts)

.PARAMETER Description
    Brief description.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBDCIMPowerPortTemplate

    Creates a new DCIM PowerPortTemplate object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBDCIMPowerPortTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [uint64]$Device_Type,
        [uint64]$Module_Type,
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Label,
        [string]$Type,
        [uint16]$Maximum_Draw,
        [uint16]$Allocated_Draw,
        [string]$Description,

        [object[]]$Tags,

        [switch]$Raw
    )
    process {
        Write-Verbose "Creating DCIM Power Port Template"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','power-port-templates'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create power port template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
