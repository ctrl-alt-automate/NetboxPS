<#
.SYNOPSIS
    Creates a new Module Bay Type in Netbox DCIM module.

.DESCRIPTION
    Creates a new Module Bay Type in Netbox DCIM module (NetBox 4.7+).
    A module bay type describes which kinds of modules a module bay accepts.
    Assign it to module bays, module bay templates and module types via their
    -Module_Bay_Types parameter.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Name
    Name of the module bay type.

.PARAMETER Slug
    URL-friendly unique identifier (slug). Derived from -Name when omitted
    (whitespace replaced by '-', lowercased).

.PARAMETER Manufacturer
    Manufacturer assigned to this object (database ID).

.PARAMETER Color
    Color as a 6-digit hex code (RRGGBB), e.g. 'ff0000'.

.PARAMETER Description
    Brief description.

.PARAMETER Owner
    Owner assigned to this object (database ID).

.PARAMETER Comments
    Detailed comments (Markdown is supported).

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.EXAMPLE
    New-NBDCIMModuleBayType -Name 'SFP Cage' -Color '00ff00'

    Creates a module bay type named 'SFP Cage' with slug 'sfp-cage'.

.EXAMPLE
    New-NBDCIMModuleBayType -Name 'Line Card Slot' -Slug 'lc-slot' -Manufacturer 3

    Creates a manufacturer-specific module bay type with an explicit slug.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.7.1.0
    Requires NetBox 4.7.0 or later.
#>
function New-NBDCIMModuleBayType {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Slug,
        [uint64]$Manufacturer,
        [ValidatePattern('^[0-9a-fA-F]{6}$')]
        [string]$Color,
        [string]$Description,
        [uint64]$Owner,
        [string]$Comments,
        [object[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating DCIM Module Bay Type"
        # Auto-generate slug from name if not provided (NetBox REST does not auto-slug)
        if (-not $PSBoundParameters.ContainsKey('Slug')) {
            $PSBoundParameters['Slug'] = ($Name -replace '\s+', '-').ToLower()
        }
        # NetBox validates color against ^[0-9a-f]{6}$ (lowercase only)
        if ($PSBoundParameters.ContainsKey('Color')) {
            $PSBoundParameters['Color'] = $Color.ToLower()
        }
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'module-bay-types'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create module bay type')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
