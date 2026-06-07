<#
.SYNOPSIS
    Updates an existing DCIM PowerPanel in Netbox DCIM module.

.DESCRIPTION
    Updates an existing DCIM PowerPanel in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to update.

.PARAMETER Site
    Site assigned to this object (database ID).

.PARAMETER Name
    Name of the object.

.PARAMETER Location
    Location assigned to this object (database ID).

.PARAMETER Description
    Brief description.

.PARAMETER Comments
    Detailed comments (Markdown is supported).

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.EXAMPLE
    Set-NBDCIMPowerPanel

    Updates an existing DCIM PowerPanel object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBDCIMPowerPanel {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Site,
        [string]$Name,
        [uint64]$Location,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Updating DCIM Power Panel"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','power-panels',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update power panel')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
