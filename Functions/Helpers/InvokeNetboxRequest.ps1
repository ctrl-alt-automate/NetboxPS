function InvokeNetboxRequest {
    <#
    .SYNOPSIS
        Invokes a REST API request to Netbox.

    .DESCRIPTION
        Core function for all Netbox API communication. Handles authentication,
        retry logic for transient failures, and comprehensive error handling.
        Cross-platform compatible (Windows, Linux, macOS).

        Supports automatic pagination when -All is specified for GET requests.

    .PARAMETER URI
        The URI builder object containing the API endpoint.

    .PARAMETER Headers
        Additional headers to include in the request.

    .PARAMETER Body
        The request body for POST/PATCH/PUT requests.

    .PARAMETER Timeout
        Request timeout in seconds. Defaults to module timeout setting.

    .PARAMETER Method
        HTTP method (GET, POST, PATCH, PUT, DELETE, OPTIONS).

    .PARAMETER Raw
        Return the raw API response instead of just the results array.

    .PARAMETER All
        Automatically fetch all pages of results for GET requests.
        Uses the 'next' field in API response to paginate.

    .PARAMETER PageSize
        Number of items per page when using -All. Default: 100.
        Range: 1-1000.

    .PARAMETER MaxRetries
        Maximum number of retry attempts for transient failures. Default: 3.

    .PARAMETER RetryDelayMs
        Initial delay between retries in milliseconds. Uses exponential backoff. Default: 1000.

    .OUTPUTS
        [PSCustomObject] The API response or results array.

    .EXAMPLE
        $result = InvokeNetboxRequest -URI $uri -Method GET

    .EXAMPLE
        $result = InvokeNetboxRequest -URI $uri -Method GET -All
        Fetches all pages of results automatically.

    .EXAMPLE
        $result = InvokeNetboxRequest -URI $uri -Method POST -Body $data -MaxRetries 5
.NOTES
    AddedInVersion: v1.0.4

    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [System.UriBuilder]$URI,

        [Hashtable]$Headers = @{},

        [object]$Body = $null,

        [ValidateRange(1, 65535)]
        [uint16]$Timeout = (Get-NBTimeout),

        [ValidateSet('GET', 'PATCH', 'PUT', 'POST', 'DELETE', 'OPTIONS', IgnoreCase = $true)]
        [string]$Method = 'GET',

        [switch]$Raw,

        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [ValidateRange(1, 10)]
        [int]$MaxRetries = 3,

        [ValidateRange(100, 30000)]
        [int]$RetryDelayMs = 1000,

        [Parameter()]
        [string]$Branch
    )

    # Handle automatic pagination for GET requests
    if ($All -and $Method -eq 'GET') {
        Write-Verbose "Automatic pagination enabled with page size $PageSize"

        # Add/update limit parameter in URI for first request (cross-platform)
        $currentQuery = $URI.Query.TrimStart('?')
        if ($currentQuery) {
            # Remove any existing limit parameter
            $currentQuery = ($currentQuery -split '&' | Where-Object { $_ -notmatch '^limit=' }) -join '&'
            $URI.Query = "$currentQuery&limit=$PageSize"
        }
        else {
            $URI.Query = "limit=$PageSize"
        }

        $allResults = [System.Collections.ArrayList]::new()
        $pageNum = 0
        $nextUrl = $null

        do {
            $pageNum++
            $currentUri = if ($nextUrl) {
                # Validate that the server-returned pagination URL matches the
                # original request's origin (scheme + host + port) before
                # following it. Without this check, a compromised or malicious
                # NetBox server could redirect pagination to an attacker-
                # controlled host and receive the Authorization header (Bearer
                # token) in plaintext.
                # Reference: 2026-04-18 Tier 2 security review, finding TM-1/IV-1.
                # Using Uri.GetLeftPart(Authority) gives a canonical
                # "scheme://host[:port]" that handles default-port substitution
                # consistently across how the URI was constructed (explicit
                # port vs parsed from a string).
                $nextBuilder     = [System.UriBuilder]::new($nextUrl)
                $originalOrigin  = $URI.Uri.GetLeftPart([System.UriPartial]::Authority)
                $nextOrigin      = $nextBuilder.Uri.GetLeftPart([System.UriPartial]::Authority)
                if ($nextOrigin -ne $originalOrigin) {
                    throw "Refusing to follow pagination 'next' URL to a different origin. Expected $originalOrigin, got $nextOrigin. This may indicate a compromised server or man-in-the-middle attack."
                }
                $nextBuilder
            }
            else {
                $URI
            }

            Write-Verbose "Fetching page ${pageNum}..."

            # Make single-page request (recursive call without -All)
            $pageParams = @{
                URI         = $currentUri
                Headers     = $Headers
                Body        = $Body
                Timeout     = $Timeout
                Method      = $Method
                Raw         = $true
                MaxRetries  = $MaxRetries
                RetryDelayMs = $RetryDelayMs
            }
            $pageResult = InvokeNetboxRequest @pageParams

            if ($pageResult.results) {
                $itemCount = $pageResult.results.Count
                [void]$allResults.AddRange($pageResult.results)
                Write-Verbose "Page ${pageNum}: Retrieved $itemCount items (Total: $($allResults.Count))"

                # Show progress for large datasets
                if ($pageResult.count -gt 0) {
                    $percentComplete = [Math]::Min(100, [int](($allResults.Count / $pageResult.count) * 100))
                    $progressParams = @{
                        Activity        = 'Fetching all results'
                        Status          = "$($allResults.Count) of $($pageResult.count) items"
                        PercentComplete = $percentComplete
                    }
                    Write-Progress @progressParams
                }
            }

            $nextUrl = $pageResult.next

        } while ($nextUrl)

        Write-Progress -Activity "Fetching all results" -Completed

        if ($Raw) {
            # Return a synthetic response object with all results
            return [PSCustomObject]@{
                count    = $allResults.Count
                next     = $null
                previous = $null
                results  = $allResults.ToArray()
            }
        }
        else {
            return $allResults.ToArray()
        }
    }

    # Retryable HTTP status codes
    $retryableStatusCodes = @(408, 429, 500, 502, 503, 504)

    # Get authorization and branch context headers using centralized helper
    $requestHeaders = Get-NBRequestHeaders -Branch $Branch
    foreach ($key in $requestHeaders.Keys) {
        $Headers[$key] = $requestHeaders[$key]
    }

    $splat = @{
        'Method'      = $Method
        'Uri'         = $URI.Uri.AbsoluteUri
        'Headers'     = $Headers
        'TimeoutSec'  = $Timeout
        'ContentType' = 'application/json'
        'ErrorAction' = 'Stop'
    }

    $splat += Get-NBInvokeParams

    if ($Body) {
        if ($Body -is [array]) {
            # Bulk array: suppress field-level logging to avoid leaking sensitive values
            Write-Verbose "BODY: [bulk array of $($Body.Count) items]"
            $null = $splat.Add('Body', ($Body | ConvertTo-Json -Compress -Depth 10))
        }
        else {
            # Sanitize sensitive fields before logging
            $sensitivePatterns = @('secret', 'password', 'key', 'token', 'psk')
            $sanitizedBody = @{}
            foreach ($prop in $Body.PSObject.Properties) {
                $isSensitive = $sensitivePatterns | Where-Object { $prop.Name -match $_ }
                if ($isSensitive) {
                    $sanitizedBody[$prop.Name] = '***REDACTED***'
                }
                else {
                    $sanitizedBody[$prop.Name] = $prop.Value
                }
            }
            Write-Verbose "BODY: $($sanitizedBody | ConvertTo-Json -Compress)"
            $null = $splat.Add('Body', ($Body | ConvertTo-Json -Compress -Depth 10))
        }
    }

    $attempt = 0

    while ($attempt -lt $MaxRetries) {
        $attempt++

        try {
            Write-Verbose "[$attempt/$MaxRetries] $Method $($URI.Uri.AbsoluteUri)"
            $result = Invoke-RestMethod @splat

            # Success - return result
            if ($Raw) {
                Write-Verbose "Returning raw result by choice"
                return $result
            }
            else {
                if ($result.psobject.Properties.Name -contains 'results') {
                    Write-Verbose "Found 'results' property, returning results directly"
                    return $result.Results
                }
                else {
                    Write-Verbose "No 'results' property found, returning full response"
                    return $result
                }
            }
        }
        catch {
            $statusCode = $null
            $errorMessage = $_.Exception.Message
            $errorBody = $null

            # Extract status code from response
            if ($_.Exception.Response) {
                $statusCode = [int]$_.Exception.Response.StatusCode
            }

            # PowerShell Core 7.x: ErrorDetails.Message contains the response body
            # (HttpResponseMessage is disposed before we can read it directly)
            if ($_.ErrorDetails.Message) {
                Write-Verbose "Using ErrorDetails.Message for error body (PowerShell Core)"
                $errorBody = $_.ErrorDetails.Message
            }
            # Fallback: Try to read from Response object (Windows PowerShell 5.1)
            elseif ($_.Exception.Response) {
                # Use helper function for safe response body extraction
                $errorResponse = GetNetboxAPIErrorBody -Response $_.Exception.Response
                if ($errorResponse.Body) {
                    $errorBody = $errorResponse.Body
                }
            }

            # Parse error body if we have one
            if ($errorBody) {
                # Try to parse as JSON first (Netbox API returns JSON errors)
                try {
                    $errorData = $errorBody | ConvertFrom-Json -ErrorAction Stop
                    if ($errorData.detail) {
                        $errorMessage = $errorData.detail
                        # Netbox 4.7+ bulk create/update failures return
                        # {"detail": ..., "errors": [{"index": N, "errors": {field: [msg]}}]}
                        # so the caller can correlate each error with the offending object.
                        if ($errorData.errors -is [System.Array] -and $errorData.errors.Count -gt 0) {
                            $perObject = foreach ($entry in $errorData.errors) {
                                $fieldErrors = if ($entry.errors) {
                                    ($entry.errors.PSObject.Properties | ForEach-Object {
                                        "$($_.Name): $($_.Value -join ', ')"
                                    }) -join '; '
                                } else { "$($entry | ConvertTo-Json -Compress -Depth 5)" }
                                "[$($entry.index)] $fieldErrors"
                            }
                            $errorMessage = "$errorMessage`n" + ($perObject -join "`n")
                        }
                    }
                    elseif ($errorData.error) {
                        $errorMessage = $errorData.error
                    }
                    elseif ($errorData) {
                        # Try to format the error object nicely
                        $errorMessage = ($errorData.PSObject.Properties | ForEach-Object {
                            "$($_.Name): $($_.Value -join ', ')"
                        }) -join '; '
                    }
                }
                catch {
                    # Not valid JSON - check if it's HTML (from proxies)
                    if ($errorBody -match '^\s*<' -or $errorBody -match '<!DOCTYPE') {
                        $errorMessage = ExtractHtmlErrorMessage -Html $errorBody -StatusCode $statusCode
                    }
                    # Plain text or other format
                    elseif ($errorBody.Length -lt 500) {
                        $errorMessage = $errorBody
                    }
                    else {
                        # Large non-JSON response - truncate
                        $errorMessage = $errorBody.Substring(0, 500) + '...'
                    }
                }
            }

            # Check if we should retry
            $shouldRetry = ($statusCode -in $retryableStatusCodes) -and ($attempt -lt $MaxRetries)

            if ($shouldRetry) {
                # Exponential backoff with jitter
                $delay = $RetryDelayMs * [Math]::Pow(2, $attempt - 1)
                $jitter = Get-Random -Minimum 0 -Maximum ($delay * 0.1)
                $totalDelay = [int]($delay + $jitter)

                $statusName = GetHttpStatusName -StatusCode $statusCode
                Write-Verbose "Retryable error ($statusCode $statusName). Waiting ${totalDelay}ms before retry..."
                Start-Sleep -Milliseconds $totalDelay
                continue
            }

            # Non-retryable error or max retries reached - throw detailed error
            $statusName = if ($statusCode) { GetHttpStatusName -StatusCode $statusCode } else { "Unknown" }

            $errorParams = @{
                StatusCode   = $statusCode
                StatusName   = $statusName
                Method       = $Method
                Endpoint     = $URI.Uri.AbsoluteUri
                ErrorMessage = $errorMessage
            }
            $detailedMessage = BuildDetailedErrorMessage @errorParams

            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new($detailedMessage),
                "NetboxAPI.$statusCode",
                (GetErrorCategory -StatusCode $statusCode),
                $URI.Uri.AbsoluteUri
            )

            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }
}

function GetHttpStatusName {
    [CmdletBinding()]
    [OutputType([string])]
    param([int]$StatusCode)

    $statusNames = @{
        400 = 'Bad Request'
        401 = 'Unauthorized'
        403 = 'Forbidden'
        404 = 'Not Found'
        405 = 'Method Not Allowed'
        408 = 'Request Timeout'
        409 = 'Conflict'
        429 = 'Too Many Requests'
        500 = 'Internal Server Error'
        502 = 'Bad Gateway'
        503 = 'Service Unavailable'
        504 = 'Gateway Timeout'
    }

    if ($statusNames.ContainsKey($StatusCode)) {
        return $statusNames[$StatusCode]
    }
    return "HTTP $StatusCode"
}

function GetErrorCategory {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.ErrorCategory])]
    param([int]$StatusCode)

    switch ($StatusCode) {
        400 { return [System.Management.Automation.ErrorCategory]::InvalidArgument }
        401 { return [System.Management.Automation.ErrorCategory]::AuthenticationError }
        403 { return [System.Management.Automation.ErrorCategory]::PermissionDenied }
        404 { return [System.Management.Automation.ErrorCategory]::ObjectNotFound }
        405 { return [System.Management.Automation.ErrorCategory]::InvalidOperation }
        408 { return [System.Management.Automation.ErrorCategory]::OperationTimeout }
        409 { return [System.Management.Automation.ErrorCategory]::ResourceExists }
        429 { return [System.Management.Automation.ErrorCategory]::LimitsExceeded }
        { $_ -ge 500 } { return [System.Management.Automation.ErrorCategory]::ConnectionError }
        default { return [System.Management.Automation.ErrorCategory]::InvalidOperation }
    }
}

function BuildDetailedErrorMessage {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [int]$StatusCode,
        [string]$StatusName,
        [string]$Method,
        [string]$Endpoint,
        [string]$ErrorMessage
    )

    # Detect active branch context (if any) so auth failures can hint at
    # branch-specific permission issues. See issue #382.
    $branchHint = $null
    if ($script:NetboxConfig.BranchStack -and $script:NetboxConfig.BranchStack.Count -gt 0) {
        $currentBranch = $script:NetboxConfig.BranchStack.Peek()
        $branchHint = if ($currentBranch -is [PSCustomObject] -and $currentBranch.Name) {
            "$($currentBranch.Name) (schema_id: $($currentBranch.SchemaId))"
        }
        else {
            [string]$currentBranch
        }
    }

    $troubleshooting = switch ($StatusCode) {
        401 {
            $tips = @(
                "- Verify your API token is correct and not expired"
                "- Check token in Netbox: Admin > API Tokens"
                "- Ensure token has not been revoked"
            )
            if ($branchHint) {
                $tips += @(
                    "- Active branch context: $branchHint"
                    "- Verify the token user has access to this branch"
                )
            }
            $tips -join "`n"
        }
        403 {
            $tips = @(
                "- Verify your API token has permission for this operation"
                "- Check object-level permissions in Netbox"
                "- Ensure the token user has the required role"
            )
            if ($branchHint) {
                $tips += @(
                    "- Active branch context: $branchHint"
                    "- Verify write permissions apply within the branch schema"
                    "- Confirm the branch is not merged, archived, or read-only"
                    "- Use Exit-NBBranch to test if the operation succeeds in main context"
                )
            }
            $tips -join "`n"
        }
        404 {
            @(
                "- Verify the resource ID exists in Netbox"
                "- Check if the resource was deleted"
                "- Ensure the API endpoint is correct for your Netbox version"
            ) -join "`n"
        }
        429 {
            @(
                "- You are being rate limited by the API"
                "- Wait a moment and retry your request"
                "- Consider reducing request frequency"
            ) -join "`n"
        }
        { $_ -ge 500 } {
            @(
                "- This is a server-side error in Netbox"
                "- Check Netbox server logs for details"
                "- Verify Netbox service is running correctly"
                "- Try again in a few moments"
            ) -join "`n"
        }
        default {
            "- Check your request parameters`n- Verify the API endpoint exists"
        }
    }

    return @"
Netbox API Error: $StatusCode $StatusName
Endpoint: $Method $Endpoint
Message: $ErrorMessage

Troubleshooting:
$troubleshooting
"@
}

function ExtractHtmlErrorMessage {
    <#
    .SYNOPSIS
        Extracts a meaningful error message from HTML error pages.

    .DESCRIPTION
        When a proxy (nginx, HAProxy, Cloudflare) returns an HTML error page,
        this function extracts the title or heading to provide a more useful
        error message than raw HTML.

    .PARAMETER Html
        The HTML content from the error response.

    .PARAMETER StatusCode
        The HTTP status code for context.

    .OUTPUTS
        [string] A human-readable error message.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string]$Html,
        [int]$StatusCode
    )

    # Try to extract <title> content
    if ($Html -match '<title>([^<]+)</title>') {
        $title = $Matches[1].Trim()
        if ($title -and $title -ne '') {
            return "Proxy error: $title"
        }
    }

    # Try to extract <h1> content
    if ($Html -match '<h1[^>]*>([^<]+)</h1>') {
        $heading = $Matches[1].Trim()
        if ($heading -and $heading -ne '') {
            return "Proxy error: $heading"
        }
    }

    # Detect known proxy signatures and provide helpful messages
    $htmlLower = $Html.ToLower()

    if ($htmlLower -match 'cloudflare') {
        return "Cloudflare proxy error (HTTP $StatusCode) - The backend server may be unreachable"
    }

    if ($htmlLower -match 'nginx') {
        return "nginx proxy error (HTTP $StatusCode) - The backend server may be unavailable"
    }

    if ($htmlLower -match 'haproxy') {
        return "HAProxy error (HTTP $StatusCode) - The backend server may be down"
    }

    if ($htmlLower -match 'apache') {
        return "Apache proxy error (HTTP $StatusCode) - The backend server may not be responding"
    }

    if ($htmlLower -match 'varnish') {
        return "Varnish cache error (HTTP $StatusCode) - The origin server may be unreachable"
    }

    # Generic fallback for unidentified HTML responses
    return "Proxy returned HTML error page (HTTP $StatusCode) - Check network/proxy configuration"
}
