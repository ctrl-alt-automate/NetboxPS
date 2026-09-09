<#
.SYNOPSIS
    Creates a new DCIM ModuleType in Netbox DCIM module.

.DESCRIPTION
    Creates a new DCIM ModuleType in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

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

.PARAMETER Cooling_Method
    Cooling method. One of: 'air', 'liquid', 'hybrid', 'immersion'.
    Requires NetBox 4.7.0 or later; ignored with a warning on older servers.

.PARAMETER End_Of_Life
    Date after which this module type is no longer supported by the manufacturer.
    Sent as yyyy-MM-dd. Requires NetBox 4.7.0 or later; ignored with a
    warning on older servers.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.EXAMPLE
    New-NBDCIMModuleType

    Creates a new DCIM ModuleType object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBDCIMModuleType {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Manufacturer,
        [Parameter(Mandatory = $true)][string]$Model,
        [string]$Part_Number,
        [uint16]$Weight,
        [string]$Weight_Unit,
        [string]$Description,
        [string]$Comments,
        [ValidateSet('air', 'liquid', 'hybrid', 'immersion', IgnoreCase = $true)]
        [string]$Cooling_Method,
        [datetime]$End_Of_Life,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating DCIM Module Type"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','module-types'))

        # NetBox DateField wants yyyy-MM-dd, not the ISO datetime ConvertTo-Json emits.
        if ($PSBoundParameters.ContainsKey('End_Of_Life') -and $null -ne $PSBoundParameters['End_Of_Life']) {
            $PSBoundParameters['End_Of_Life'] = ([datetime]$PSBoundParameters['End_Of_Life']).ToString('yyyy-MM-dd')
        }

        # NetBox 4.7+ only fields: drop them with a warning on older servers.
        $skipParams = @('Raw')
        foreach ($p in @('Cooling_Method', 'End_Of_Life')) {
            if (Test-NBMinimumVersion -ParameterName $p -MinimumVersion '4.7.0' -BoundParameters $PSBoundParameters -FeatureName "The -$p parameter") {
                $skipParams += $p
            }
        }

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName $skipParams
        if ($PSCmdlet.ShouldProcess($Model, 'Create module type')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
