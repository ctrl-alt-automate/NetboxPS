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