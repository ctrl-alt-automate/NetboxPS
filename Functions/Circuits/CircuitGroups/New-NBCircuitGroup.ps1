<#
.SYNOPSIS
    Creates a new circuit group in Netbox.

.DESCRIPTION
    Creates a new circuit group in Netbox.

.PARAMETER Name
    Name of the circuit group.

.PARAMETER Slug
    URL-friendly slug.

.PARAMETER Description
    Description.

.PARAMETER Tenant
    Tenant ID.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBCircuitGroup -Name "WAN Links" -Slug "wan-links"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBCircuitGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [string]$Slug,

        [string]$Description,

        [uint64]$Tenant,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Circuit Group"
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit-groups'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Circuit Group')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
