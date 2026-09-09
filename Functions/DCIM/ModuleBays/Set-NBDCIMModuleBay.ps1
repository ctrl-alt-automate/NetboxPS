<#
.SYNOPSIS
    Updates an existing DCIM ModuleBay in Netbox DCIM module.

.DESCRIPTION
    Updates an existing DCIM ModuleBay in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Enabled
    Whether the module bay is enabled (NetBox 4.6+).

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to update.

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
    this bay accepts (NetBox 4.7+). Pass an empty array (@()) to clear the
    assignment. Ignored with a warning on older versions.

.EXAMPLE
    Set-NBDCIMModuleBay

    Updates an existing DCIM ModuleBay object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBDCIMModuleBay {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device,
        [string]$Name,
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
        Write-Verbose "Updating DCIM Module Bay"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','module-bays',$Id))
        # Module_Bay_Types only exists on NetBox 4.7+; drop it (with a warning) on older versions
        $skipParams = @('Id', 'Raw')
        if (Test-NBMinimumVersion -ParameterName 'Module_Bay_Types' -MinimumVersion '4.7.0' -BoundParameters $PSBoundParameters -FeatureName 'Module bay types') {
            $skipParams += 'Module_Bay_Types'
        }
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName $skipParams
        if ($PSCmdlet.ShouldProcess($Id, 'Update module bay')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
