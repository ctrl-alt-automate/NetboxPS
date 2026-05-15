<#
.SYNOPSIS
    Updates a rack group in Netbox DCIM.

.DESCRIPTION
    Updates an existing RackGroup (NetBox 4.6+).

.PARAMETER Id
    The ID of the rack group to update.

.PARAMETER Name
    The name of the rack group.

.PARAMETER Slug
    URL-friendly unique identifier.

.PARAMETER Description
    A description of the rack group.

.PARAMETER Comments
    Additional comments.

.PARAMETER Owner
    The owner ID for object ownership.

.PARAMETER Tags
    Tags to assign to this rack group.

.PARAMETER Custom_Fields
    A hashtable of custom field values.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMRackGroup -Id 1 -Description "Updated"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.6.0.1

#>
function Set-NBDCIMRackGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Slug,

        [string]$Description,

        [string]$Comments,

        [uint64]$Owner,

        [object[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating DCIM Rack Group"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'rack-groups', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update rack group')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
