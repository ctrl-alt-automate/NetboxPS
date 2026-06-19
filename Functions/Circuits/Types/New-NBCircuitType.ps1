<#
.SYNOPSIS
    Creates a new circuit type in Netbox.

.DESCRIPTION
    Creates a new circuit type in Netbox.

.PARAMETER Name
    Name of the circuit type.

.PARAMETER Slug
    URL-friendly slug. Auto-generated from name if not provided.

.PARAMETER Color
    Color code (6 hex characters).

.PARAMETER Description
    Description of the circuit type.

.PARAMETER Owner
    ID of the owner (tenant).

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBCircuitType -Name "MPLS" -Slug "mpls"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBCircuitType {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [string]$Slug,

        [ValidatePattern('^[0-9a-fA-F]{6}$')]
        [string]$Color,

        [string]$Description,

        [uint64]$Owner,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Circuit Type"
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit-types'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Circuit Type')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
