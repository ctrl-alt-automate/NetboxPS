<#
.SYNOPSIS
    Clears the stored Netbox API credential.

.DESCRIPTION
    Clears the stored Netbox API credential from the module configuration.

.PARAMETER Force
    Skip the confirmation prompt.

.EXAMPLE
    Clear-NBCredential

    Clears the stored Netbox API credential.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v1.7.1

#>
function Clear-NBCredential {
    [CmdletBinding(ConfirmImpact = 'Medium', SupportsShouldProcess = $true)]
    [OutputType([void])]
    param
    (
        [switch]$Force
    )

    if ($Force -or ($PSCmdlet.ShouldProcess('Netbox Credentials', 'Clear'))) {
        $script:NetboxConfig.Credential = $null
    }
}
