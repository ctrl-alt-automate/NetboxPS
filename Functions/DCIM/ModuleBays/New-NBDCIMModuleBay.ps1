<#
.SYNOPSIS
    Creates a new DCIM ModuleBay in Netbox DCIM module.

.DESCRIPTION
    Creates a new DCIM ModuleBay in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Enabled
    Whether the module bay is enabled (NetBox 4.6+). Defaults to true server-side.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Device
    Device assigned to this object (database ID).

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

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.PARAMETER Module_Bay_Types
    One or more module bay type database IDs describing which kinds of modules
    this bay accepts (NetBox 4.7+). Ignored with a warning on older versions.

.EXAMPLE
    New-NBDCIMModuleBay

    Creates a new DCIM ModuleBay object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBDCIMModuleBay {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Device,
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Label,
        [string]$Position,
        [bool]$Enabled,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [uint64[]]$Module_Bay_Types,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating DCIM Module Bay"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','module-bays'))
        # Module_Bay_Types only exists on NetBox 4.7+; drop it (with a warning) on older versions
        $skipParams = @('Raw')
        if (Test-NBMinimumVersion -ParameterName 'Module_Bay_Types' -MinimumVersion '4.7.0' -BoundParameters $PSBoundParameters -FeatureName 'Module bay types') {
            $skipParams += 'Module_Bay_Types'
        }
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName $skipParams
        if ($PSCmdlet.ShouldProcess($Name, 'Create module bay')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
