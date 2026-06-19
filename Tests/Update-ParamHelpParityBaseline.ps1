<#
.SYNOPSIS
    Regenerates Tests/param-help-parity-baseline.txt from the current source tree.

.DESCRIPTION
    Snapshots the current set of param() <-> .PARAMETER help gaps so the CI gate
    in CodeQuality.Tests.ps1 only fails on NEW gaps. Run this ONLY after you have
    legitimately REDUCED the backlog (added missing .PARAMETER help or fixed a
    param name) -- it rewrites the baseline to match reality.

    Do NOT run this to silence a freshly-introduced gap. The correct fix for a new
    finding is to add the .PARAMETER help, not to re-baseline.

.EXAMPLE
    pwsh -NoProfile -File ./Tests/Update-ParamHelpParityBaseline.ps1
#>
[CmdletBinding()]
param(
    [string]$BaselinePath = (Join-Path $PSScriptRoot 'param-help-parity-baseline.txt')
)

. (Join-Path $PSScriptRoot 'ParamHelpParity.Helper.ps1')

$violations = Get-NBParamHelpParityViolation
$dataLines = $violations |
    ForEach-Object { '{0}::{1}::{2}' -f $_.Function, $_.Param, $_.Kind } |
    Sort-Object

$header = @'
# param() <-> .PARAMETER comment-based-help parity baseline
# =========================================================
# Format: <FunctionName>::<ParameterName>::<Missing|Orphan>
#   Missing = a declared parameter has no .PARAMETER help entry
#   Orphan  = a .PARAMETER help entry names a parameter that does not exist
# Lines starting with # and blank lines are ignored. Matching is case-insensitive.
#
# This file is the allow-list of KNOWN parity gaps. The CI gate in
# CodeQuality.Tests.ps1 (Context "Comment-based help parameter parity") fails on
# any gap NOT listed here. It is currently EMPTY -- every public function
# parameter has matching .PARAMETER help -- so the gate is fully enforced.
#
# Keep it empty: the fix for a new finding is to add the .PARAMETER help (or fix
# the param name), NOT to add a line here. Only regenerate after a deliberate,
# reviewed change to the known set:
#   pwsh -NoProfile -File ./Tests/Update-ParamHelpParityBaseline.ps1
# ---------------------------------------------------------------------------
'@

$content = $header + "`n" + ($dataLines -join "`n") + "`n"
Set-Content -Path $BaselinePath -Value $content -Encoding UTF8 -NoNewline

Write-Host ("Wrote {0} baseline entries to {1}" -f $dataLines.Count, $BaselinePath)
