#Requires -Version 7
<#
.SYNOPSIS
    Run a Pester test set against every supported NetBox version on local Docker.
.DESCRIPTION
    For each version in the matrix, starts (or reuses) the local Docker stack via
    scripts/Start-NetboxDocker.ps1, exports NETBOX_HOST / NETBOX_TOKEN / NETBOX_SCHEME, runs the
    requested tests, and prints a summary table. This is the local equivalent of the CI
    integration matrix (.github/workflows/integration.yml).
.PARAMETER TestPath
    Pester test file(s) to run. Default: ./Tests/Integration.Tests.ps1
.PARAMETER Tag
    Pester tag filter. Default: 'Live'
.PARAMETER Versions
    NetBox versions to test. Default: the full matrix (4.7.0, 4.6.10, 4.5.10, 4.4.10, 4.3.7).
.PARAMETER Worker
    Also start the RQ worker profile (NetBox 4.7 background jobs).
.PARAMETER TearDown
    Remove each stack (including volumes) after its tests.
.PARAMETER StopOnFailure
    Stop after the first version with failing tests.
.EXAMPLE
    ./scripts/Test-AllNetboxVersions.ps1
.EXAMPLE
    ./scripts/Test-AllNetboxVersions.ps1 -Versions 4.7.0, 4.3.7 -TestPath ./Tests/BulkOperations.Tests.ps1
.EXAMPLE
    ./scripts/Test-AllNetboxVersions.ps1 -TearDown
#>
[CmdletBinding()]
param(
    [string[]]$TestPath = @('./Tests/Integration.Tests.ps1'),
    [string]$Tag = 'Live',
    [ValidateSet('4.7.0', '4.6.10', '4.5.10', '4.4.10', '4.3.7')]
    [string[]]$Versions = @('4.7.0', '4.6.10', '4.5.10', '4.4.10', '4.3.7'),
    [switch]$Worker,
    [switch]$TearDown,
    [switch]$StopOnFailure
)

$ErrorActionPreference = 'Continue'
$starter = Join-Path $PSScriptRoot 'Start-NetboxDocker.ps1'
$results = @()

foreach ($version in $Versions) {
    Write-Host ""
    Write-Host "==================== NetBox $version ====================" -ForegroundColor Yellow
    $result = [PSCustomObject]@{
        Version       = $version
        ActualVersion = $null
        TestsPassed   = 0
        TestsFailed   = 0
        TestsSkipped  = 0
        Duration      = $null
        Error         = $null
    }
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $conn = & $starter -Version $version -Worker:$Worker -SetEnvironment
        $result.ActualVersion = $version

        $pester = Invoke-Pester -Path $TestPath -TagFilter $Tag -PassThru -Output Minimal
        $result.TestsPassed  = $pester.PassedCount
        $result.TestsFailed  = $pester.FailedCount
        $result.TestsSkipped = $pester.SkippedCount
        $color = if ($pester.FailedCount -gt 0) { 'Red' } else { 'Green' }
        Write-Host "  $version -> $($pester.PassedCount) passed, $($pester.FailedCount) failed, $($pester.SkippedCount) skipped" -ForegroundColor $color
        if ($pester.FailedCount -gt 0 -and $StopOnFailure) { throw "Tests failed on NetBox $version" }
    }
    catch {
        $result.Error = $_.Exception.Message
        Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
        if ($StopOnFailure) { $sw.Stop(); $result.Duration = $sw.Elapsed; $results += $result; break }
    }
    finally {
        if ($TearDown) { & $starter -Version $version -Down }
        $sw.Stop()
        $result.Duration = $sw.Elapsed
        $results += $result
    }
}

Write-Host ""
$results | Format-Table Version, TestsPassed, TestsFailed, TestsSkipped, @{ n = 'Duration'; e = { $_.Duration.ToString('mm\:ss') } }, Error -AutoSize
if ($results | Where-Object { $_.TestsFailed -gt 0 -or $_.Error }) { exit 1 }
