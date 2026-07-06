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

.EXAMPLE
    Set-NBQueryOption -IgnoreCase
    Sets the Netbox API query parameters to be case-insensitive.

.EXAMPLE
    Set-NBQueryOption -IgnoreCase:$false
    Sets the Netbox API query parameters to be case-sensitive (default on startup of the module).

.EXAMPLE
    Set-NBQueryOption -MatchMode 'Wildcard'
    Sets the Netbox API query parameters to be treated as Powershell wildcards.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/

.NOTES
    Depending on the API version, different sets of parameters are supported as case-insensitive.
    As this feature is relying on the API version and its supported parameters, not all parameters are supported as case-insensitive.
#>
function Set-NBQueryOption {
    [CmdletBinding(ConfirmImpact = 'Low',
        SupportsShouldProcess = $true)]
    [OutputType([boolean], [string])]
    param (
        [Parameter(ParameterSetName = 'IgnoreCase', Mandatory = $true)]
        [switch]$IgnoreCase,

        [Parameter(ParameterSetName = 'MatchMode', Mandatory = $true)]
        [ValidateSet('Exact', 'Wildcard', 'Regex')]
        [string]$MatchMode = 'Exact'
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
        }
        switch ("$($script:NetboxConfig.IgnoreCaseInQueries), $($script:NetboxConfig.MatchMode)") {
            'False, Exact' {
                $Script:QueryParameterDecoration = ''
            }
            'False, Wildcard' {
                $Script:QueryParameterDecoration = '__regex'
            }
            'False, Regex' {
                $Script:QueryParameterDecoration = '__regex'
            }
            'True, Exact' {
                $Script:QueryParameterDecoration = '__ie'
            }
            'True, Wildcard' {
                $Script:QueryParameterDecoration = '__iregex'
            }
            'True, Regex' {
                $Script:QueryParameterDecoration = '__iregex'
            }
            default {
                Throw "Invalid combination of IgnoreCase and MatchMode: $($script:NetboxConfig.IgnoreCaseInQueries), $($script:NetboxConfig.MatchMode)"
            }
        }

        $Script:QueryParameterHash = @{}       # reset list (equal to case sensitive)

        if ('' -ne $Script:QueryParameterDecoration) {
            CheckNetboxIsConnected
            # depending on the API version, we have different sets of parameters that are supported.
            $activeApiMinorVersion = "{0}.{1}" -f ($script:NetboxConfig.ParsedVersion -split '\.')[0..1] #, ($script:NetboxConfig.ParsedVersion -split '\.')[1]
            if ([version]$activeApiMinorVersion -lt [version](@($Script:IgnoreCaseParameterDictonary.Keys)[0])) {
                Write-Warning "API version $($script:NetboxConfig.ParsedVersion) is less than the minimum supported version ($(@($Script:IgnoreCaseParameterDictonary.Keys)[0])). No case-insensitive parameters will be used."
                return $false
            }
            foreach ($key in $Script:IgnoreCaseParameterDictonary.Keys) {
                if ([version]$key -eq [version]$activeApiMinorVersion) {
                    $Script:QueryParameterHash = $Script:IgnoreCaseParameterDictonary[$key]
                    break
                }
            }
            if ($Script:QueryParameterHash.Keys.Count -eq 0) {
                $latestKnownVersion = (@($Script:IgnoreCaseParameterDictonary.Keys)[-1])
                $Script:QueryParameterHash = $Script:IgnoreCaseParameterDictonary[$latestKnownVersion]
                Write-Warning "No case-insensitive parameters are defined for API version $($activeApiMinorVersion).x. Taking the latest known version ($latestKnownVersion)."
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