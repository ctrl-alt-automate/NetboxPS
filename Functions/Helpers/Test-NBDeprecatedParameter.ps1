function Test-NBDeprecatedParameter {
    <#
    .SYNOPSIS
        Checks if a deprecated parameter is being used and handles it appropriately.

    .DESCRIPTION
        This helper function checks if a deprecated parameter is being used and:
        - Emits a warning if the current Netbox version is >= the deprecation version
        - Returns $true if the parameter should be excluded from the API request
        - Returns $false if the parameter should still be sent (older Netbox version)

        This allows for graceful deprecation of parameters while maintaining
        backwards compatibility with older Netbox versions.

    .PARAMETER ParameterName
        The name of the deprecated parameter.

    .PARAMETER DeprecatedInVersion
        The Netbox version where this parameter was deprecated/removed.

    .PARAMETER RemovedInVersion
        The Netbox version that will remove the field entirely. Supplying this switches the
        helper to warn-only mode: the caller is told the parameter is on its way out, but the
        function returns $false so the value is still sent. Use this while a deprecated field
        is deprecated-but-functional; omit it once the server ignores the field.

    .PARAMETER BoundParameters
        The $PSBoundParameters from the calling function.

    .PARAMETER ReplacementMessage
        Optional message explaining what to use instead.

    .OUTPUTS
        [bool] - $true if parameter should be excluded, $false if it should be included

    .EXAMPLE
        # In a function with deprecated Is_Staff parameter:
        if (Test-NBDeprecatedParameter -ParameterName 'Is_Staff' -DeprecatedInVersion '4.5.0' -BoundParameters $PSBoundParameters) {
            $PSBoundParameters.Remove('Is_Staff') | Out-Null
        }

    .EXAMPLE
        # Deprecated but still functional until Netbox 5.0 - warn, but keep sending the value:
        $null = Test-NBDeprecatedParameter -ParameterName 'Ports' -DeprecatedInVersion '4.7.0' `
            -RemovedInVersion '5.0' -BoundParameters $PSBoundParameters `
            -ReplacementMessage 'Use -Port_Mappings instead.'

    .NOTES
    AddedInVersion: v4.5.0.0
        This function requires that Connect-NBAPI has been called and
        $script:NetboxConfig.ParsedVersion is set.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory)]
        [string]$ParameterName,

        [Parameter(Mandatory)]
        [string]$DeprecatedInVersion,

        [string]$RemovedInVersion,

        [Parameter(Mandatory)]
        [hashtable]$BoundParameters,

        [string]$ReplacementMessage
    )

    # If the parameter wasn't used, nothing to do
    if (-not $BoundParameters.ContainsKey($ParameterName)) {
        return $false
    }

    # Get the current Netbox version
    $currentVersion = $script:NetboxConfig.ParsedVersion
    $deprecatedVersion = [version]$DeprecatedInVersion

    if ($null -eq $currentVersion) {
        Write-Verbose "Cannot determine Netbox version - parameter '$ParameterName' will be sent"
        return $false
    }

    if ($currentVersion -ge $deprecatedVersion) {
        # Parameter is deprecated in this version. Two flavours:
        #  - no -RemovedInVersion: the server ignores the field, so drop it from the request
        #  - with -RemovedInVersion: still functional, so warn but keep sending it
        $stillSent = -not [string]::IsNullOrEmpty($RemovedInVersion)

        $warningMsg = if ($stillSent) {
            "The '-$ParameterName' parameter is deprecated in Netbox $DeprecatedInVersion and will be removed in Netbox $RemovedInVersion."
        } else {
            "The '$ParameterName' parameter is deprecated in Netbox $DeprecatedInVersion and will be ignored."
        }
        if ($ReplacementMessage) {
            $warningMsg += " $ReplacementMessage"
        }

        # Report each distinct message once per connection. A bulk pipeline would otherwise
        # emit hundreds of identical warnings and train users to silence all of them.
        if ($null -eq $script:NetboxConfig.DeprecationWarned) {
            $script:NetboxConfig.DeprecationWarned = @{}
        }
        if (-not $script:NetboxConfig.DeprecationWarned.ContainsKey($warningMsg)) {
            $script:NetboxConfig.DeprecationWarned[$warningMsg] = $true
            Write-Warning $warningMsg
        } else {
            Write-Verbose "Deprecation already reported this session: $warningMsg"
        }

        return (-not $stillSent)
    }

    # Older version - parameter is still valid
    Write-Verbose "Parameter '$ParameterName' is valid for Netbox $currentVersion (deprecated in $DeprecatedInVersion)"
    return $false
}
