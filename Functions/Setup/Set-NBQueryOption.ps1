<#
.SYNOPSIS
    Sets the behaviour of query parameters.

.DESCRIPTION
    Sets the behaviour of query parameters (see notes).

.PARAMETER IgnoreCase
    If set, query parameters of type string will be case-insensitive (Netbox's `__ie`). To reset to case-sensitive, use `-IgnoreCase:$false`.

.PARAMETER MatchMode
    Sets the match mode for query parameters. Valid values are:
    - Exact: Only exact matches will be returned (default).
    - Wildcard: Query parameters will be treated as Powershell wildcards.
    - Regex: Query parameters will be treated as regular expressions (Netbox's `regex`).

.PARAMETER Pagination
    How -All walks large result sets. 'Offset' (default) uses limit/offset pages exactly as before.
    'Cursor' uses Netbox 4.6+ cursor pagination (?start=<pk>, results ordered by primary key), which
    stays fast on very large tables where offset paging degrades. Requires Netbox 4.6+; on older
    servers offset paging is used automatically. Explicit -Offset on a Get cmdlet always wins.

.PARAMETER TagMatch
    How multiple values of a -Tag / -Tag_Id filter combine. 'All' (default) is Netbox's native
    behaviour: an object must carry every listed tag. 'Any' sends Netbox 4.6.6+ 'tag__any' /
    'tag_id__any' so an object matches when it carries at least one of them. Below Netbox 4.6.6 the
    option is ignored (plain 'tag' is sent) because an unknown lookup would silently return every object.

.PARAMETER OptimisticConcurrency
    Netbox 4.6+ returns an ETag on single-object GETs and honours If-Match on PATCH/PUT/DELETE
    (HTTP 412 when the object changed in between). When enabled, the module remembers the ETag of
    every object it reads and sends it as If-Match on the next update or delete of that same object,
    so concurrent edits fail loudly instead of silently overwriting each other. Needs PowerShell 7+
    (response headers are not exposed on Windows PowerShell 5.1). Use -OptimisticConcurrency:$false
    to disable; disabling also clears the cached ETags.

.EXAMPLE
    Set-NBQueryOption -IgnoreCase
    Sets the Netbox API query parameters to be case-insensitive.

.EXAMPLE
    Set-NBQueryOption -IgnoreCase:$false
    Sets the Netbox API query parameters to be case-sensitive (default on startup of the module).

.EXAMPLE
    Set-NBQueryOption -MatchMode 'Wildcard'
    Sets the Netbox API query parameters to be treated as Powershell wildcards.

.EXAMPLE
    Set-NBQueryOption -Pagination Cursor
    Get-NBIPAMAddress -All
    Walks the whole IP address table with cursor pagination (Netbox 4.6+).

.EXAMPLE
    Set-NBQueryOption -TagMatch Any
    Get-NBDCIMDevice -Tag 'edge', 'core'
    Returns devices tagged 'edge' OR 'core' (Netbox 4.6.6+); with the default 'All' both tags are required.

.EXAMPLE
    Set-NBQueryOption -OptimisticConcurrency
    $dev = Get-NBDCIMDevice -Id 42
    Set-NBDCIMDevice -Id 42 -Description 'changed'
    The PATCH carries If-Match with the ETag from the GET; it fails with HTTP 412 if someone else changed device 42 in between.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/

.NOTES
    Depending on the API version, different sets of parameters are supported as case-insensitive.
    As this feature is relying on the API version and its supported parameters, not all parameters are supported as case-insensitive.
#>
function Set-NBQueryOption {
    [CmdletBinding(ConfirmImpact = 'Low',
        SupportsShouldProcess = $true,
        DefaultParameterSetName = 'IgnoreCase')]
    [OutputType([boolean], [string])]
    param (
        # Not mandatory + default set: a bare `Set-NBQueryOption` keeps its pre-MatchMode meaning (IgnoreCase = $false)
        [Parameter(ParameterSetName = 'IgnoreCase')]
        [switch]$IgnoreCase,

        [Parameter(ParameterSetName = 'MatchMode', Mandatory = $true)]
        [ValidateSet('Exact', 'Wildcard', 'Regex')]
        [string]$MatchMode = 'Exact',

        [Parameter(ParameterSetName = 'Pagination', Mandatory = $true)]
        [ValidateSet('Offset', 'Cursor')]
        [string]$Pagination,

        [Parameter(ParameterSetName = 'TagMatch', Mandatory = $true)]
        [ValidateSet('All', 'Any')]
        [string]$TagMatch,

        [Parameter(ParameterSetName = 'OptimisticConcurrency', Mandatory = $true)]
        [switch]$OptimisticConcurrency
    )

    if ($PSCmdlet.ShouldProcess('Netbox Query Options', 'Set')) {
        # We only set the values if they are passed in, otherwise we leave them as they are.
        switch ($PSCmdlet.ParameterSetName) {
            'IgnoreCase' {
                $script:NetboxConfig.IgnoreCaseInQueries = $IgnoreCase
            }
            'MatchMode' {
                $script:NetboxConfig.MatchMode = $MatchMode
            }
            'Pagination' {
                $script:NetboxConfig.Pagination = $Pagination
                if ($Pagination -eq 'Cursor' -and $script:NetboxConfig.ParsedVersion -and $script:NetboxConfig.ParsedVersion -lt [version]'4.6.0') {
                    Write-Warning "Cursor pagination requires Netbox 4.6.0 or higher (connected to $($script:NetboxConfig.ParsedVersion)). Offset pagination will be used until you connect to a newer server."
                }
                Write-Verbose "Set Pagination to $Pagination"
                return $script:NetboxConfig.Pagination
            }
            'TagMatch' {
                $script:NetboxConfig.TagMatch = $TagMatch
                if ($TagMatch -eq 'Any' -and $script:NetboxConfig.ParsedVersion -and $script:NetboxConfig.ParsedVersion -lt [version]'4.6.6') {
                    Write-Warning "TagMatch 'Any' requires Netbox 4.6.6 or higher (connected to $($script:NetboxConfig.ParsedVersion)). Tag filters keep the default all-tags semantics until you connect to a newer server."
                }
                Write-Verbose "Set TagMatch to $TagMatch"
                return $script:NetboxConfig.TagMatch
            }
            'OptimisticConcurrency' {
                $script:NetboxConfig.OptimisticConcurrency = [bool]$OptimisticConcurrency
                if (-not $OptimisticConcurrency) {
                    $script:NetboxConfig.ETagCache = @{}
                }
                elseif ($script:NetboxConfig.ParsedVersion -and $script:NetboxConfig.ParsedVersion -lt [version]'4.6.0') {
                    Write-Warning "Optimistic concurrency (ETag/If-Match) requires Netbox 4.6.0 or higher (connected to $($script:NetboxConfig.ParsedVersion)). Older servers send no ETag, so updates are sent without If-Match."
                }
                Write-Verbose "Set OptimisticConcurrency to $($script:NetboxConfig.OptimisticConcurrency)"
                return $script:NetboxConfig.OptimisticConcurrency
            }
        }

        # depending on the API version, we have different sets of parameters that are supported.
        # Per API version, a set of IgnoreCaseParameterDictionary and RegexParameterDictionary must be defined in the module (see _IgnoreCaseParameters.ps1)
        # This is presumed, to get the latest known version supported from IgnoreCaseParameterDictionary only
        $Script:QueryParameterDecoration = ''
        $Script:QueryParameterHash = @{}
        if ($script:NetboxConfig.IgnoreCaseInQueries -or $script:NetboxConfig.MatchMode -ne 'Exact') {
            $qpSupport = Get-VersionQueryParameterSupport -ShowWarning
            if ($null -eq $qpSupport.UsedVersion) {
                return                  # version below oldest supported version
            }
            switch ("$($script:NetboxConfig.IgnoreCaseInQueries), $($script:NetboxConfig.MatchMode)") {
                'False, Exact' {
                    $Script:QueryParameterDecoration = ''
                    $Script:QueryParameterHash = @{}
                }
            'True, Exact' {
                $Script:QueryParameterDecoration = '__ie'
                $Script:QueryParameterHash = $Script:IgnoreCaseParameterDictionary[$qpSupport.UsedVersion.tostring()]
            }
            'False, Wildcard' {
                $Script:QueryParameterDecoration = '__regex'
                $Script:QueryParameterHash = $Script:RegexParameterDictionary[$qpSupport.UsedVersion.tostring()]
            }
            'False, Regex' {
                $Script:QueryParameterDecoration = '__regex'
                $Script:QueryParameterHash = $Script:RegexParameterDictionary[$qpSupport.UsedVersion.tostring()]
            }
            'True, Wildcard' {
                $Script:QueryParameterDecoration = '__iregex'
                $Script:QueryParameterHash = $Script:RegexParameterDictionary[$qpSupport.UsedVersion.tostring()]
            }
            'True, Regex' {
                $Script:QueryParameterDecoration = '__iregex'
                $Script:QueryParameterHash = $Script:RegexParameterDictionary[$qpSupport.UsedVersion.tostring()]
            }
            default {
                Throw "Invalid combination of IgnoreCase and MatchMode: $($script:NetboxConfig.IgnoreCaseInQueries), $($script:NetboxConfig.MatchMode)"
            }
        }
    }

        switch ($PSCmdlet.ParameterSetName) {
            'IgnoreCase' {
                Write-Verbose "Set IgnoreCase to $($script:NetboxConfig.IgnoreCaseInQueries)"
                $script:NetboxConfig.IgnoreCaseInQueries
            }
            'MatchMode' {
                Write-Verbose "Set MatchMode to $($script:NetboxConfig.MatchMode)"
                $script:NetboxConfig.MatchMode
            }
        }
    }
}