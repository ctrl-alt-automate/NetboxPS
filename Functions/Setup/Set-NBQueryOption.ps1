<#
.SYNOPSIS
    Sets the behaviour of query parameters.

.DESCRIPTION
    Sets the behaviour of query parameters.

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

#>
function Set-NBQueryOption {
    [CmdletBinding(ConfirmImpact = 'Low',
        SupportsShouldProcess = $true)]
    [OutputType([boolean])]
    param
    (
        [switch]$IgnoreCase
    )

    if ($PSCmdlet.ShouldProcess('Netbox Query Options', 'Set')) {
        $script:NetboxConfig.IgnoreCaseInQueries = $IgnoreCase
        $script:NetboxConfig.IgnoreCaseInQueries
    }
}