
function BuildNewURI {
<#
    .SYNOPSIS
        Create a new URI for Netbox

    .DESCRIPTION
        Internal function used to build a URIBuilder object.

    .PARAMETER Hostname
        Hostname of the Netbox API

    .PARAMETER Segments
        Array of strings for each segment in the URL path

    .PARAMETER Parameters
        Hashtable of query parameters to include

    .PARAMETER HTTPS
        Whether to use HTTPS or HTTP

    .EXAMPLE
        PS C:\> BuildNewURI -Segments @('dcim', 'devices')
.NOTES
    AddedInVersion: v1.0.4

#>

    [CmdletBinding()]
    [OutputType([System.UriBuilder])]
    param
    (
        [Parameter(Mandatory = $false)]
        [string[]]$Segments,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters,

        [switch]$SkipConnectedCheck
    )

    Write-Verbose "Building URI"

    if (-not $SkipConnectedCheck) {
        # There is no point in continuing if we have not successfully connected to an API
        $null = CheckNetboxIsConnected
    }

    # Begin a URI builder with HTTP/HTTPS and the provided hostname
    $uriBuilder = [System.UriBuilder]::new($script:NetboxConfig.HostScheme, $script:NetboxConfig.Hostname, $script:NetboxConfig.HostPort)

    # Validate and sanitize segments (defense-in-depth)
    $sanitizedSegments = $Segments.ForEach({
        $segment = ([string]$_).trim('/').trim()
        # Warn if segment contains characters other than alphanumeric, underscore, or hyphen
        if ($segment -and $segment -notmatch '^[a-zA-Z0-9_-]+$') {
            Write-Warning "URI segment contains unexpected characters: $segment"
        }
        $segment
    })

    # Generate the path by joining sanitized segments
    $uriBuilder.Path = "api/{0}/" -f ($sanitizedSegments -join '/')

    Write-Verbose " URIPath: $($uriBuilder.Path)"

    if ($parameters) {
        # Build query string without System.Web dependency (cross-platform)
        $QueryParts = [System.Collections.Generic.List[string]]::new()

        foreach ($param in $Parameters.GetEnumerator()) {
            # Handle array values by repeating the key for each value (e.g., ?key=value1&key=value2)
            $EncodedKey = [System.Uri]::EscapeDataString($param.Key)
            foreach ($thisValue in $param.Value) {
                Write-Verbose " Adding URI parameter $($param.Key):$thisValue"
                # URL encode key and value using .NET Uri class (available everywhere)
                $EncodedValue = [System.Uri]::EscapeDataString([string]$thisValue)
                $QueryParts.Add("$EncodedKey=$EncodedValue")
            }
        }

        $uriBuilder.Query = $QueryParts -join '&'
    }

    Write-Verbose " Completed building URIBuilder"
    # Return the entire UriBuilder object
    $uriBuilder
}