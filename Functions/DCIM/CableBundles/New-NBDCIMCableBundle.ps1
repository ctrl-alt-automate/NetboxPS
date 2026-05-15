<#
.SYNOPSIS
    Creates a new cable bundle in Netbox DCIM.

.DESCRIPTION
    Creates a new CableBundle (NetBox 4.6+). Groups individual cables
    managed as one physical run. Not for modeling fiber strands within
    a single cable.

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
    New-NBDCIMCableBundle -Name 'PP1-PP2 trunk' -Description '48x CAT6'

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.6.0.1

#>
function New-NBDCIMCableBundle {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [string]$Description,

        [string]$Comments,

        [uint64]$Owner,

        [object[]]$Tags,

        [hashtable]$Custom_Fields,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating DCIM Cable Bundle"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cable-bundles'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create cable bundle')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
