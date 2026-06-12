function Set-NBDCIMManufacturer {
<#
    .SYNOPSIS
        Update a manufacturer in Netbox

    .DESCRIPTION
        Updates an existing manufacturer object in Netbox.

    .PARAMETER Id
        The ID of the manufacturer to update

    .PARAMETER Name
        The name of the manufacturer

    .PARAMETER Slug
        The URL-friendly slug

    .PARAMETER Description
        A description of the manufacturer

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Force
        Skip confirmation prompts

    .PARAMETER Tags
        One or more tags to assign to this object (tag names or IDs).

    .PARAMETER Raw
        Return the raw API response object instead of the .results collection.

    .EXAMPLE
        Set-NBDCIMManufacturer -Id 1 -Description "Updated description"

    .EXAMPLE
        Get-NBDCIMManufacturer -Name "Cisco" | Set-NBDCIMManufacturer -Description "Network equipment"
.NOTES
    AddedInVersion: v4.4.10.0

#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Slug,

        [string]$Description,

        [hashtable]$Custom_Fields,

        [switch]$Force,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating DCIM Manufacturer"
        foreach ($ManufacturerId in $Id) {

            if ($Force -or $PSCmdlet.ShouldProcess("ID $ManufacturerId", "Update manufacturer")) {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'manufacturers', $ManufacturerId))

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'Force'

                $URI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method PATCH -Raw:$Raw
            }
        }
    }
}
