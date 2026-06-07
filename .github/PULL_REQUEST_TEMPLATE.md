## Description

<!-- Briefly describe the changes in this PR -->

## Type of Change

<!-- Mark the relevant option with an "x" -->

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Documentation update
- [ ] Code refactoring (no functional changes)
- [ ] CI/CD or build changes

## Related Issues

<!-- Link to related issues using "Fixes #123" or "Relates to #123" -->

Fixes #

## Checklist

<!-- Ensure all items are checked before requesting review -->

### Code Quality
- [ ] Code follows the [PowerShell Practice and Style Guidelines](https://poshcode.gitbook.io/powershell-practice-and-style/)
- [ ] Functions use `[CmdletBinding()]` attribute
- [ ] State-changing functions use `SupportsShouldProcess`
- [ ] No hardcoded paths or credentials
- [ ] `Write-Verbose` used for debugging (not `Write-Host`)
- [ ] Every new/changed parameter has a `.PARAMETER` help entry, and every `.PARAMETER`/body `$var` maps to a real `param()` entry (CI gate: CodeQuality "parameter parity")
- [ ] New `$script:NetboxConfig` keys are seeded in `SetupNetboxConfigVariable.ps1`; companion getters return a default rather than throwing on a fresh import

### Testing
- [ ] Existing tests pass (`Invoke-Pester ./Tests/`)
- [ ] New tests added for new functionality — at least one **pre-merge** (not `Live`/`Integration`-tagged) Pester assertion per new/changed parameter (URI or request body). Array-widened params assert repeat-key emission (`?k=a&k=b`)
- [ ] Tested manually against Netbox instance (if applicable)

### API Correctness
- [ ] Filters widened to an array type are confirmed multi-value in the OpenAPI schema (`schema.type: array`) — scalar filters silently honor only the first repeated value
- [ ] Any case-insensitive / `__ie` (or other lookup-suffix) mapping is intersected against the schema's actual capable fields per endpoint; numeric/datetime/relational/CIDR/choice fields excluded
- [ ] Filters/params marked NetBox 4.x+ degrade safely on older servers (NetBox silently ignores unknown filters → verify no false unfiltered results)

### Documentation
- [ ] Function has proper comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.EXAMPLE`)
- [ ] README updated (if needed)
- [ ] Wiki updated (if needed)

## Testing Performed

<!-- Describe how you tested these changes -->

- Netbox version tested:
- PowerShell version:
- Platform (Windows/Linux/macOS):

## Screenshots (if applicable)

<!-- Add screenshots for UI-related changes -->

## Additional Notes

<!-- Any additional context or notes for reviewers -->
