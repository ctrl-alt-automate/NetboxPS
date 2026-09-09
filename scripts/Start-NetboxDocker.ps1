<#
.SYNOPSIS
    Starts (or stops / inspects) a local NetBox Docker stack for one supported NetBox version.
.DESCRIPTION
    Single source of truth for local live testing. Every supported NetBox version gets its own
    docker compose project, image tag, host port and API token, so several versions can run side
    by side (the same matrix CI uses, see .github/workflows/integration.yml):

      Version   Image tag           Port   Token (netbox-docker generation)
      4.7.0     v4.7.0-5.1.0        8000   nbt_powernetbox1.<40 hex>   (5.x: SUPERUSER_API_KEY + _TOKEN -> v2)
      4.6.10    v4.6.10-5.0.2       8001   nbt_powernetbox1.<40 hex>
      4.5.10    v4.5.10-4.0.2       8002   v2 token with a random key -> created via manage.py shell
      4.4.10    v4.4.10-3.4.2       8003   0123456789abcdef0123456789abcdef01234567 (v1)
      4.3.7     v4.3.7-3.3.0        8004   0123456789abcdef0123456789abcdef01234567 (v1)

    The script waits until the API answers, resolves the token, and returns an object with Host,
    Token, Scheme, Version, Port and Project. With -SetEnvironment it also exports NETBOX_HOST /
    NETBOX_TOKEN / NETBOX_SCHEME for the Live-tagged Pester tests, and NETBOX_<ver>_HOST/_TOKEN
    (e.g. NETBOX_470_HOST) for the Scenario tests.

    IMPORTANT: docker compose falls back to its default image tag when NETBOX_VERSION is not set,
    and then RECREATES the netbox container on the wrong release. This script always sets it; if
    you run compose by hand for one of these projects, pass NETBOX_VERSION=<tag> every time.
.PARAMETER Version
    NetBox version key: 4.7.0, 4.6.10, 4.5.10, 4.4.10 or 4.3.7.
.PARAMETER Worker
    Also start the optional RQ worker (compose profile 'worker'). Needed for NetBox 4.7
    background bulk writes (?background=true) and other background jobs.
.PARAMETER Down
    Stop and remove the stack (including volumes) instead of starting it.
.PARAMETER Status
    Only report whether the stack is running and return its connection object; do not start it.
.PARAMETER SetEnvironment
    Export NETBOX_HOST / NETBOX_TOKEN / NETBOX_SCHEME (and NETBOX_<ver>_HOST/_TOKEN) in the
    current session.
.PARAMETER TimeoutSeconds
    How long to wait for the API to come up (first boot runs migrations). Default 600.
.EXAMPLE
    ./scripts/Start-NetboxDocker.ps1 -Version 4.7.0 -Worker -SetEnvironment
    Invoke-Pester ./Tests/Integration.Tests.ps1 -Tag Live
.EXAMPLE
    $nb = ./scripts/Start-NetboxDocker.ps1 -Version 4.3.7
    $cred = [PSCredential]::new('api', (ConvertTo-SecureString $nb.Token -AsPlainText -Force))
    Connect-NBAPI -Hostname localhost -Port $nb.Port -Scheme http -Credential $cred
.EXAMPLE
    ./scripts/Start-NetboxDocker.ps1 -Version 4.7.0 -Down
.NOTES
    Requires Docker Desktop (or another Docker engine) to be running and the compose plugin.
    Uses docker-compose.ci.yml from the repository root plus a generated port override in the
    system temp directory.
#>
[CmdletBinding(DefaultParameterSetName = 'Up')]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('4.7.0', '4.6.10', '4.5.10', '4.4.10', '4.3.7')]
    [string]$Version,

    [Parameter(ParameterSetName = 'Up')]
    [switch]$Worker,

    [Parameter(ParameterSetName = 'Down')]
    [switch]$Down,

    [Parameter(ParameterSetName = 'Status')]
    [switch]$Status,

    [Parameter(ParameterSetName = 'Up')]
    [Parameter(ParameterSetName = 'Status')]
    [switch]$SetEnvironment,

    [Parameter(ParameterSetName = 'Up')]
    [ValidateRange(30, 3600)]
    [int]$TimeoutSeconds = 600
)

$ErrorActionPreference = 'Stop'

$v1Token = '0123456789abcdef0123456789abcdef01234567'
$v2Token = "nbt_powernetbox1.$v1Token"   # SUPERUSER_API_KEY 'powernetbox1' + SUPERUSER_API_TOKEN, netbox-docker 5.0.2+

$matrix = @{
    '4.7.0'  = @{ Image = 'v4.7.0-5.1.0';  Port = 8000; Token = $v2Token; TokenSource = 'deterministic-v2' }
    '4.6.10' = @{ Image = 'v4.6.10-5.0.2'; Port = 8001; Token = $v2Token; TokenSource = 'deterministic-v2' }
    '4.5.10' = @{ Image = 'v4.5.10-4.0.2'; Port = 8002; Token = $null;    TokenSource = 'create-v2' }
    '4.4.10' = @{ Image = 'v4.4.10-3.4.2'; Port = 8003; Token = $v1Token; TokenSource = 'v1' }
    '4.3.7'  = @{ Image = 'v4.3.7-3.3.0';  Port = 8004; Token = $v1Token; TokenSource = 'v1' }
}

$entry   = $matrix[$Version]
$project = "pn-$($Version -replace '\.', '')"
$repoRoot = Split-Path $PSScriptRoot -Parent
$compose  = Join-Path $repoRoot 'docker-compose.ci.yml'
if (-not (Test-Path $compose)) { throw "docker-compose.ci.yml not found at $compose" }

$override = Join-Path ([System.IO.Path]::GetTempPath()) "powernetbox-$project-override.yml"
@"
services:
  netbox:
    ports: !override
      - "$($entry.Port):8080"
"@ | Set-Content -Path $override -Encoding ascii

$env:NETBOX_VERSION = $entry.Image
$composeArgs = @('compose', '-p', $project, '-f', $compose, '-f', $override)
if ($Worker) { $composeArgs += @('--profile', 'worker') }

function Get-ContainerHealth {
    $name = "$project-netbox-1"
    $out = docker inspect $name --format '{{.State.Status}} {{if .State.Health}}{{.State.Health.Status}}{{end}}' 2>$null
    if ($LASTEXITCODE -ne 0) { return $null }
    return $out.Trim()
}

function Resolve-Token {
    if ($entry.TokenSource -ne 'create-v2') { return $entry.Token }
    # netbox-docker 4.0.x creates a v2 token with a random key; mint a deterministic-enough one via Django.
    $py = @'
from users.models import Token
from django.contrib.auth import get_user_model
u = get_user_model().objects.get(username='admin')
t = Token(user=u, description='powernetbox-local')
s = Token.generate()
t.token = s
t.save()
print(f'nbt_{t.key}.{s}')
'@
    $out = docker exec "$project-netbox-1" /opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py shell -c $py 2>$null
    $tok = @($out | Where-Object { $_ -match '^nbt_' })[0]
    if (-not $tok) { throw "Could not create a v2 token in $project-netbox-1: $($out -join ' ')" }
    return $tok
}

function New-ConnectionObject([string]$token) {
    [PSCustomObject]@{
        Version = $Version
        Image   = $entry.Image
        Project = $project
        Port    = $entry.Port
        Host    = "localhost:$($entry.Port)"
        Scheme  = 'http'
        Token   = $token
    }
}

function Set-ConnectionEnvironment($conn) {
    $env:NETBOX_HOST   = $conn.Host
    $env:NETBOX_TOKEN  = $conn.Token
    $env:NETBOX_SCHEME = $conn.Scheme
    $key = $Version -replace '\.', ''
    Set-Item -Path "env:NETBOX_${key}_HOST"  -Value $conn.Host
    Set-Item -Path "env:NETBOX_${key}_TOKEN" -Value $conn.Token
    Write-Host "Exported NETBOX_HOST=$($conn.Host) NETBOX_SCHEME=http NETBOX_TOKEN=<set> (and NETBOX_${key}_HOST/_TOKEN)" -ForegroundColor Green
}

switch ($PSCmdlet.ParameterSetName) {
    'Down' {
        Write-Host "Stopping $project ($($entry.Image))..." -ForegroundColor Cyan
        & docker @composeArgs --profile worker down -v 2>&1 | ForEach-Object { Write-Verbose $_ }
        Remove-Item $override -ErrorAction SilentlyContinue
        return
    }
    'Status' {
        $health = Get-ContainerHealth
        if (-not $health) { Write-Host "$project ($Version) is not running" -ForegroundColor Yellow; return $null }
        Write-Host "$project ($Version): $health" -ForegroundColor Cyan
        $tokenFile = Join-Path ([System.IO.Path]::GetTempPath()) "powernetbox-$project-token.txt"
        $token = if ($entry.Token) { $entry.Token } elseif (Test-Path $tokenFile) { (Get-Content $tokenFile -Raw).Trim() } else { $null }
        $conn = New-ConnectionObject $token
        if ($SetEnvironment -and $token) { Set-ConnectionEnvironment $conn }
        return $conn
    }
}

Write-Host "Starting NetBox $Version ($($entry.Image)) as project '$project' on http://localhost:$($entry.Port) ..." -ForegroundColor Cyan
& docker @composeArgs up -d 2>&1 | ForEach-Object { Write-Verbose $_ }
if ($LASTEXITCODE -ne 0) { throw "docker compose up failed for $project" }

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$ready = $false
while ((Get-Date) -lt $deadline) {
    $health = Get-ContainerHealth
    if ($health -match 'healthy') {
        try {
            $probe = Invoke-WebRequest -Uri "http://localhost:$($entry.Port)/login/" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
            if ($probe.StatusCode -eq 200) { $ready = $true; break }
        }
        catch { }
    }
    Start-Sleep -Seconds 5
}
if (-not $ready) {
    docker logs "$project-netbox-1" --tail 40 2>&1 | ForEach-Object { Write-Warning $_ }
    throw "NetBox $Version did not become healthy within $TimeoutSeconds seconds"
}

$tokenFile = Join-Path ([System.IO.Path]::GetTempPath()) "powernetbox-$project-token.txt"
$token = if ($entry.Token) { $entry.Token } elseif (Test-Path $tokenFile) { (Get-Content $tokenFile -Raw).Trim() } else { $null }
if (-not $token) {
    $token = Resolve-Token
    Set-Content -Path $tokenFile -Value $token -Encoding ascii
}

# Final check: the token must actually authenticate (catches a stale token file after `-Down`)
$authHeader = if ($token -like 'nbt_*') { "Bearer $token" } else { "Token $token" }
try {
    $apiStatus = Invoke-RestMethod -Uri "http://localhost:$($entry.Port)/api/status/" -Headers @{ Authorization = $authHeader } -TimeoutSec 10
}
catch {
    if ($entry.TokenSource -eq 'create-v2') {
        $token = Resolve-Token
        Set-Content -Path $tokenFile -Value $token -Encoding ascii
        $apiStatus = Invoke-RestMethod -Uri "http://localhost:$($entry.Port)/api/status/" -Headers @{ Authorization = "Bearer $token" } -TimeoutSec 10
    }
    else { throw }
}
Write-Host "NetBox $($apiStatus.'netbox-version') is up on http://localhost:$($entry.Port) (token: $($entry.TokenSource))" -ForegroundColor Green

$conn = New-ConnectionObject $token
if ($SetEnvironment) { Set-ConnectionEnvironment $conn }
return $conn
