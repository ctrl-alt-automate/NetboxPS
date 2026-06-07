<#
.SYNOPSIS
    Sets the port for Netbox API connections.

.DESCRIPTION
    Sets the port for Netbox API connections.

.PARAMETER Port
    Port.

.EXAMPLE
    Set-NBHostPort -Port 443

    Sets the Netbox API host port.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v1.3.3

#>
function Set-NBHostPort {
    [CmdletBinding(ConfirmImpact = 'Low',
                   SupportsShouldProcess = $true)]
    [OutputType([uint16])]
    param
    (
        [Parameter(Mandatory = $true)]
        [uint16]$Port
    )

    if ($PSCmdlet.ShouldProcess('Netbox Port', 'Set')) {
        $script:NetboxConfig.HostPort = $Port
        $script:NetboxConfig.HostPort
    }
}