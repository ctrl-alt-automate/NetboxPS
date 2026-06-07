<#
.SYNOPSIS
    Creates a new circuit termination in Netbox.

.DESCRIPTION
    Creates a new circuit termination in Netbox.

.PARAMETER Circuit
    Circuit ID.

.PARAMETER Term_Side
    Termination side (A or Z).

.PARAMETER Site
    Site ID.

.PARAMETER Provider_Network
    Provider network ID.

.PARAMETER Port_Speed
    Port speed in Kbps.

.PARAMETER Upstream_Speed
    Upstream speed in Kbps.

.PARAMETER Xconnect_Id
    Cross-connect ID.

.PARAMETER Pp_Info
    Patch panel info.

.PARAMETER Description
    Description.

.PARAMETER Mark_Connected
    Mark as connected.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBCircuitTermination -Circuit 1 -Term_Side "A" -Site 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBCircuitTermination {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [uint64]$Circuit,

        [Parameter(Mandatory = $true)]
        [ValidateSet('A', 'Z')]
        [string]$Term_Side,

        [uint64]$Site,

        [uint64]$Provider_Network,

        [uint64]$Port_Speed,

        [uint64]$Upstream_Speed,

        [string]$Xconnect_Id,

        [string]$Pp_Info,

        [string]$Description,

        [bool]$Mark_Connected,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Circuit Termination"
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit-terminations'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess("Circuit $Circuit Side $Term_Side", 'Create Circuit Termination')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
