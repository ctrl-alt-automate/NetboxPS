function New-NBIPAMASNRange {
<#
    .SYNOPSIS
        Create a new ASN range in Netbox

    .DESCRIPTION
        Creates a new ASN range object in Netbox.

    .PARAMETER Name
        The name of the ASN range (required)

    .PARAMETER Slug
        The URL-friendly slug (required)

    .PARAMETER RIR
        The RIR (Regional Internet Registry) ID (required)

    .PARAMETER Start
        The starting ASN number (required)

    .PARAMETER End
        The ending ASN number (required)

    .PARAMETER Tenant
        The tenant ID

    .PARAMETER Description
        A description of the ASN range

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .PARAMETER Tags
        One or more tags to assign to this object (tag names or IDs).

    .EXAMPLE
        New-NBIPAMASNRange -Name "Private" -Slug "private" -RIR 1 -Start 64512 -End 65534

        Creates a private ASN range
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

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Slug,

        [Parameter(Mandatory = $true)]
        [uint64]$RIR,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 4294967295)]
        [uint64]$Start,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 4294967295)]
        [uint64]$End,

        [uint64]$Tenant,

        [string]$Description,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating IPAM ASN Range"
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'asn-ranges'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create new ASN range')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
