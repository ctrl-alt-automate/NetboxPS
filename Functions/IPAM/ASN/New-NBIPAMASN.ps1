function New-NBIPAMASN {
<#
    .SYNOPSIS
        Create a new ASN in Netbox

    .DESCRIPTION
        Creates a new ASN (Autonomous System Number) object in Netbox.

    .PARAMETER ASN
        The ASN number (required, 1-4294967295)

    .PARAMETER RIR
        The RIR (Regional Internet Registry) ID

    .PARAMETER Tenant
        The tenant ID

    .PARAMETER Role
        The role ID assigned to this ASN (NetBox 4.6+)

    .PARAMETER Description
        A description of the ASN

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .PARAMETER Tags
        One or more tags to assign to this object (tag names or IDs).

    .EXAMPLE
        New-NBIPAMASN -ASN 65001

        Creates ASN 65001

    .EXAMPLE
        New-NBIPAMASN -ASN 65001 -RIR 1 -Description "Primary ASN"

        Creates ASN 65001 with RIR and description
.NOTES
    AddedInVersion: v4.4.10.0

#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 4294967295)]
        [uint64]$ASN,

        [uint64]$RIR,

        [uint64]$Tenant,

        [uint64]$Role,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating IPAM ASN"
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'asns'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($ASN, 'Create new ASN')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
