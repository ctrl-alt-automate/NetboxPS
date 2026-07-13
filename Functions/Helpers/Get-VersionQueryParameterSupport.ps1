function Get-VersionQueryParameterSupport {
    <#
    .SYNOPSIS
    Gets the version query parameter support information.

    .DESCRIPTION
    This function checks the supported API versions and returns an object containing the minimum, maximum, and used versions.

    .PARAMETER ShowWarning
    Switch to show warnings if the active API version is outside the supported range.

    .OUTPUTS
    [PSCustomObject] with properties [version]MinVersion, [version]MaxVersion, [version]APIVersion, and [string!!]UsedVersion.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [switch] $ShowWarning
    )

    CheckNetboxIsConnected

    $result = [PSCustomObject]@{
        MinVersion      = [version] (@($Script:IgnoreCaseParameterDictonary.Keys)[0])
        MaxVersion      = [version] (@($Script:IgnoreCaseParameterDictonary.Keys)[-1])
        APIVersion      = [version]::new($script:NetboxConfig.ParsedVersion.Major, $script:NetboxConfig.ParsedVersion.Minor)
        UsedVersion     = (@($Script:IgnoreCaseParameterDictonary.Keys)[-1])   # Default is the latest known version; $null: unsupported version
    }
    if ($result.APIVersion -lt $result.MinVersion -and $ShowWarning) {
        Write-Warning "API version $($script:NetboxConfig.ParsedVersion) is less than the minimum supported version ($(@($Script:IgnoreCaseParameterDictonary.Keys)[0])). No case-insensitive parameters will be used."
        $result.UsedVersion = $null
    } else {
        foreach ($key in $Script:IgnoreCaseParameterDictonary.Keys) {
            if ([version]$key -eq $result.APIVersion) {
                $result.UsedVersion = [version]$key
                break
            }
        }
        if ($result.UsedVersion -lt $result.APIVersion -and $ShowWarning) {
            Write-Warning "No explicit defined query parameter support for API version $($result.APIVersion). Taking the latest known version ($($result.MaxVersion))."
        }
    }
    $result
}