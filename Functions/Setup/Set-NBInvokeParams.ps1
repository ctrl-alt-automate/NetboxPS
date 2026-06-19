<#
.SYNOPSIS
    Sets additional parameters for Netbox API invocations.

.DESCRIPTION
    Sets additional parameters for Netbox API invocations.

.PARAMETER InvokeParams
    InvokeParams.

.EXAMPLE
    Set-NBInvokeParams -InvokeParams @{ SkipCertificateCheck = $true }

    Sets additional parameters for Invoke-RestMethod calls.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v1.7.1

#>
function Set-NBInvokeParams {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Params refers to a collection of invoke parameters')]
    [CmdletBinding(ConfirmImpact = 'Low',
        SupportsShouldProcess = $true)]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$InvokeParams
    )

    if ($PSCmdlet.ShouldProcess('Netbox Invoke Params', 'Set')) {
        $script:NetboxConfig.InvokeParams = $InvokeParams
        $script:NetboxConfig.InvokeParams
    }
}