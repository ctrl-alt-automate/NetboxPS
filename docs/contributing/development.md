# Development Practices

This page documents the quality controls and development practices used in PowerNetbox.

## Overview

We use several GitHub features to maintain code quality and ensure consistent contributions:

| Feature | Purpose | Benefit |
|---------|---------|---------|
| Required Status Checks | Automated testing before merge | Prevents broken code |
| PR Templates | Standardized pull requests | Complete information |
| Issue Templates | Structured bug/feature reports | Faster resolution |
| CODEOWNERS | Automatic reviewer assignment | Expert review |
| Branch Protection | Prevents direct pushes | Enforces process |
| Milestones | Release tracking | Clear roadmap |

## Branch Protection

Both `dev` and `main` branches are protected:

### Required Checks

| Check | Description |
|-------|-------------|
| PSScriptAnalyzer | PowerShell linting |
| Pester Tests (ubuntu-latest, PS 7.6) | Unit tests on Linux, PowerShell 7.6 LTS |
| Pester Tests (windows-latest, PS 7.6) | Unit tests on Windows, PowerShell 7.6 LTS |
| Pester Tests (windows-latest, PS 5.1) | Unit tests on Windows PowerShell 5.1 |

The test workflow runs seven legs in total (Linux, Windows and macOS on PowerShell 7.4 and
7.6, plus Windows PowerShell 5.1); the four above are the ones branch protection requires.

The Windows PowerShell 5.1 leg is required deliberately - see
[Keep .ps1 files ASCII-only](#keep-ps1-files-ascii-only) below.

### Requirements

- ✅ All status checks must pass
- ✅ At least 1 code review approval
- ❌ Force push disabled
- ❌ Branch deletion disabled

## Keep .ps1 files ASCII-only

Use only ASCII characters in `.ps1` files - no em-dashes, arrows, curly quotes or accented
characters. Markdown files are unaffected; this rule is about PowerShell sources only.

If code needs to *emit* a non-ASCII character, build it from its code point instead of
pasting the glyph. `Functions/Helpers/ConvertTo-NBRackConsole.ps1` is the pattern to copy:

```powershell
TopLeft    = [string][char]0x2554  # the glyph may appear in the trailing comment
Horizontal = [string][char]0x2550
```

The source stays ASCII, so it parses identically on every edition, and the comment still
shows a reader what the constant renders as.

**Why:** Windows PowerShell 5.1 reads script files as Windows-1252, not UTF-8. A multi-byte
UTF-8 character is decoded as two garbage characters, which usually breaks the parse
somewhere *after* the offending line. The result is an error that points at the wrong place
and does not mention encoding at all:

```
Missing closing ')' in expression.
Missing closing '}' in statement block.
```

PowerShell 7 parses the same file without complaint, so this only ever fails on the Windows
PowerShell 5.1 leg - which is one of the reasons that leg is a required check. If a build
fails with an inexplicable "missing closing bracket" error on 5.1 only, search the file for
non-ASCII characters first:

```powershell
# Every .ps1 in the repo that contains a non-ASCII character
Get-ChildItem ./Functions -Recurse -Filter *.ps1 |
    Select-String -Pattern '[^\x00-\x7F]'
```

The only hits this should return are the annotated glyphs in
`ConvertTo-NBRackConsole.ps1`, which live in trailing comments. Anything else is a bug
waiting for the next Windows PowerShell 5.1 run.

## Why These Practices?

### 1. Required Status Checks

**Problem**: Broken code can be merged accidentally, causing issues for all users.

**Solution**: Automated tests run on every PR:
- **PSScriptAnalyzer**: Catches common mistakes, enforces style
- **Pester Tests**: Verifies code works correctly
- **Multi-Platform**: Tests on Windows, Linux, macOS

**Result**: Only working, tested code reaches users.

### 2. PR Templates

**Problem**: PRs often lack context, making review difficult.

**Solution**: Structured template with:
- Description of changes
- Type of change (bug fix, feature, etc.)
- Checklist of requirements
- Testing information

**Result**: Reviewers have all information needed for effective review.

### 3. Issue Templates

**Problem**: Bug reports often missing crucial details (version, OS, steps to reproduce).

**Solution**: Templates that prompt for:
- Environment details (PowerShell version, Netbox version, OS)
- Steps to reproduce
- Expected vs actual behavior

**Result**: Faster issue resolution with complete information.

### 4. CODEOWNERS

**Problem**: Not knowing who should review what.

**Solution**: Automatic reviewer assignment:
- Module owners review their modules
- Critical files (manifest, deploy script) get extra attention

**Result**: Right expertise applied to each review.

### 5. Branch Protection

**Problem**: Accidental pushes to main branches can break releases.

**Solution**: Protected branches require:
- PR-based workflow
- Passing checks
- Code review approval

**Result**: Stable main branches, reliable releases.

### 6. Milestones

**Problem**: Hard to track what's included in each release.

**Solution**: Milestones group related issues:
- `v4.5.0 Compatibility` - Netbox 4.5 work
- Future version milestones as needed

**Result**: Clear roadmap, organized releases.

## Contributing

See [CONTRIBUTING.md](https://github.com/ctrl-alt-automate/PowerNetbox/blob/dev/CONTRIBUTING.md) for detailed contribution guidelines.

## Related Pages

- [Getting Started](../getting-started/connecting.md)
- [Function Naming](../architecture/function-naming.md)
- [Troubleshooting](../guides/troubleshooting.md)
- [Compatibility](../guides/compatibility.md)
