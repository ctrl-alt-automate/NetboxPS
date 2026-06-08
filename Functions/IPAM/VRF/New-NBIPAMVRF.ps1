function New-NBIPAMVRF {
<#
    .SYNOPSIS
        Create a new VRF in Netbox

    .DESCRIPTION
        Creates a new VRF (Virtual Routing and Forwarding) object in Netbox.

    .PARAMETER Name
        The name of the VRF (required)

    .PARAMETER RD
        The route distinguisher (RFC 4364 format, e.g., "65001:100")

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
        New-NBIPAMVRF -Name "Production"

        Creates a new VRF named "Production"

    .EXAMPLE
        New-NBIPAMVRF -Name "Customer-A" -RD "65001:100" -Enforce_Unique $true

        Creates a new VRF with route distinguisher and unique enforcement
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
        Write-Verbose "Creating IPAM VRF"
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'vrfs'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create new VRF')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
