<#
.SYNOPSIS
    Creates a new DCIM Module in Netbox DCIM module.

.DESCRIPTION
    Creates a new DCIM Module in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Device
    Device assigned to this object (database ID).

.PARAMETER Module_Bay
    Module Bay.

.PARAMETER Module_Type
    Module type assigned to this object (database ID).

.PARAMETER Status
    Operational status.

.PARAMETER Serial
    Serial number assigned by the manufacturer.

.PARAMETER Asset_Tag
    Unique asset tag.

.PARAMETER Description
    Brief description.

.PARAMETER Comments
    Detailed comments (Markdown is supported).

.PARAMETER Replicate_Components
    Automatically populate components associated with this module type (default: true)

.PARAMETER Adopt_Components
    Adopt already existing components

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.EXAMPLE
    New-NBDCIMModule

    Creates a new DCIM Module object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBDCIMModule {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Device,
        [Parameter(Mandatory = $true)][uint64]$Module_Bay,
        [Parameter(Mandatory = $true)][uint64]$Module_Type,
        [string]$Status,
        [string]$Serial,
        [string]$Asset_Tag,
        [string]$Description,
        [string]$Comments,
        [bool]$Replicate_Components,
        [bool]$Adopt_Components,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating DCIM Module"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','modules'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess("Device $Device", 'Create module')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
