<#
.SYNOPSIS
    Creates a new DCIM ModuleBayTemplate in Netbox DCIM module.

.DESCRIPTION
    Creates a new DCIM ModuleBayTemplate in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Device_Type
    Device type assigned to this object (database ID).

.PARAMETER Name
    Name of the object.

.PARAMETER Label
    Physical label.

.PARAMETER Position
    Position (e.g. rack unit or bay identifier).

.PARAMETER Description
    Brief description.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBDCIMModuleBayTemplate

    Creates a new DCIM ModuleBayTemplate object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBDCIMModuleBayTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Device_Type,
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Label,
        [string]$Position,
        [string]$Description,

        [object[]]$Tags,

        [switch]$Raw
    )
    process {
        Write-Verbose "Creating DCIM Module Bay Template"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','module-bay-templates'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create module bay template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
