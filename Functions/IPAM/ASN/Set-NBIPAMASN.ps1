function Set-NBIPAMASN {
<#
    .SYNOPSIS
        Update an ASN in Netbox

    .DESCRIPTION
        Updates an existing ASN (Autonomous System Number) object in Netbox.

    .PARAMETER Id
        The ID of the ASN to update (required)

    .PARAMETER ASN
        The ASN number

    .PARAMETER RIR
        The RIR (Regional Internet Registry) ID

    .PARAMETER Tenant
        The tenant ID

    .PARAMETER Role
        The role ID assigned to this ASN (NetBox 4.6+). Pass $null to clear.

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
        Set-NBIPAMASN -Id 1 -Description "Updated description"

        Updates the description of ASN 1
.NOTES
    AddedInVersion: v4.4.10.0

#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [ValidateRange(1, 4294967295)]
        [uint64]$ASN,

        [uint64]$RIR,

        [uint64]$Tenant,

        [Nullable[uint64]]$Role,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating IPAM ASN"
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'asns', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update ASN')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
