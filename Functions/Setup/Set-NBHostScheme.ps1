<#
.SYNOPSIS
    Sets the HTTP scheme (http/https) for Netbox API connections.

.DESCRIPTION
    Sets the HTTP scheme (http/https) for Netbox API connections.

.PARAMETER Scheme
    Scheme.

.EXAMPLE
    Set-NBHostScheme -Scheme 'https'

    Sets the Netbox API host scheme (http or https).

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v1.3.3

#>
function Set-NBHostScheme {
    [CmdletBinding(ConfirmImpact = 'Low',
                   SupportsShouldProcess = $true)]
    [OutputType([string])]
    param
    (
        [Parameter(Mandatory = $false)]
        [ValidateSet('https', 'http', IgnoreCase = $true)]
        [string]$Scheme = 'https'
    )

    if ($PSCmdlet.ShouldProcess('Netbox Host Scheme', 'Set')) {
        if ($Scheme -eq 'http') {
            Write-Warning "Connecting via non-secure HTTP is not-recommended"
        }

        $script:NetboxConfig.HostScheme = $Scheme
        $script:NetboxConfig.HostScheme
    }
}