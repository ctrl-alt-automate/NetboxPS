<#
.SYNOPSIS
    Retrieves the current API query options.

.DESCRIPTION
    Retrieves the current API query options.

.EXAMPLE
    Get-NBQueryOption

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES

#>
function Get-NBQueryOption {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param ()

    Write-Verbose "Getting Netbox Query Options"
    if ($null -eq $script:NetboxConfig.IgnoreCaseInQueries -or $null -eq $script:NetboxConfig.MatchMode) {
        throw "Netbox Query Options are not set! You may set them with Set-NBQueryOption"
    }

    [PSCustomObject]@{
        Name = "IgnoreCase"
        Value = $script:NetboxConfig.IgnoreCaseInQueries
    }
    [PSCustomObject]@{
        Name = "MatchMode"
        Value = $script:NetboxConfig.MatchMode
    }
    [PSCustomObject]@{
        Name = "Pagination"
        Value = $script:NetboxConfig.Pagination
    }
    [PSCustomObject]@{
        Name = "TagMatch"
        Value = $script:NetboxConfig.TagMatch
    }
    [PSCustomObject]@{
        Name = "OptimisticConcurrency"
        Value = [bool]$script:NetboxConfig.OptimisticConcurrency
    }
}