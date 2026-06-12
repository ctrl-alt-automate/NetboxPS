<#
.SYNOPSIS
    Shared AST logic for the comment-based-help parameter-parity guardrail.

.DESCRIPTION
    Single source of truth used by BOTH the Pester gate in CodeQuality.Tests.ps1
    and the baseline regenerator below. Keeping the logic here (rather than
    duplicating it in the test and a separate script) prevents drift between
    "what the test checks" and "what the baseline records".

    For every PUBLIC function (name contains '-') under Functions/, it compares
    the declared param() parameters against the .PARAMETER entries in the
    function's comment-based help, and reports two kinds of violation:
      - Missing : a declared parameter has no .PARAMETER help entry
      - Orphan  : a .PARAMETER help entry names a parameter that doesn't exist

    Internal helpers (file/function names without a hyphen, e.g. BuildNewURI)
    are intentionally out of scope -- the public API is what we hold to the bar.

    Comparison is case-insensitive (PowerShell's comment-based help stores
    .PARAMETER names upper-cased), matching how PowerShell itself resolves help.

.NOTES
    Introduced with the param<->.PARAMETER parity guardrail. PS 5.1 compatible
    (no PS7-only syntax) so it runs on every CI matrix leg.
#>

function Get-NBParamHelpParityViolation {
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[object]])]
    param(
        # Root Functions/ directory. Defaults to ../Functions relative to this file.
        [string]$FunctionsPath = (Join-Path (Split-Path $PSScriptRoot -Parent) 'Functions')
    )

    $FunctionsPath = (Resolve-Path -LiteralPath $FunctionsPath).Path
    $violations = [System.Collections.Generic.List[object]]::new()

    $files = Get-ChildItem -Path $FunctionsPath -Recurse -Filter '*.ps1' |
        Where-Object { $_.BaseName -notlike '_*' } | Sort-Object FullName

    foreach ($file in $files) {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$null)
        $func = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) |
            Select-Object -First 1
        if (-not $func) { continue }

        # Public API only: function name must contain a hyphen (Verb-NBNoun).
        if ($func.Name -notmatch '-') { continue }

        $paramBlock = $func.Body.ParamBlock
        if (-not $paramBlock -or $paramBlock.Parameters.Count -eq 0) { continue }
        $declared = @($paramBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath })

        $help = $func.GetHelpContent()
        if (-not $help) { $help = $ast.GetHelpContent() }
        # No help block at all on a public function is itself a gap -> every param is Missing.
        $documented = if ($help) { @($help.Parameters.Keys) } else { @() }

        foreach ($p in $declared) {
            if ($documented -notcontains $p) {
                $violations.Add([pscustomobject]@{ Function = $func.Name; Param = $p; Kind = 'Missing'; File = $file.Name })
            }
        }
        foreach ($d in $documented) {
            if ($declared -notcontains $d) {
                $violations.Add([pscustomobject]@{ Function = $func.Name; Param = $d; Kind = 'Orphan'; File = $file.Name })
            }
        }
    }

    # Return as a plain array so the pipeline/@() enumerates individual violations
    # (returning the List itself, or ",$List", makes callers see one opaque object).
    return $violations.ToArray()
}

function ConvertTo-NBParamHelpKey {
    # Canonical, case-insensitive key for matching a violation against the baseline.
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Violation)
    return ('{0}::{1}::{2}' -f $Violation.Function, $Violation.Param, $Violation.Kind).ToLowerInvariant()
}

function Get-NBParamHelpExemption {
    # Reads the baseline exemptions file into a case-insensitive lookup hashtable.
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)
    $set = @{}
    if (-not (Test-Path -LiteralPath $Path)) { return $set }
    foreach ($line in (Get-Content -LiteralPath $Path)) {
        $trimmed = $line.Trim()
        if ($trimmed.Length -eq 0 -or $trimmed.StartsWith('#')) { continue }
        $set[$trimmed.ToLowerInvariant()] = $true
    }
    return $set
}
