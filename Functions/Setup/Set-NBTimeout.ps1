<#
.SYNOPSIS
    Sets the timeout for Netbox API requests.

.DESCRIPTION
    Sets the timeout for Netbox API requests.

.PARAMETER TimeoutSeconds
    TimeoutSeconds.

.EXAMPLE
    Set-NBTimeout -TimeoutSeconds 60

    Sets the Netbox API request timeout.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v1.7.1

#>

function Set-NBTimeout {
    [CmdletBinding(ConfirmImpact = 'Low',
                   SupportsShouldProcess = $true)]
    [OutputType([uint16])]
    param
    (
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 65535)]
        [uint16]$TimeoutSeconds = 30
    )

    if ($PSCmdlet.ShouldProcess('Netbox Timeout', 'Set')) {
        $script:NetboxConfig.Timeout = $TimeoutSeconds
        $script:NetboxConfig.Timeout
    }
}