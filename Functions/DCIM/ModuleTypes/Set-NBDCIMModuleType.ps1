<#
.SYNOPSIS
    Updates an existing DCIM ModuleType in Netbox DCIM module.

.DESCRIPTION
    Updates an existing DCIM ModuleType in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to update.

.PARAMETER Manufacturer
    Manufacturer assigned to this object (database ID).

.PARAMETER Model
    Model name.

.PARAMETER Part_Number
    Discrete part number (optional)

.PARAMETER Weight
    Numeric weight value.

.PARAMETER Weight_Unit
    Unit of measurement for the weight.

.PARAMETER Description
    Brief description.

.PARAMETER Comments
    Detailed comments (Markdown is supported).

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.PARAMETER Module_Bay_Types
    One or more module bay type database IDs this module type can be installed
    into (NetBox 4.7+). Pass an empty array (@()) to clear the assignment.
    Ignored with a warning on older versions.

.EXAMPLE
    Set-NBDCIMModuleType

    Updates an existing DCIM ModuleType object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBDCIMModuleType {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Manufacturer,
        [string]$Model,
        [string]$Part_Number,
        [uint16]$Weight,
        [string]$Weight_Unit,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [uint64[]]$Module_Bay_Types,
        [switch]$Raw
    )
    process {
        Write-Verbose "Updating DCIM Module Type"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','module-types',$Id))
        # Module_Bay_Types only exists on NetBox 4.7+; drop it (with a warning) on older versions
        $skipParams = @('Id', 'Raw')
        if (Test-NBMinimumVersion -ParameterName 'Module_Bay_Types' -MinimumVersion '4.7.0' -BoundParameters $PSBoundParameters -FeatureName 'Module bay types') {
            $skipParams += 'Module_Bay_Types'
        }
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName $skipParams
        if ($PSCmdlet.ShouldProcess($Id, 'Update module type')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
