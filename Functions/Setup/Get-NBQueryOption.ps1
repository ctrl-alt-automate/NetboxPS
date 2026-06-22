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
    if ($null -eq $script:NetboxConfig.IgnoreCaseInQueries) {
        throw "Netbox Query Options are not set! You may set them with Set-NBQueryOption"
    }

    [PSCustomObject]@{
        Name = "IgnoreCase"
        Value = $script:NetboxConfig.IgnoreCaseInQueries
    }
}