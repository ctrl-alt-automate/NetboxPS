<#
.SYNOPSIS
    Updates an existing Module Bay Type in Netbox DCIM module.

.DESCRIPTION
    Updates an existing Module Bay Type in Netbox DCIM module (NetBox 4.7+).
    Supports pipeline input for Id parameter.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to update.

.PARAMETER Name
    Name of the module bay type.

.PARAMETER Slug
    URL-friendly unique identifier (slug).

.PARAMETER Manufacturer
    Manufacturer assigned to this object (database ID). Pass $null to clear.

.PARAMETER Color
    Color as a 6-digit hex code (RRGGBB), e.g. 'ff0000'. Pass '' to clear.

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
    Set-NBDCIMModuleBayType -Id 4 -Color 'ff0000' -Description 'Hot-swappable'

    Updates the color and description of module bay type 4.

.EXAMPLE
    Set-NBDCIMModuleBayType -Id 4 -Manufacturer $null

    Clears the manufacturer assignment of module bay type 4.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.7.1.0
    Requires NetBox 4.7.0 or later.
#>
function Set-NBDCIMModuleBayType {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Name,
        [string]$Slug,
        [Nullable[uint64]]$Manufacturer,
        [AllowEmptyString()]
        [ValidatePattern('^([0-9a-fA-F]{6})?$')]
        [string]$Color,
        [string]$Description,
        [uint64]$Owner,
        [string]$Comments,
        [object[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Updating DCIM Module Bay Type"
        # NetBox validates color against ^[0-9a-f]{6}$ (lowercase only); '' clears it
        if ($PSBoundParameters.ContainsKey('Color')) {
            $PSBoundParameters['Color'] = $Color.ToLower()
        }
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'module-bay-types', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update module bay type')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
