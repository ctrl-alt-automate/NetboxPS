<#
.SYNOPSIS
    Updates an existing virtual circuit type in Netbox.

.DESCRIPTION
    Updates an existing virtual circuit type in Netbox.

.PARAMETER Id
    The ID of the virtual circuit type to update.

.PARAMETER Name
    Name of the virtual circuit type.

.PARAMETER Slug
    URL-friendly slug.

.PARAMETER Color
    Color code (6 hex characters).

.PARAMETER Description
    Description.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    Set-NBVirtualCircuitType -Id 1 -Description "Updated"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBVirtualCircuitType {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Slug,

        [ValidatePattern('^[0-9a-fA-F]{6}$')]
        [string]$Color,

        [string]$Description,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating Virtual Circuit Type"
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'virtual-circuit-types', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Virtual Circuit Type')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
