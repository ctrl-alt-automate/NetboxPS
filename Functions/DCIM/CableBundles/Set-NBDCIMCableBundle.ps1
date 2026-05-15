<#
.SYNOPSIS
    Updates a cable bundle in Netbox DCIM.

.DESCRIPTION
    Updates an existing CableBundle (NetBox 4.6+).

.PARAMETER Id
    The ID of the cable bundle to update.

.PARAMETER Name
    The name of the cable bundle.

.PARAMETER Description
    A description of the cable bundle.

.PARAMETER Comments
    Additional comments.

.PARAMETER Owner
    The owner ID for object ownership.

.PARAMETER Tags
    Tags to assign to this cable bundle.

.PARAMETER Custom_Fields
    A hashtable of custom field values.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMCableBundle -Id 1 -Description 'Updated'

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.6.0.1

#>
function Set-NBDCIMCableBundle {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Description,

        [string]$Comments,

        [uint64]$Owner,

        [object[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating DCIM Cable Bundle"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cable-bundles', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update cable bundle')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
