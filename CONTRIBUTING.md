# Contributing to PowerNetbox

Thank you for your interest in contributing to PowerNetbox! This document explains our development practices and how to contribute effectively.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Code Quality Standards](#code-quality-standards)
- [Testing Requirements](#testing-requirements)
- [Pull Request Process](#pull-request-process)
- [Why These Practices?](#why-these-practices)

## Code of Conduct

Be respectful, inclusive, and constructive. We're all here to build great software together.

## Getting Started

### Prerequisites

- PowerShell 7.6 LTS, 7.4 LTS, or Windows PowerShell 5.1 (see the [Compatibility guide](https://docs.powernetbox.dev/guides/compatibility/#powershell-support))
- Git
- A Netbox instance for testing (or use Docker)
- [Pester](https://pester.dev/) 5.0+ for running tests

### Setup

```powershell
# Clone the repository
git clone https://github.com/ctrl-alt-automate/PowerNetbox.git
cd PowerNetbox

# Build the module
./deploy.ps1 -Environment dev -SkipVersion

# Run tests
Invoke-Pester ./Tests/
```

### Docker-based Testing

```bash
# Start a local Netbox instance
docker compose -f docker-compose.ci.yml up -d

# Wait for Netbox to be ready (2-3 minutes)
# Then run integration tests
pwsh -Command "Invoke-Pester ./Tests/Integration.Tests.ps1 -Tag 'Live'"

# Cleanup
docker compose -f docker-compose.ci.yml down -v
```

## Development Workflow

### Branch Strategy

| Branch | Purpose |
|--------|---------|
| `main` | Production releases (published to PSGallery) |
| `dev` | Active development |
| `beta` | Pre-release testing (e.g., Netbox 4.5 compatibility) |
| `feature/*` | Feature branches |
| `fix/*` | Bug fix branches |

### Creating a Feature

1. **Create a branch** from `dev`:
   ```bash
   git checkout dev
   git pull origin dev
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following our [code standards](#code-quality-standards)

3. **Test your changes**:
   ```powershell
   Invoke-Pester ./Tests/
   ```

4. **Commit with meaningful messages**:
   ```bash
   git commit -m "feat(dcim): Add support for cable profiles"
   ```

5. **Push and create a PR** against `dev`

## Code Quality Standards

### PowerShell Best Practices

We follow the [PowerShell Practice and Style Guidelines](https://poshcode.gitbook.io/powershell-practice-and-style/).

#### Required Attributes

```powershell
function Get-NBExample {
    [CmdletBinding()]                    # Always required
    [OutputType([PSCustomObject])]       # Document return type
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]       # Validate inputs
        [string]$Name,

        [switch]$Raw                     # All functions need -Raw switch
    )

    process {                            # Use process block for pipeline support
        # Implementation
    }
}
```

#### State-Changing Functions

Functions that modify data must use `SupportsShouldProcess`:

```powershell
function New-NBExample {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param(...)

    process {
        if ($PSCmdlet.ShouldProcess($Name, 'Create Example')) {
            # Create the resource
        }
    }
}
```

| Verb | ConfirmImpact |
|------|---------------|
| New- | Low |
| Set- | Medium |
| Remove- | High |

#### Naming Conventions

- **Functions**: `[Verb]-NB[Module][Resource]` (e.g., `Get-NBDCIMDevice`)
- **Files**: One function per file, filename matches function name
- **Parameters**: PascalCase, use standard names (`Id`, `Name`, `Limit`, `Offset`)

#### Forbidden Practices

- ❌ `Write-Host` (use `Write-Verbose` instead)
- ❌ Hardcoded paths or credentials
- ❌ Using `\` in paths (use `Join-Path`)
- ❌ Ignoring errors silently

### Automated Checks

Every PR is automatically checked for:

| Check | Tool | Purpose |
|-------|------|---------|
| Linting | PSScriptAnalyzer | PowerShell best practices |
| Unit Tests | Pester | Code correctness |
| Cross-Platform | GitHub Actions | Windows, Linux, macOS compatibility |

## Testing Requirements

### Unit Tests

- All new functions need corresponding tests
- Tests go in `Tests/` directory
- Use Pester 5.x syntax

```powershell
Describe "Get-NBDCIMDevice" {
    It "Should return devices" {
        # Test implementation
    }
}
```

### Test Coverage

We aim for comprehensive coverage of:

- Happy path scenarios
- Error handling
- Edge cases
- Pipeline input

### Running Tests

```powershell
# All tests
Invoke-Pester ./Tests/

# Specific test file
Invoke-Pester ./Tests/DCIM.Tests.ps1

# With coverage
Invoke-Pester ./Tests/ -CodeCoverage ./Functions/**/*.ps1
```

## Pull Request Process

### Before Submitting

1. ✅ All tests pass locally
2. ✅ Code follows style guidelines
3. ✅ New functionality has tests
4. ✅ Documentation updated (if needed)

### PR Requirements

PRs must pass these automated checks before merge:

| Check | Required |
|-------|----------|
| PSScriptAnalyzer | ✅ |
| Pester Tests (ubuntu-latest, PS 7.6) | ✅ |
| Pester Tests (windows-latest, PS 7.6) | ✅ |
| Pester Tests (windows-latest, PS 5.1) | ✅ |
| Code Review (1 approval) | ✅ |

The full matrix runs seven legs (three operating systems on PowerShell 7.4 and 7.6, plus
Windows PowerShell 5.1); the four above are the ones branch protection requires.

### Review Process

1. **Automated checks** run immediately
2. **Code owners** are automatically assigned as reviewers
3. **At least 1 approval** is required
4. **All checks must pass** before merge

## Why These Practices?

We've implemented specific GitHub features to maintain code quality. Here's why:

### Required Status Checks

**Why?** Prevents broken code from being merged.

- PSScriptAnalyzer catches common PowerShell mistakes
- Pester tests verify functionality works
- Cross-platform tests ensure compatibility

### PR Templates

**Why?** Ensures consistent, complete information.

- Reviewers know what changed and why
- Checklist prevents forgotten steps
- Testing details help reproduce issues

### Issue Templates

**Why?** Gets the right information upfront.

- Bug reports include environment details
- Feature requests explain the use case
- Reduces back-and-forth communication

### CODEOWNERS

**Why?** Ensures the right people review changes.

- Module experts review their areas
- Critical files get extra attention
- Automatic assignment saves time

### Branch Protection

**Why?** Prevents accidental damage.

- Can't push directly to protected branches
- Must go through PR process
- Ensures all checks pass

### Milestones

**Why?** Tracks progress toward releases.

- Groups related issues together
- Shows what's included in each version
- Helps prioritize work

---

## Questions?

- Check the [Wiki](https://github.com/ctrl-alt-automate/PowerNetbox/wiki)
- Open a [Discussion](https://github.com/ctrl-alt-automate/PowerNetbox/discussions)
- Review existing [Issues](https://github.com/ctrl-alt-automate/PowerNetbox/issues)

Thank you for contributing to PowerNetbox! 🎉
