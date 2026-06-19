<#
.SYNOPSIS
    Sets the credential for Netbox API authentication.

.DESCRIPTION
    Sets the credential for Netbox API authentication.

.PARAMETER Credential
    Credential.

.PARAMETER Token
    Token.

.EXAMPLE
    Set-NBCredential

    Sets the Netbox API credential.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v1.0.4

#>
function Set-NBCredential {
    [CmdletBinding(DefaultParameterSetName = 'CredsObject',
        ConfirmImpact = 'Low',
        SupportsShouldProcess = $true)]
    [OutputType([pscredential])]
    param
    (
        [Parameter(ParameterSetName = 'CredsObject',
            Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter(ParameterSetName = 'UserPass',
            Mandatory = $true)]
        [securestring]$Token
    )

    if ($PSCmdlet.ShouldProcess('Netbox Credentials', 'Set')) {
        switch ($PsCmdlet.ParameterSetName) {
            'CredsObject' {
                $script:NetboxConfig.Credential = $Credential
                break
            }

            'UserPass' {
                $script:NetboxConfig.Credential = [System.Management.Automation.PSCredential]::new('notapplicable', $Token)
                break
            }
        }

        $script:NetboxConfig.Credential
    }
}