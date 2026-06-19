function New-NBDCIMRegion {
<#
    .SYNOPSIS
        Create a new region in Netbox

    .DESCRIPTION
        Creates a new region object in Netbox.
        Regions are used to organize sites geographically (e.g., countries, states, cities).

    .PARAMETER Name
        The name of the region (required)

    .PARAMETER Slug
        The URL-friendly slug (required)

    .PARAMETER Parent
        The parent region ID for nested regions

    .PARAMETER Description
        A description of the region

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .PARAMETER Tags
        One or more tags to assign to this object (tag names or IDs).

    .EXAMPLE
        New-NBDCIMRegion -Name "Europe" -Slug "europe"

        Creates a new region named "Europe"

    .EXAMPLE
        New-NBDCIMRegion -Name "Netherlands" -Slug "netherlands" -Parent 1

        Creates a new region as a child of region 1
.NOTES
    AddedInVersion: v4.4.10.0

#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Slug,

        [uint64]$Parent,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating DCIM Region"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'regions'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create new region')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
