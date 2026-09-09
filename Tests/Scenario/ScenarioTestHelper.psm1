#
# ScenarioTestHelper.psm1
#
# Shared utilities for PowerNetbox Scenario Tests.
# Manages test data import/cleanup using the TestData Python scripts.
#

# Module-scope variables
$script:TestDataPath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) ".." | Join-Path -ChildPath "TestData"

# Test environments = the local Docker stacks started with scripts/Start-NetboxDocker.ps1
# (same matrix as CI). Host/port/token per version are fixed there; NETBOX_<ver>_HOST /
# NETBOX_<ver>_TOKEN environment variables override them (Start-NetboxDocker -SetEnvironment
# exports exactly those). 'custom' uses NETBOX_HOST / NETBOX_TOKEN / NETBOX_SCHEME as-is.
$script:V1Token = '0123456789abcdef0123456789abcdef01234567'
$script:V2Token = "nbt_powernetbox1.$($script:V1Token)"   # netbox-docker 5.0.2+ deterministic v2 token

function script:New-DockerEnvironment([string]$key, [int]$port, [string]$defaultToken) {
    $envKey = $key -replace '\.', ''
    $host  = [System.Environment]::GetEnvironmentVariable("NETBOX_${envKey}_HOST")
    $token = [System.Environment]::GetEnvironmentVariable("NETBOX_${envKey}_TOKEN")
    @{
        Hostname = if ($host) { $host } else { "localhost:$port" }
        Token    = if ($token) { $token } else { $defaultToken }
        Scheme   = 'http'
    }
}

$script:TestEnvironments = @{
    '4.7.0'  = New-DockerEnvironment '4.7.0'  8000 $script:V2Token
    '4.6.10' = New-DockerEnvironment '4.6.10' 8001 $script:V2Token
    '4.5.10' = New-DockerEnvironment '4.5.10' 8002 $null      # random-key v2 token: Start-NetboxDocker exports NETBOX_4510_TOKEN
    '4.4.10' = New-DockerEnvironment '4.4.10' 8003 $script:V1Token
    '4.3.7'  = New-DockerEnvironment '4.3.7'  8004 $script:V1Token
    'custom' = @{
        Hostname = $env:NETBOX_HOST
        Token    = $env:NETBOX_TOKEN
        Scheme   = if ($env:NETBOX_SCHEME) { $env:NETBOX_SCHEME } else { 'https' }
    }
}

# Current test session state
$script:CurrentEnvironment = $null
$script:TestDataImported = $false

function Get-ScenarioTestDataPath {
    <#
    .SYNOPSIS
        Returns the path to the TestData directory.
    #>
    return $script:TestDataPath
}

function Get-ScenarioEnvironments {
    <#
    .SYNOPSIS
        Returns available test environments.
    #>
    return $script:TestEnvironments.Keys
}

function Connect-ScenarioTest {
    <#
    .SYNOPSIS
        Connects to a Netbox test environment for scenario testing.

    .PARAMETER Environment
        The Netbox version to connect to (4.7.0, 4.6.10, 4.5.10, 4.4.10, 4.3.7) - a local Docker
        stack from scripts/Start-NetboxDocker.ps1 - or 'custom' (NETBOX_HOST / NETBOX_TOKEN).

    .EXAMPLE
        Connect-ScenarioTest -Environment '4.7.0'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('4.7.0', '4.6.10', '4.5.10', '4.4.10', '4.3.7', 'custom')]
        [string]$Environment
    )

    $config = $script:TestEnvironments[$Environment]
    if (-not $config) {
        throw "Environment '$Environment' not found"
    }

    # Validate we know where to connect
    if (-not $config.Hostname -or -not $config.Token) {
        $envPrefix = if ($Environment -eq 'custom') { 'NETBOX' } else { "NETBOX_$($Environment -replace '\.', '')" }
        throw "No host/token for environment '$Environment'. Start it with ./scripts/Start-NetboxDocker.ps1 -Version $Environment -SetEnvironment (exports ${envPrefix}_HOST and ${envPrefix}_TOKEN)."
    }

    $secureToken = ConvertTo-SecureString -String $config.Token -AsPlainText -Force
    $credential = [PSCredential]::new('api', $secureToken)

    $hostName, $hostPort = $config.Hostname -split ':', 2
    $connectParams = @{
        Hostname             = $hostName
        Credential           = $credential
        Scheme               = $config.Scheme
        SkipCertificateCheck = ($config.Scheme -eq 'https')
    }
    if ($hostPort) { $connectParams.Port = [int]$hostPort }

    Connect-NBAPI @connectParams

    # Verify connection
    $version = Get-NBVersion
    if (-not $version) {
        throw "Failed to connect to Netbox $Environment"
    }

    $script:CurrentEnvironment = $Environment
    Write-Verbose "Connected to Netbox $($version.'netbox-version') ($Environment)"

    return $version
}

function Import-ScenarioTestData {
    <#
    .SYNOPSIS
        Imports test data to the current Netbox environment using the Python import script.

    .PARAMETER Environment
        The Netbox version to import data to. Defaults to current environment.

    .PARAMETER Force
        Skip confirmation and cleanup before import.

    .EXAMPLE
        Import-ScenarioTestData -Environment '4.7.0'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [ValidateSet('4.7.0', '4.6.10', '4.5.10', '4.4.10', '4.3.7', 'custom')]
        [string]$Environment = $script:CurrentEnvironment,

        [switch]$Force
    )

    if (-not $Environment) {
        throw "No environment specified. Use Connect-ScenarioTest first or provide -Environment"
    }

    $importScript = Join-Path $script:TestDataPath "import_testdata.py"
    if (-not (Test-Path $importScript)) {
        throw "Import script not found: $importScript"
    }

    # Clean up first if Force is specified
    if ($Force) {
        Remove-ScenarioTestData -Environment $Environment -Confirm:$false
    }

    if ($PSCmdlet.ShouldProcess("Netbox $Environment", "Import test data")) {
        Push-Location $script:TestDataPath
        try {
            $result = python3 $importScript $Environment 2>&1
            $exitCode = $LASTEXITCODE

            if ($exitCode -ne 0) {
                Write-Warning "Import script returned exit code $exitCode"
                Write-Warning ($result -join "`n")
                return $false
            }

            Write-Verbose ($result -join "`n")
            $script:TestDataImported = $true
            return $true
        }
        finally {
            Pop-Location
        }
    }
}

function Remove-ScenarioTestData {
    <#
    .SYNOPSIS
        Removes all PNB-Test data from the current Netbox environment.

    .PARAMETER Environment
        The Netbox version to clean up. Defaults to current environment.

    .EXAMPLE
        Remove-ScenarioTestData -Environment '4.7.0'
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [ValidateSet('4.7.0', '4.6.10', '4.5.10', '4.4.10', '4.3.7', 'custom')]
        [string]$Environment = $script:CurrentEnvironment
    )

    if (-not $Environment) {
        throw "No environment specified. Use Connect-ScenarioTest first or provide -Environment"
    }

    $cleanupScript = Join-Path $script:TestDataPath "cleanup_testdata.py"
    if (-not (Test-Path $cleanupScript)) {
        throw "Cleanup script not found: $cleanupScript"
    }

    if ($PSCmdlet.ShouldProcess("Netbox $Environment", "Remove all PNB-Test data")) {
        Push-Location $script:TestDataPath
        try {
            $result = python3 $cleanupScript $Environment 2>&1
            $exitCode = $LASTEXITCODE

            if ($exitCode -ne 0) {
                Write-Warning "Cleanup script returned exit code $exitCode"
                Write-Warning ($result -join "`n")
                return $false
            }

            Write-Verbose ($result -join "`n")
            $script:TestDataImported = $false
            return $true
        }
        finally {
            Pop-Location
        }
    }
}

function Test-ScenarioTestData {
    <#
    .SYNOPSIS
        Checks if test data is present in the current Netbox environment.

    .DESCRIPTION
        Looks for PNB-Test prefixed objects to verify test data exists.
        Uses Query parameter for partial matching (wildcards don't work with Name parameter).
    #>
    [CmdletBinding()]
    param()

    $prefix = Get-TestPrefix

    # Check for test sites using Query (supports partial matching)
    $sites = Get-NBDCIMSite -Query $prefix -Limit 1
    if ($sites) {
        return $true
    }

    # Check for test tenants using Query
    $tenants = Get-NBTenant -Query $prefix -Limit 1
    if ($tenants) {
        return $true
    }

    return $false
}

function Get-TestPrefix {
    <#
    .SYNOPSIS
        Returns the test object prefix used by scenario tests.
    #>
    return "PNB-Test"
}

function Assert-ScenarioTestDataExists {
    <#
    .SYNOPSIS
        Ensures test data exists, importing if necessary.

    .PARAMETER Environment
        The Netbox version to check/import.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('4.7.0', '4.6.10', '4.5.10', '4.4.10', '4.3.7', 'custom')]
        [string]$Environment
    )

    # Connect if not already connected
    if ($script:CurrentEnvironment -ne $Environment) {
        Connect-ScenarioTest -Environment $Environment
    }

    # Check if data exists
    if (-not (Test-ScenarioTestData)) {
        Write-Verbose "Test data not found, importing..."
        Import-ScenarioTestData -Environment $Environment -Force
    }

    # Verify import succeeded
    if (-not (Test-ScenarioTestData)) {
        throw "Failed to verify test data exists after import"
    }

    return $true
}

# Helper function to get test objects by type
function Get-ScenarioTestObjects {
    <#
    .SYNOPSIS
        Gets test objects of a specific type.

    .PARAMETER ObjectType
        The type of objects to retrieve (e.g., 'Site', 'Device', 'Prefix').

    .DESCRIPTION
        Uses Query parameter for functions that support it (most do).
        Falls back to client-side filtering with Where-Object for functions
        that don't have Query or need more complex matching.

    .EXAMPLE
        Get-ScenarioTestObjects -ObjectType 'Device'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet(
            'Site', 'Device', 'DeviceType', 'DeviceRole', 'Manufacturer', 'Platform',
            'Rack', 'RackRole', 'RackType', 'Location', 'Region', 'SiteGroup',
            'Interface', 'Cable', 'FrontPort', 'RearPort',
            'Prefix', 'Address', 'VLAN', 'VLANGroup', 'VRF', 'Aggregate', 'RIR', 'Role',
            'Tenant', 'TenantGroup', 'Contact', 'ContactRole',
            'VirtualMachine', 'Cluster', 'ClusterType', 'ClusterGroup', 'VMInterface',
            'Circuit', 'Provider', 'CircuitType',
            'Tunnel', 'TunnelGroup', 'L2VPN', 'IKEPolicy', 'IPSecPolicy', 'IPSecProfile',
            'WirelessLAN', 'WirelessLANGroup',
            'Tag', 'CustomField', 'Webhook', 'ConfigContext'
        )]
        [string]$ObjectType
    )

    $prefix = Get-TestPrefix

    switch ($ObjectType) {
        # DCIM - most use Query parameter for partial matching
        'Site'          { Get-NBDCIMSite -Query $prefix }
        'Device'        { Get-NBDCIMDevice -Query $prefix }
        'DeviceType'    { Get-NBDCIMDeviceType -Query $prefix }
        'DeviceRole'    { Get-NBDCIMDeviceRole -All | Where-Object { $_.name -like "$prefix*" } }
        'Manufacturer'  { Get-NBDCIMManufacturer -Query $prefix }
        'Platform'      { Get-NBDCIMPlatform -All | Where-Object { $_.name -like "$prefix*" } }
        'Rack'          { Get-NBDCIMRack -Query $prefix }
        'RackRole'      { Get-NBDCIMRackRole -Query $prefix }
        'RackType'      { Get-NBDCIMRackType -Query $prefix }
        'Location'      { Get-NBDCIMLocation -Query $prefix }
        'Region'        { Get-NBDCIMRegion -Query $prefix }
        'SiteGroup'     { Get-NBDCIMSiteGroup -Query $prefix }
        'Interface'     { Get-NBDCIMInterface -All | Where-Object { $_.device.name -like "$prefix*" } }
        'Cable'         { Get-NBDCIMCable -All | Where-Object { $_.description -like "*$prefix*" -or ($_.a_terminations -and $_.a_terminations[0].object.device.name -like "$prefix*") } }
        'FrontPort'     { Get-NBDCIMFrontPort -All | Where-Object { $_.device.name -like "$prefix*" } }
        'RearPort'      { Get-NBDCIMRearPort -All | Where-Object { $_.device.name -like "$prefix*" } }

        # IPAM - use Query parameter
        'Prefix'        { Get-NBIPAMPrefix -Query $prefix }
        'Address'       { Get-NBIPAMAddress -Query $prefix }
        'VLAN'          { Get-NBIPAMVLAN -Query $prefix }
        'VLANGroup'     { Get-NBIPAMVLANGroup -Query $prefix }
        'VRF'           { Get-NBIPAMVRF -Query $prefix }
        'Aggregate'     { Get-NBIPAMAggregate -Query $prefix }
        'RIR'           { Get-NBIPAMRIR -Query $prefix }
        'Role'          { Get-NBIPAMRole -Query $prefix }

        # Tenancy
        'Tenant'        { Get-NBTenant -Query $prefix }
        'TenantGroup'   { Get-NBTenantGroup -Query $prefix }
        'Contact'       { Get-NBContact -Query $prefix }
        'ContactRole'   { Get-NBContactRole -Query $prefix }

        # Virtualization
        'VirtualMachine' { Get-NBVirtualMachine -Query $prefix }
        'Cluster'        { Get-NBVirtualizationCluster -Query $prefix }
        'ClusterType'    { Get-NBVirtualizationClusterType -Query $prefix }
        'ClusterGroup'   { Get-NBVirtualizationClusterGroup -Query $prefix }
        'VMInterface'    { Get-NBVirtualMachineInterface -Query $prefix }

        # Circuits
        'Circuit'       { Get-NBCircuit -Query $prefix }
        'Provider'      { Get-NBCircuitProvider -Query $prefix }
        'CircuitType'   { Get-NBCircuitType -Query $prefix }

        # VPN
        'Tunnel'        { Get-NBVPNTunnel -Query $prefix }
        'TunnelGroup'   { Get-NBVPNTunnelGroup -All | Where-Object { $_.name -like "$prefix*" } }
        'L2VPN'         { Get-NBVPNL2VPN -All | Where-Object { $_.name -like "$prefix*" } }
        'IKEPolicy'     { Get-NBVPNIKEPolicy -All | Where-Object { $_.name -like "$prefix*" } }
        'IPSecPolicy'   { Get-NBVPNIPSecPolicy -All | Where-Object { $_.name -like "$prefix*" } }
        'IPSecProfile'  { Get-NBVPNIPSecProfile -All | Where-Object { $_.name -like "$prefix*" } }

        # Wireless
        'WirelessLAN'      { Get-NBWirelessLAN -All | Where-Object { $_.ssid -like "$prefix*" } }
        'WirelessLANGroup' { Get-NBWirelessLANGroup -All | Where-Object { $_.name -like "$prefix*" } }

        # Extras
        'Tag'           { Get-NBTag -All | Where-Object { $_.name -like "$prefix*" } }
        'CustomField'   { Get-NBCustomField -Query $prefix }
        'Webhook'       { Get-NBWebhook -Query $prefix }
        'ConfigContext' { Get-NBConfigContext -Query $prefix }

        default { throw "Unknown object type: $ObjectType" }
    }
}

# Export module functions
Export-ModuleMember -Function @(
    'Get-ScenarioTestDataPath',
    'Get-ScenarioEnvironments',
    'Connect-ScenarioTest',
    'Import-ScenarioTestData',
    'Remove-ScenarioTestData',
    'Test-ScenarioTestData',
    'Get-TestPrefix',
    'Assert-ScenarioTestDataExists',
    'Get-ScenarioTestObjects'
)
