BeforeAll {
    . "$PSScriptRoot/common.ps1"

    # Get all public functions (those with a hyphen in the name)
    $script:PublicFunctions = Get-Command -Module PowerNetbox -CommandType Function |
        Where-Object { $_.Name -match '-' }
}

Describe "Code Quality Tests" -Tag 'Quality' {

    Context "CmdletBinding" {
        It "All public functions should have CmdletBinding" {
            $missing = $script:PublicFunctions | Where-Object {
                -not $_.CmdletBinding
            }
            $missing | Should -BeNullOrEmpty -Because "all public functions should use [CmdletBinding()]"
        }
    }

    Context "Approved Verbs" {
        It "All public functions should use approved verbs" {
            $approvedVerbs = (Get-Verb).Verb
            $badVerbs = $script:PublicFunctions | Where-Object {
                $_.Verb -notin $approvedVerbs
            }
            $badVerbs | Should -BeNullOrEmpty -Because "all public functions should use approved PowerShell verbs"
        }
    }

    Context "ShouldProcess" {
        It "State-changing functions should declare SupportsShouldProcess" {
            $stateChangingVerbs = @('New', 'Set', 'Remove')
            # Exclude Setup/config functions that don't change Netbox state
            $setupFunctions = @(
                'Set-NBCredential', 'Set-NBHostName', 'Set-NBHostPort',
                'Set-NBHostScheme', 'Set-NBInvokeParams', 'Set-NBTimeout',
                'Set-NBCipherSSL', 'Set-NBuntrustedSSL'
            )
            $stateChangingFunctions = $script:PublicFunctions | Where-Object {
                $_.Verb -in $stateChangingVerbs -and $_.Name -notin $setupFunctions
            }
            $missing = $stateChangingFunctions | Where-Object {
                'WhatIf' -notin $_.Parameters.Keys
            }
            $missing | Should -BeNullOrEmpty -Because "New/Set/Remove API functions should support ShouldProcess for -WhatIf/-Confirm"
        }
    }

    Context "Raw Parameter" {
        It "All API Get functions should have a -Raw parameter" {
            # Exclude Setup/config getters and internal helpers
            $excludedFunctions = @(
                'Get-NBCredential', 'Get-NBHostname', 'Get-NBHostPort',
                'Get-NBHostScheme', 'Get-NBInvokeParams', 'Get-NBTimeout',
                'Get-NBRequestHeaders', 'Get-NBVersion', 'Get-NBBranchContext',
                'Get-NBAPIDefinition'
            )
            $getFunctions = $script:PublicFunctions | Where-Object {
                $_.Verb -eq 'Get' -and $_.Name -notin $excludedFunctions
            }
            $missing = $getFunctions | Where-Object {
                'Raw' -notin $_.Parameters.Keys
            }
            $missing | Should -BeNullOrEmpty -Because "all API Get functions should support the -Raw switch"
        }
    }

    Context "Parameter Type Validation" {

        It "Get- function Id parameters should accept arrays (uint64[])" {
            $functionsPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'Functions'
            # Only check Get- functions - they should support array Id for batch queries
            # Set/Remove/other action functions operate on single resources
            $files = Get-ChildItem -Path $functionsPath -Filter "Get-*.ps1" -Recurse

            $violations = @()

            foreach ($file in $files) {
                $content = Get-Content $file.FullName -Raw

                # Check for non-array [uint64]$Id parameter declarations
                # This pattern matches [uint64]$Id followed by comma, whitespace, or newline
                if ($content -match '\[uint64\]\$Id[,\s\r\n]' -and $content -notmatch '\[uint64\[\]\]\$Id') {
                    $violations += $file.Name
                }
            }

            $violations | Should -BeNullOrEmpty -Because "Get- function Id parameters should use [uint64[]] to accept arrays. Violations: $($violations -join ', ')"
        }
    }

    Context "Function Definition Validation" {

        It "No duplicate function names should exist" {
            $functionsPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'Functions'
            $files = Get-ChildItem -Path $functionsPath -Filter "*.ps1" -Recurse

            $functionNames = @{}
            $duplicates = @()

            foreach ($file in $files) {
                $content = Get-Content $file.FullName -Raw

                # Extract function name using regex
                if ($content -match 'function\s+([\w-]+)\s*\{') {
                    $funcName = $Matches[1]

                    # Case-insensitive check (PowerShell functions are case-insensitive)
                    $funcNameLower = $funcName.ToLower()
                    if ($functionNames.ContainsKey($funcNameLower)) {
                        $duplicates += [PSCustomObject]@{
                            Name  = $funcName
                            File1 = $functionNames[$funcNameLower]
                            File2 = $file.Name
                        }
                    }
                    else {
                        $functionNames[$funcNameLower] = $file.Name
                    }
                }
            }

            $duplicates | Should -BeNullOrEmpty -Because "Each function should only be defined once"
        }
    }

    Context "Comment-based help parameter parity" {

        BeforeAll {
            . "$PSScriptRoot/ParamHelpParity.Helper.ps1"
            $baseline = Get-NBParamHelpExemption -Path (Join-Path $PSScriptRoot 'param-help-parity-baseline.txt')
            $newViolations = @(Get-NBParamHelpParityViolation | Where-Object {
                -not $baseline.ContainsKey((ConvertTo-NBParamHelpKey -Violation $_))
            })
            # Pre-format readable "Function -Param [Kind]" lines so a failure names the offenders.
            $script:NewParityStrings = @($newViolations | ForEach-Object {
                ('{0}  -{1}  [{2}]' -f $_.Function, $_.Param, $_.Kind)
            })
        }

        It "No NEW param() to .PARAMETER help gaps are introduced" {
            $script:NewParityStrings |
                Should -BeNullOrEmpty -Because 'every public function parameter needs a matching .PARAMETER help entry (and vice versa); add the help (Missing) or fix the .PARAMETER name (Orphan). Do NOT re-baseline a new finding. Regenerate the baseline only after reducing the backlog: pwsh -File ./Tests/Update-ParamHelpParityBaseline.ps1'
        }
    }
}
