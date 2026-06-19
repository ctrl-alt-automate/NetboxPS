<#
.SYNOPSIS
    Sets the behaviour of query parameters.

.DESCRIPTION
    Sets the behaviour of query parameters (see notes).

.PARAMETER IgnoreCase
    If set, query parameters of type string will be case-insensitive (Netbox's `__ie`)

.EXAMPLE
    Set-NBQueryOption -IgnoreCase
    Sets the Netbox API query parameters to be case-insensitive.

.EXAMPLE
    Set-NBQueryOption -IgnoreCase:$false
    Sets the Netbox API query parameters to be case-sensitive (default on startup of the module).

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/

.NOTES
    Depending on the API version, different sets of parameters are supported as case-insensitive.
    As this feature is relying on the API version and its supported parameters, not all parameters are supported as case-insensitive.

#>
function Set-NBQueryOption {
    [CmdletBinding(ConfirmImpact = 'Low',
        SupportsShouldProcess = $true)]
    [OutputType([boolean])]
    param (
        [switch]$IgnoreCase
    )

    if ($PSCmdlet.ShouldProcess('Netbox Query Options', 'Set')) {
        $script:NetboxConfig.IgnoreCaseInQueries = $IgnoreCase
        $Script:IgnoreCaseParameterHash = @{}       # reset list (equal to case sensitive)

        if ($IgnoreCase -eq $true) {
            CheckNetboxIsConnected
            # depending on the API version, we have different sets of parameters that are supported.
            $activeApiMinorVersion = "{0}.{1}" -f ($script:NetboxConfig.ParsedVersion -split '\.')[0..1] #, ($script:NetboxConfig.ParsedVersion -split '\.')[1]
            if ([version]$activeApiMinorVersion -lt [version](@($Script:IgnoreCaseParameterDictonary.Keys)[0])) {
                Write-Warning "API version $($script:NetboxConfig.ParsedVersion) is less than the minimum supported version ($(@($Script:IgnoreCaseParameterDictonary.Keys)[0])). No case-insensitive parameters will be used."
                return $false
            }
            foreach ($key in $Script:IgnoreCaseParameterDictonary.Keys) {
                if ([version]$key -eq [version]$activeApiMinorVersion) {
                    $Script:IgnoreCaseParameterHash = $Script:IgnoreCaseParameterDictonary[$key]
                    break
                }
            }
            if ($Script:IgnoreCaseParameterHash.Keys.Count -eq 0) {
                $latestKnownVersion = (@($Script:IgnoreCaseParameterDictonary.Keys)[-1])
                $Script:IgnoreCaseParameterHash = $Script:IgnoreCaseParameterDictonary[$latestKnownVersion]
                Write-Warning "No case-insensitive parameters are defined for API version $($activeApiMinorVersion).x. Taking the latest known version ($latestKnownVersion)."
            }
        }

        $script:NetboxConfig.IgnoreCaseInQueries
    }
}