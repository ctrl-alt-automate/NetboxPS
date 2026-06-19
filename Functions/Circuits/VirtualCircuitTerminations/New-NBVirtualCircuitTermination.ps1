<#
.SYNOPSIS
    Creates a new virtual circuit termination in Netbox.

.DESCRIPTION
    Creates a new virtual circuit termination in Netbox.

.PARAMETER Virtual_Circuit
    Virtual circuit ID.

.PARAMETER Interface
    Interface ID.

.PARAMETER Role
    Role (peer, hub, spoke).

.PARAMETER Description
    Description.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBVirtualCircuitTermination -Virtual_Circuit 1 -Interface 1 -Role "peer"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBVirtualCircuitTermination {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [uint64]$Virtual_Circuit,

        [Parameter(Mandatory = $true)]
        [uint64]$Interface,

        [ValidateSet('peer', 'hub', 'spoke')]
        [string]$Role,

        [string]$Description,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Virtual Circuit Termination"
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'virtual-circuit-terminations'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess("VC $Virtual_Circuit Interface $Interface", 'Create Virtual Circuit Termination')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
