
function Get-NBIPAMAvailableIP {
    <#
    .SYNOPSIS
        A convenience method for returning available IP addresses within a prefix

    .DESCRIPTION
        By default, the number of IPs returned will be equivalent to PAGINATE_COUNT. An arbitrary limit
        (up to MAX_PAGE_SIZE, if set) may be passed, however results will not be paginated

    .PARAMETER Prefix_ID
        Database ID of the prefix to get available IPs from.

    .PARAMETER Limit
        Maximum number of available IPs to return.

    .PARAMETER Raw
        Return the raw API response.

    .EXAMPLE
        Get-NBIPAMAvailableIP -Prefix_ID (Get-NBIPAMPrefix -Prefix 192.0.2.0/24).id

        Get (Next) Available IP on the Prefix 192.0.2.0/24

    .EXAMPLE
        Get-NBIPAMAvailableIP -Prefix_ID 2 -NumberOfIPs 3

        Get 3 (Next) Available IP on the Prefix 192.0.2.0/24
.NOTES
    AddedInVersion: v1.0.4


#>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [Alias('Id')]
        [uint64]$Prefix_ID,

        [Alias('NumberOfIPs')]
        [uint16]$Limit,

        [switch]$Raw
    )

    process {
        Write-Verbose "Retrieving IPAM Available IP"
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'prefixes', $Prefix_ID, 'available-ips'))

        $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'prefix_id', 'Raw'

        $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

        InvokeNetboxRequest -URI $uri -Raw:$Raw
    }
}
