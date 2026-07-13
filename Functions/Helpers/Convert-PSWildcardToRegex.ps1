function Convert-PSWildcardToRegex {
    <#
        .SYNOPSIS
            Converts a Powershell wildcard string to a regex string
        .DESCRIPTION
            Converts a Powershell wildcard string to a regex string. This is necessary because the Netbox API uses regex for its search parameters.
        .PARAMETER String
            The Powershell wildcard string to convert to regex.
        .OUTPUTS
            [string] The converted regex string.
        .EXAMPLE
            Convert-PSWildcardToRegex -String 'abc*'
            Returns '^abc.*$'
        .EXAMPLE
            Convert-PSWildcardToRegex -String 'a[bc]?'
            Returns '^a[bc].$'
        .NOTES
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [string] $String
    )

    process {
        if ([string]::IsNullOrEmpty($String)) {
            return $String
        }
        # replace wildcard characters with regex equivalents
        $regexString = [regex]::Escape($String)
        $regexString = $regexString -replace '\\\*', '.*' -replace '\\\?', '.' -replace '\\\[', '[' -replace '\\\]', ']'
        "^$regexString`$"
    }
}