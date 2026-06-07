<#
.SYNOPSIS
    Updates an existing DCIM Module in Netbox DCIM module.

.DESCRIPTION
    Updates an existing DCIM Module in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to update.

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

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.EXAMPLE
    Set-NBDCIMModule

    Updates an existing DCIM Module object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBDCIMModule {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device,
        [uint64]$Module_Bay,
        [uint64]$Module_Type,
        [string]$Status,
        [string]$Serial,
        [string]$Asset_Tag,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Updating DCIM Module"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','modules',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update module')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
