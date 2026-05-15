<#
.SYNOPSIS
    Creates a new rack group in Netbox DCIM.

.DESCRIPTION
    Creates a new RackGroup (NetBox 4.6+). A rack group is a flat,
    location-independent axis for organising racks (e.g. by row or aisle).

.PARAMETER Name
    The name of the rack group.

.PARAMETER Slug
    URL-friendly unique identifier. Auto-generated from name if omitted.

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
    New-NBDCIMRackGroup -Name "Row A"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.6.0.1

#>
function New-NBDCIMRackGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
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
        Write-Verbose "Creating DCIM Rack Group"
        if (-not $PSBoundParameters.ContainsKey('Slug')) {
            $PSBoundParameters['Slug'] = ($Name -replace '\s+', '-').ToLower()
        }

        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'rack-groups'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create rack group')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
