<#
.SYNOPSIS
    Sets the hostname for Netbox API connections.

.DESCRIPTION
    Sets the hostname for Netbox API connections.

.PARAMETER Hostname
    Hostname.

.EXAMPLE
    Set-NBHostName -Hostname 'netbox.example.com'

    Sets the Netbox API hostname.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v1.0.4

#>
function Set-NBHostName {
    [CmdletBinding(ConfirmImpact = 'Low',
        SupportsShouldProcess = $true)]
    [OutputType([string])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Hostname
    )

    if ($PSCmdlet.ShouldProcess('Netbox Hostname', 'Set')) {
        $script:NetboxConfig.Hostname = $Hostname.Trim()
        $script:NetboxConfig.Hostname
    }
}