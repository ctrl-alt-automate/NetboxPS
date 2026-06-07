function Set-NBIPAMVRF {
<#
    .SYNOPSIS
        Update a VRF in Netbox

    .DESCRIPTION
        Updates an existing VRF (Virtual Routing and Forwarding) object in Netbox.

    .PARAMETER Id
        The ID of the VRF to update (required)

    .PARAMETER Name
        The name of the VRF

    .PARAMETER RD
        The route distinguisher (RFC 4364 format)

    .PARAMETER Tenant
        The tenant ID that owns this VRF

    .PARAMETER Enforce_Unique
        Prevent duplicate prefixes/IP addresses within this VRF

    .PARAMETER Description
        A description of the VRF

    .PARAMETER Comments
        Additional comments

    .PARAMETER Import_Targets
        Array of route target IDs for import

    .PARAMETER Export_Targets
        Array of route target IDs for export

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .PARAMETER Tags
        One or more tags to assign to this object (tag names or IDs).

    .EXAMPLE
        Set-NBIPAMVRF -Id 1 -Name "Production-VRF"

        Updates the name of VRF 1

    .EXAMPLE
        Set-NBIPAMVRF -Id 1 -Enforce_Unique $true

        Enables unique enforcement for VRF 1
.NOTES
    AddedInVersion: v4.4.10.0

#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$RD,

        [uint64]$Tenant,

        [bool]$Enforce_Unique,

        [string]$Description,

        [string]$Comments,

        [uint64[]]$Import_Targets,

        [uint64[]]$Export_Targets,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating IPAM VRF"
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'vrfs', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update VRF')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
