---
name: new-netbox-endpoint
description: Use when adding or porting a PowerShell cmdlet that wraps a NetBox REST API endpoint in PowerNetbox — creating a Get-NB, New-NB, Set-NB, or Remove-NB function for a new or missing resource, touching a ValidateSet on an existing one, or writing the matching Pester tests.
---

# Adding a new NetBox endpoint to PowerNetbox

## Overview

Each NetBox endpoint maps to up to four cmdlets: `Get-NB*`, `New-NB*`,
`Set-NB*`, `Remove-NB*`. Each cmdlet is one file under
`Functions/<Module>/<Resource>/`, and all four share a consistent shape
driven by a central `InvokeNetboxRequest` + `BuildURIComponents` helpers.
The job of this skill is to make the fifth, fiftieth, and five-hundredth
endpoint look identical.

## When this applies

- NetBox ships a new API endpoint (e.g. new minor release adds `/api/dcim/<x>/`).
- An issue asks for a missing resource (pattern seen on #356, #362-#364, #383).
- A drift report from `scripts/Verify-ValidateSetParity.ps1` flags a new
  enum you want to expose.
- You are porting a cmdlet from community code (e.g. NetboxPS) to PowerNetbox conventions.

## Workflow (in order)

1. **Scope** — Is the endpoint read-only, read-write, or read-only-and-ephemeral (job-style)?
   That decides how many of the four cmdlets you need. Get-only is fine; you
   don't need `New`/`Set`/`Remove` if NetBox doesn't expose POST/PATCH/DELETE.
2. **Research** — skim the NetBox OpenAPI spec at
   `https://<host>/api/schema/` (or for dev: use
   `/.claude/commands/netbox-api.md` shorthand). Note every required field,
   every ChoiceSet, every pagination quirk.
3. **ValidateSet parity** — for every `ValidateSet` attribute you add,
   run `scripts/Verify-ValidateSetParity.ps1 -Function <Name>` against the
   NetBox version you target. Drift is the single most common bug class on
   this codebase (#360, #365, #385, #389, #392).
4. **Implement** — one file per cmdlet, copy from the templates below.
5. **Test** — one `Context "<cmdlet>"` per cmdlet in
   `Tests/<Module>.Tests.ps1`. Mock at the `InvokeNetboxRequest` level,
   not `Invoke-RestMethod`, unless the cmdlet bypasses it (file uploads, SVG).
6. **Build + verify** — `./deploy.ps1 -Environment dev -SkipVersion`,
   then `Invoke-Pester ./Tests/<Module>.Tests.ps1`.
7. **Revert build artefacts before commit** —
   `git checkout PowerNetbox.psd1` (deploy.ps1 updates its date).

## Cmdlet templates

All four templates share: `[CmdletBinding()]`, explicit `process {}` for
pipeline support, `-Raw` switch, `Write-Verbose` for any operational
logging (never `Write-Host` in non-interactive paths).

### GET

Add query filter parameters (`-Label`, `-Parent`, `-Status`, etc.) inside
the `ParameterSet = 'Query'` group — they flow through `BuildURIComponents`
automatically and appear as `?name=value` query params. Match the NetBox
API field name one-to-one (e.g. API field `mark_utilized` → PS param
`Mark_Utilized`; snake→PascalCase via underscore). Type-check each:
numeric IDs as `[uint64]`, booleans as `[bool]` (never `[switch]`), arrays
as `[string[]]` or `[uint64[]]` depending on whether the API filter
expects names or IDs.

> **Before widening a filter to an array (`[T[]]`), confirm the server filter is
> actually multi-value.** In the OpenAPI schema (`/api/schema/?format=json`) the
> list-endpoint parameter shows `schema.type: array` for multi-value filters and a
> scalar type otherwise. The #447 repeat-key mechanism sends `?k=a&k=b`, but NetBox
> honors only the FIRST value on a scalar filter — so array-typing it is silently
> misleading. Counter-example: contact-assignments `object_type_id` is scalar even
> though its sibling `object_type` is multi-value (PR #456). When unsure, keep scalar.

```powershell
function Get-NB[Module][Resource] {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    param (
        [switch]$All,
        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,
        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName)]
        [uint64[]]$Id,
        [Parameter(ParameterSetName = 'Query')]
        [string]$Name,
        # [Parameter(ParameterSetName = 'Query')]
        # [string]$Status,                                # <-- filter params go here
        # [Parameter(ParameterSetName = 'Query')]
        # [uint64]$Site_Id,
        [uint16]$Limit,
        [uint32]$Offset,   # uint32, not uint16 — NetBox datasets (IPAM, Circuits) exceed 65 535 items
        [switch]$Brief,
        [string[]]$Fields,
        [string[]]$Omit,
        [switch]$Raw
    )
    process {
        # MANDATORY on every Get cmdlet since PR #397/#400.
        # User picks exactly one projection — Brief, Fields, OR Omit.
        AssertNBMutualExclusiveParam `
            -BoundParameters $PSBoundParameters `
            -Parameters 'Brief', 'Fields', 'Omit'

        Write-Verbose "Retrieving <Resource>"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' {
                # Pass projection params (Brief / Fields / Omit) through on
                # detail endpoints too — NetBox supports ?brief=1 / ?fields=
                # / ?omit= on /api/<module>/<resource>/<id>/ (not just on
                # list endpoints). Call BuildURIComponents with 'Id', 'Raw',
                # 'All', 'PageSize' skipped so only Brief/Fields/Omit and any
                # other meaningful flags end up as query params.
                foreach ($i in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('<module>', '<resource>', $i))
                    $URIComponents = BuildURIComponents -URISegments $Segments.Clone() `
                        -ParametersDictionary $PSBoundParameters `
                        -SkipParameterByName 'Id', 'Raw', 'All', 'PageSize'
                    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters
                    InvokeNetboxRequest -URI $URI -Raw:$Raw
                }
            }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('<module>', '<resource>'))
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() `
                    -ParametersDictionary $PSBoundParameters `
                    -SkipParameterByName 'Raw', 'All', 'PageSize'
                InvokeNetboxRequest `
                    -URI (BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters) `
                    -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}
```

### NEW

```powershell
function New-NB[Module][Resource] {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param (
        [Parameter(Mandatory)]
        [string]$Name,
        # Prefer [object[]] for Tags — it accepts both IDs (uint64) and
        # strings. Older cmdlets use [string[]] or [uint64[]] and are
        # kept as-is for back-compat, but new code should use [object[]].
        [object[]]$Tags,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating <Resource>: $Name"
        $Segments = [System.Collections.ArrayList]::new(@('<module>', '<resource>'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() `
            -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create <Resource>')) {
            InvokeNetboxRequest `
                -URI (BuildNewURI -Segments $URIComponents.Segments) `
                -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
```

### SET (PATCH)

```powershell
function Set-NB[Module][Resource] {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [uint64]$Id,
        [string]$Name,
        [switch]$Raw
    )
    process {
        Write-Verbose "Updating <Resource> ID $Id"
        $Segments = [System.Collections.ArrayList]::new(@('<module>', '<resource>', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() `
            -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update <Resource>')) {
            InvokeNetboxRequest `
                -URI (BuildNewURI -Segments $URIComponents.Segments) `
                -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
```

#### SET — null-clearing for enum string parameters

When a `Set-*` function's parameter has `[ValidateSet]` and the user needs
to be able to *clear* that field server-side (send JSON `null`), the
`[AllowNull()] [ValidateSet] [string]` combination doesn't work —
PowerShell coerces `$null` to `""` at bind time and then ValidateSet
rejects the empty string (see Pitfalls row 3).

Pattern used on `Set-NBDCIMInterface` (`Duplex`, `POE_Mode`, `POE_Type`,
`RF_Role`, `Mode`) from PR #401 — add `''` to the ValidateSet as a
caller-visible sentinel, use `[AllowEmptyString()]`, then translate `''`
→ `$null` in `process {}` **before** `BuildURIComponents` so the PATCH
body carries a literal JSON `null`:

```powershell
function Set-NB[Module][Resource] {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [uint64]$Id,

        [AllowEmptyString()]
        [ValidateSet('full', 'half', 'auto', '', IgnoreCase = $true)]
        [string]$Duplex,                 # pass '' to clear server-side

        [switch]$Raw
    )
    process {
        # Translate '' → $null for the clearable enum params BEFORE
        # BuildURIComponents, so the PATCH body becomes {"duplex": null}
        # rather than {"duplex": ""} (which NetBox rejects).
        $clearable = @('Duplex')
        foreach ($p in $clearable) {
            if ($PSBoundParameters.ContainsKey($p) -and $PSBoundParameters[$p] -eq '') {
                $PSBoundParameters[$p] = $null
            }
        }

        $Segments = [System.Collections.ArrayList]::new(@('<module>', '<resource>', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() `
            -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update <Resource>')) {
            InvokeNetboxRequest `
                -URI (BuildNewURI -Segments $URIComponents.Segments) `
                -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
```

Numeric parameters needing null-clearing use `[Nullable[T]]` instead —
see Pitfalls row 2 for the `[ValidateRange]` + `[Nullable[int]]` conflict
and PR #398 for the rollout across 9 numeric Interface parameters.

### REMOVE

```powershell
function Remove-NB[Module][Resource] {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([void])]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [uint64]$Id,
        [switch]$Raw
    )
    process {
        Write-Verbose "Deleting <Resource> ID $Id"
        if ($PSCmdlet.ShouldProcess($Id, 'Delete <Resource>')) {
            InvokeNetboxRequest `
                -URI (BuildNewURI -Segments @('<module>', '<resource>', $Id)) `
                -Method DELETE -Raw:$Raw
        }
    }
}
```

## Test pattern

Most test files mock at the **module API surface** — that is,
`InvokeNetboxRequest` — not the lower-level `Invoke-RestMethod`. Nice
side effect: your test doesn't care about auth headers, retry logic,
or cross-platform HTTP differences.

```powershell
Describe "<Module> tests" -Tag '<Module>' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
        Mock -CommandName 'InvokeNetboxRequest'    -ModuleName 'PowerNetbox' -MockWith {
            return [ordered]@{
                'Method' = if ($Method) { $Method } else { 'GET' }   # defaults don't apply to mocks
                'Uri'    = $URI.Uri.AbsoluteUri                        # AbsoluteUri encodes spaces as %20
                'Body'   = if ($Body) { $Body | ConvertTo-Json -Compress -Depth 10 } else { $null }
            }
        }
        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }
    }

    Context "Get-NB<Module><Resource>" {
        It "Should request the list endpoint" {
            $r = Get-NB<Module><Resource>
            $r.Method | Should -Be 'GET'
            $r.Uri    | Should -Be 'https://netbox.domain.com/api/<module>/<resource>/'
        }
    }
}
```

Mock at `Invoke-RestMethod` level only when the cmdlet bypasses
`InvokeNetboxRequest`: `New-NBImageAttachment` (multipart form),
`Export-NBRackElevation` SVG mode, `ErrorHandling.Tests.ps1`,
`Setup.Tests.ps1`, `CrossPlatform.Tests.ps1`, `Branching.Tests.ps1`.

## ValidateSet parity — run it

Every time you add or edit a `ValidateSet`:

```pwsh
./scripts/Verify-ValidateSetParity.ps1 -NetboxVersion v<x.y.z>
# Or scope to the cmdlet you touched:
./scripts/Verify-ValidateSetParity.ps1 -Function New-NBDCIMInterface
```

If your parameter deliberately has values NetBox's choices.py doesn't have
(e.g. the `''` empty-string sentinel for PATCH null-clearing, or local
meta-values like `'Both'` for rack elevation), add an exemption to
`scripts/validateset-parity-exclusions.txt` with a comment explaining why.

## Pitfalls (things that have bitten us more than once)

| Pitfall | Cause | Fix |
|---|---|---|
| Windows PS 5.1 CI fails with "Missing closing '}'" at some line far from the real issue | Non-ASCII char (em-dash U+2014, arrows, curly quotes) in a `.ps1` file without a UTF-8 BOM — PS 5.1 parses as Windows-1252 | Stay ASCII in `.ps1` identifiers and test titles. Markdown `.md` files are unaffected. (Recurring: PR #398, PR #404) |
| `[ValidateRange]` + `[Nullable[int]]` throws `ValidationMetadataException` on `$null` | ValidateRange binds before Nullable wrapping | Drop `[ValidateRange]` on `Set-*` versions that need null-clearing; rely on server-side validation (PR #398) |
| `[AllowNull()] [ValidateSet(...)] [string]$X` rejects `$null` | PS coerces `$null` → `""` before ValidateSet runs | Use `[AllowEmptyString()] [ValidateSet('a','b','',...)]` and translate `''` → `$null` in `process{}` before `BuildURIComponents` (PR #401) |
| Pester mock gets `$null` for default-valued params | Default values do not apply inside `MockWith` | Add explicit defaults inside the mock (see test template above) |
| `ConvertTo-Json` mangles nested objects at the default depth | `ConvertTo-Json` defaults to `-Depth 2` | Pass `-Depth 10` explicitly when needed |
| PSCustomObject iterated like a hashtable throws | PSCustomObject is not a hashtable | Use `$obj.PSObject.Properties` to iterate |
| Build artefact noise in git diff | `deploy.ps1` updates `PowerNetbox.psd1` date on every build | `git checkout PowerNetbox.psd1` before staging |
| `-Tags` parameter accepts only names or only IDs, not both | Older cmdlets type `Tags` as `[string[]]` (names) or `[uint64[]]` (IDs) — mutually exclusive | New cmdlets: `[object[]]$Tags` so callers can pass a mix. Legacy cmdlets left as-is for back-compat; add `[object[]]` only on new code |
| Bulk operations pipeline runs unboundedly | No client throttle by default | `Send-NBBulkRequest` has `MaxItems = 10000` cap; pass `-BatchSize` to size each POST |
| Pagination `.next` follow to wrong host | Server-controlled URL could be attacker-controlled | `InvokeNetboxRequest` validates origin against original URI via `GetLeftPart(Authority)` (PR #404) |
| Array-widened filter silently returns only one match | NetBox honors only the FIRST value of a repeated query key when the underlying filter is scalar, even though #447 sends all values | Verify the filter is `schema.type: array` in the OpenAPI schema before changing `[T]` → `[T[]]`. Scalar example: contact-assignments `object_type_id` (PR #456) |
| Case-insensitive (`__ie`) filter returns the FULL unfiltered list | NetBox SILENTLY ignores an unknown lookup (HTTP 200, everything) — it does not 400; and `__ie` (iexact) support is per-endpoint (e.g. no `role__ie` on `/dcim/devices/`) | Only rewrite a key to `__ie` if that field exposes `*__ie` for THAT endpoint in the schema; never for numeric/datetime/relational/CIDR/choice fields. Intersect against the live schema, don't hand-curate (PR #454) |
| Param/switch referenced in body or help but missing from `param()` | Author added `.PARAMETER` help + a body reference but forgot the `[switch]$X` declaration → unbound `$null` (and hard-throws under `Set-StrictMode`) | Every `.PARAMETER` and every `$Var` read in the body needs a matching `param()` entry. The `CodeQuality.Tests.ps1` parity gate catches the help side (PR #454 `-IgnoreCase`) |
| `Get-NB*Option`/config getter throws on a fresh import | A new `$script:NetboxConfig` key read by the getter was never seeded in `SetupNetboxConfigVariable.ps1` | When adding a Set-/Get- pair backed by `$script:NetboxConfig`, seed the key (e.g. `$false`) in `SetupNetboxConfigVariable.ps1`; getters return the value, don't throw (match `Get-NBTimeout`) (PR #454) |

## Parameter naming conventions

- **Snake-case** in the cmdlet body: parameters map 1:1 to NetBox API fields.
  `Device_Type` (PS) → `device_type` (API) — done automatically by `BuildURIComponents`.
- `Id` (not `ID`) for PowerShell consistency with pipeline binding.
- `Tags` should be `[object[]]` — see Pitfalls. Older cmdlets use
  `[string[]]` or `[uint64[]]`; left as-is for compat, but new code uses `[object[]]`.
- `-Raw` switch on every cmdlet (returns the full response object rather than
  the `.results` array).
- Boolean API fields: use `[bool]`, not `[switch]`. Switches mean "omitted
  vs supplied" but NetBox treats missing vs false differently.

## Verification before PR

- [ ] `./deploy.ps1 -Environment dev -SkipVersion` — build succeeds, no duplicate function names
- [ ] `Invoke-Pester ./Tests/<Module>.Tests.ps1` — all green
- [ ] Every NEW or type-changed parameter has a `.PARAMETER` help entry AND a Pester assertion (URI or body). `Invoke-Pester ./Tests/CodeQuality.Tests.ps1` — the "parameter parity" gate fails on a new `.PARAMETER` gap; fix the help, do NOT silence it by re-baselining
- [ ] For any filter widened to an array type, the server filter is confirmed `schema.type: array` in the OpenAPI schema (scalar filters honor only the first repeated value)
- [ ] `Invoke-ScriptAnalyzer -Path ./Functions/<Module>/<new file>.ps1` — clean
- [ ] `./scripts/Verify-ValidateSetParity.ps1` — no new drift findings
- [ ] `./scripts/Verify-FilterExclusion.ps1` — if you touched any `Get-NB*.ps1`, see `docs/guides/` if unfamiliar
- [ ] `grep -nP "[^\x00-\x7F]" Functions/... Tests/...` — no non-ASCII in `.ps1` files
- [ ] `git checkout PowerNetbox.psd1` — revert build-artefact drift before committing

## Pointers

| Topic | File |
|---|---|
| Central HTTP helper | `Functions/Helpers/InvokeNetboxRequest.ps1` |
| Body + URL parameter assembly | `Functions/Helpers/BuildURIComponents.ps1` |
| URL builder | `Functions/Helpers/BuildNewURI.ps1` |
| Auth header construction (v1 vs v2) | `Functions/Helpers/Get-NBRequestHeaders.ps1` |
| Mutex helper for Brief / Fields / Omit | `Functions/Helpers/AssertNBMutualExclusiveParam.ps1` |
| Bulk operations | `Functions/Helpers/Send-NBBulkRequest.ps1` |
| Param↔.PARAMETER parity gate | `Tests/CodeQuality.Tests.ps1` (Context "Comment-based help parameter parity") |
| Parity baseline + regenerator | `Tests/param-help-parity-baseline.txt`, `Tests/Update-ParamHelpParityBaseline.ps1` |
| ValidateSet parity script | `scripts/Verify-ValidateSetParity.ps1` |
| ValidateSet parity exceptions | `scripts/validateset-parity-exclusions.txt` |
| Filter exclusion auditor | `scripts/Verify-FilterExclusion.ps1` |
| Exemption file for filter auditor | `scripts/filter-exclusion-exemptions.txt` |
| NetBox best-practices reference | `../netbox-best-practices/` (parent project dir) |
