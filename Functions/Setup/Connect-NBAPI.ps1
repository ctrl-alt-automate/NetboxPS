function Connect-NBAPI {
<#
    .SYNOPSIS
        Connects to the Netbox API and ensures Credential work properly

    .DESCRIPTION
        Connects to the Netbox API and ensures Credential work properly.
        After a successful connection, the query options IgnoreCase and MatchMode are set to their respective values (or defaults).

    .PARAMETER Hostname
        The hostname for the resource such as netbox.domain.com

    .PARAMETER Credential
        A PSCredential object. Put the API token in the Password field. The Username field is ignored.

        Supports both token formats:
        - v1 (legacy): 40-character hex token, uses 'Token' auth header
        - v2 (4.5+): Starts with 'nbt_', uses 'Bearer' auth header

        The correct auth header is automatically detected based on token format.

        Example: $cred = [PSCredential]::new('api', (ConvertTo-SecureString 'your-api-token' -AsPlainText -Force))

    .PARAMETER Scheme
        Scheme for the URI such as HTTP or HTTPS. Defaults to HTTPS

    .PARAMETER Port
        Port for the resource. Value between 1-65535

    .PARAMETER URI
        The full URI for the resource such as "https://netbox.domain.com:8443"

    .PARAMETER SkipCertificateCheck
        Skip SSL/TLS certificate validation. Use this for self-signed certificates or test environments.
        On PowerShell Core (7+), uses the native -SkipCertificateCheck parameter.
        On PowerShell Desktop (5.1), uses a custom certificate policy callback.

    .PARAMETER TimeoutSeconds
        The number of seconds before the HTTP call times out. Defaults to 30 seconds

    .PARAMETER IgnoreCase
        When set, string query parameters are sent case-insensitively using Netbox's "__ie" lookup
        (e.g., ?name__ie=value). Only applies to parameters supported by the connected Netbox version,
        and only on endpoints where that lookup is available; unsupported fields stay case-sensitive.
        See Set-NBQueryOption for details.

    .PARAMETER MatchMode
        Sets the match mode for query parameters. Valid values are:
        - Exact: Only exact matches will be returned (default).
        - Wildcard: Query parameters will be treated as Powershell wildcards.
        - Regex: Query parameters will be treated as regular expressions (Netbox's `regex`).
        See Set-NBQueryOption for details.

    .EXAMPLE
        PS C:\> Connect-NBAPI -Hostname "netbox.domain.com"

        This will prompt for Credential, then proceed to attempt a connection to Netbox

    .EXAMPLE
        PS C:\> Connect-NBAPI -Hostname "netbox.domain.com" -IgnoreCase

        This will prompt for Credential, then proceed to attempt a connection to Netbox with case-insensitive query parameters enabled

    .EXAMPLE
        PS C:\> Connect-NBAPI -URI "https://netbox.domain.com:8443" -Credential $cred -IgnoreCase -MatchMode 'Wildcard'

        Same, but with a full URI, credential object, and both query options set.

    .NOTES
        AddedInVersion: v1.0.4


#>

    [CmdletBinding(DefaultParameterSetName = 'Manual')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(ParameterSetName = 'Manual',
                   Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Hostname,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter(ParameterSetName = 'Manual')]
        [ValidateSet('https', 'http')]
        [string]$Scheme = 'https',

        [Parameter(ParameterSetName = 'Manual')]
        [uint16]$Port = 443,

        [Parameter(ParameterSetName = 'URI',
                   Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$URI,

        [Parameter(Mandatory = $false)]
        [switch]$SkipCertificateCheck,

        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 65535)]
        [uint16]$TimeoutSeconds = 30,

        [switch]$IgnoreCase,

        [ValidateSet('Exact', 'Wildcard', 'Regex')]
        [string]$MatchMode = 'Exact'
    )

    if (-not $Credential) {
        try {
            $Credential = Get-NBCredential -ErrorAction Stop
        } catch {
            # Credentials are not set... Try to obtain from the user
            if (-not ($Credential = Get-Credential -UserName 'username-not-applicable' -Message "Enter token for Netbox")) {
                throw "Token is necessary to connect to a Netbox API."
            }
        }
    }

    $invokeParams = @{ SkipCertificateCheck = $SkipCertificateCheck; }

    if ("Desktop" -eq $PSVersionTable.PsEdition) {
        #Remove -SkipCertificateCheck from Invoke Parameter (not supported <= PS 5)
        $invokeParams.remove("SkipCertificateCheck")
    }

    # Add AllowInsecureRedirect for PS 7.4+ only when SkipCertificateCheck is also enabled
    # This handles http:// redirects when connecting via https://, which some misconfigured
    # Netbox instances return. Only enabled when user has already accepted reduced security.
    $psVersion = $PSVersionTable.PSVersion
    if ($SkipCertificateCheck -and $psVersion -ge [version]'7.4') {
        $invokeParams['AllowInsecureRedirect'] = $true
        Write-Warning "AllowInsecureRedirect enabled alongside SkipCertificateCheck. HTTP redirects from HTTPS will be followed."
    }

    # For PowerShell Desktop (5.1), configure TLS and certificate handling
    if ("Desktop" -eq $PSVersionTable.PsEdition) {
        # Enable modern TLS protocols
        Set-NBCipherSSL
        if ($SkipCertificateCheck) {
            # Disable SSL certificate validation
            Set-NBuntrustedSSL
        }
    }

    switch ($PSCmdlet.ParameterSetName) {
        'Manual' {
            $uriBuilder = [System.UriBuilder]::new($Scheme, $Hostname, $Port)
        }

        'URI' {
            $uriBuilder = [System.UriBuilder]::new($URI)
            if ([string]::IsNullOrWhiteSpace($uriBuilder.Host)) {
                throw "URI appears to be invalid. Must be in format [host.name], [scheme://host.name], or [scheme://host.name:port]"
            }
        }
    }

    if ($uriBuilder.Scheme -eq 'http') {
        Write-Warning "Connecting via HTTP. Your API token will be transmitted in plaintext. Use HTTPS in production."
    }

    $null = Set-NBHostName -Hostname $uriBuilder.Host
    $null = Set-NBCredential -Credential $Credential
    $null = Set-NBHostScheme -Scheme $uriBuilder.Scheme
    $null = Set-NBHostPort -Port $uriBuilder.Port
    $null = Set-NBInvokeParams -invokeParams $invokeParams
    $null = Set-NBTimeout -TimeoutSeconds $TimeoutSeconds

    try {
        Write-Verbose "Verifying API connectivity..."
        $statusResponse = VerifyAPIConnectivity
    } catch {
        Write-Verbose "Failed to connect. Generating error"
        Write-Verbose $_.Exception.Message
        $script:NetboxConfig.Connected = $false
        if (($_.Exception.Response) -and ($_.Exception.Response.StatusCode -eq 403)) {
            throw "Invalid token"
        } else {
            throw $_
        }
    }

    # Reuse the status response from VerifyAPIConnectivity (avoids duplicate /api/status/ call)
    Write-Verbose "Checking Netbox version compatibility"
    $script:NetboxConfig.NetboxVersion = $statusResponse
    $versionString = $statusResponse.'netbox-version'
    $script:NetboxConfig.ParsedVersion = ConvertTo-NetboxVersion -VersionString $versionString

    if ($null -eq $script:NetboxConfig.ParsedVersion) {
        Write-Warning "Could not parse Netbox version '$versionString', assuming compatible"
    } elseif ($script:NetboxConfig.ParsedVersion -lt [version]'4.3') {
        # Reset config state on incompatible version
        SetupNetboxConfigVariable -Overwrite
        throw "Netbox version is incompatible with this PS module. Requires >=4.3, found version $versionString"
    } else {
        Write-Verbose "Found compatible version [$versionString] (parsed: $($script:NetboxConfig.ParsedVersion))!"
    }

    $script:NetboxConfig.Connected = $true
    Write-Verbose "Successfully connected!"

    # A new connection starts with a clean deprecation slate, so each deprecation warning is
    # reported once per connection rather than once per process.
    $script:NetboxConfig.DeprecationWarned = @{}

    # v1 (legacy) tokens are deprecated as of Netbox 4.6 and removed in Netbox 5.0. The
    # 'nbt_' discriminator is the same one Get-NBRequestHeaders uses to pick the auth scheme.
    if (($null -ne $script:NetboxConfig.ParsedVersion) -and ($script:NetboxConfig.ParsedVersion -ge [version]'4.6')) {
        $tokenValue = $script:NetboxConfig.Credential.GetNetworkCredential().Password
        if ($tokenValue -notmatch '^nbt_') {
            Write-Warning ("This connection uses a legacy (v1) API token. v1 tokens are deprecated as of " +
                "Netbox 4.6 and will be removed in Netbox 5.0. Create a v2 token under Users > API Tokens " +
                "in the Netbox UI and reconnect. See https://netboxlabs.com/docs/netbox/models/users/token/")
        }
    }

    # This needs a valid ParsedVersion to work, so it must be called after the version check
    $null = Set-NBQueryOption -IgnoreCase:$IgnoreCase
    $null = Set-NBQueryOption -MatchMode $MatchMode


    Write-Verbose "Connection process completed"
}