<#
.SYNOPSIS
    Updates an existing circuit termination in Netbox.

.DESCRIPTION
    Updates an existing circuit termination in Netbox.

.PARAMETER Id
    The ID of the circuit termination to update.

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
    Set-NBCircuitTermination -Id 1 -Port_Speed 10000

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBCircuitTermination {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [uint64]$Circuit,

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
        Write-Verbose "Updating Circuit Termination"
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit-terminations', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Circuit Termination')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
