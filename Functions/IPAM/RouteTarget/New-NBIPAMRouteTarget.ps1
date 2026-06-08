function New-NBIPAMRouteTarget {
<#
    .SYNOPSIS
        Create a new route target in Netbox

    .DESCRIPTION
        Creates a new route target object in Netbox.
        Route targets are used for VRF import/export policies (RFC 4360).

    .PARAMETER Name
        The route target value (required, RFC 4360 format, e.g., "65001:100")

    .PARAMETER Tenant
        The tenant ID that owns this route target

    .PARAMETER Description
        A description of the route target

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .PARAMETER Tags
        One or more tags to assign to this object (tag names or IDs).

    .EXAMPLE
        New-NBIPAMRouteTarget -Name "65001:100"

        Creates a new route target with value "65001:100"

    .EXAMPLE
        New-NBIPAMRouteTarget -Name "65001:200" -Description "Customer A import"

        Creates a new route target with description
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

        [uint64]$Tenant,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating IPAM Route Target"
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'route-targets'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create new route target')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
