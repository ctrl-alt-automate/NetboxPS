<p align="center">
  <img src="assets/PowerNetbox-logo.png" alt="PowerNetbox Logo" width="280">
</p>

<h1 align="center">PowerNetbox</h1>

<p align="center">
  <a href="https://www.powershellgallery.com/packages/PowerNetbox"><img src="https://img.shields.io/powershellgallery/v/PowerNetbox?label=PSGallery&logo=powershell&logoColor=white" alt="PowerShell Gallery"></a>
  <a href="https://www.powershellgallery.com/packages/PowerNetbox"><img src="https://img.shields.io/powershellgallery/dt/PowerNetbox?label=Downloads&logo=powershell&logoColor=white" alt="Downloads"></a>
  <a href="https://github.com/ctrl-alt-automate/PowerNetbox/actions/workflows/test.yml"><img src="https://github.com/ctrl-alt-automate/PowerNetbox/actions/workflows/test.yml/badge.svg" alt="Tests"></a>
  <a href="https://github.com/ctrl-alt-automate/PowerNetbox/actions/workflows/integration.yml"><img src="https://github.com/ctrl-alt-automate/PowerNetbox/actions/workflows/integration.yml/badge.svg" alt="Integration Tests"></a>
  <br>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/ctrl-alt-automate/PowerNetbox" alt="License"></a>
  <a href="https://github.com/ctrl-alt-automate/PowerNetbox/actions/workflows/pssa.yml"><img src="https://github.com/ctrl-alt-automate/PowerNetbox/actions/workflows/pssa.yml/badge.svg" alt="Lint"></a>
  <a href="https://docs.powernetbox.dev/"><img src="https://img.shields.io/badge/docs-powernetbox.dev-blue?logo=materialformkdocs&logoColor=white" alt="Documentation"></a>
  <a href="https://github.com/netbox-community/netbox"><img src="https://img.shields.io/badge/Netbox-4.6.0-blue?logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZmlsbD0id2hpdGUiIGQ9Ik0xMiAyTDIgN2wxMCA1IDEwLTV6TTIgMTdsMTAgNSAxMC01TTIgMTJsMTAgNSAxMC01Ii8+PC9zdmc+" alt="Netbox Version"></a>
</p>

<p align="center">
  <b>The</b> comprehensive PowerShell module for the <a href="https://github.com/netbox-community/netbox">Netbox</a> REST API with <b>100% coverage</b> — 520+ cmdlets across DCIM, IPAM, Virtualization, Circuits, Tenancy, VPN, Wireless, and the netbox-branching plugin.<br>
  Cross-platform (PowerShell 5.1 / 7+), fully compatible with <b>Netbox 4.6.0</b> (supports 4.3+).
</p>

<p align="center">
  <b>📖 Full documentation: <a href="https://docs.powernetbox.dev/">docs.powernetbox.dev</a></b>
</p>

---

## Acknowledgements

This project is a fork of the original **[NetboxPS](https://github.com/benclaussen/NetboxPS)** created by **[Ben Claussen](https://github.com/benclaussen)**.

We extend our sincere thanks to Ben and all original contributors for building the foundation of this module. Their work made PowerNetbox possible.

| | |
|---|---|
| **Original Author** | [Ben Claussen](https://github.com/benclaussen) |
| **Original Repository** | [benclaussen/NetboxPS](https://github.com/benclaussen/NetboxPS) |
| **License** | MIT (preserved from original) |

---

## Quickstart

```powershell
# Install
Install-Module -Name PowerNetbox -Scope CurrentUser

# Connect (paste your NetBox API token when prompted)
$cred = Get-Credential -UserName 'api'
Connect-NBAPI -Hostname 'netbox.example.com' -Credential $cred

# Query
Get-NBDCIMDevice -Brief
```

Full install options (PS 5.1 vs 7+, platform-specific, manual build), connection
and authentication details, and worked examples are in the documentation:

| | |
|---|---|
| 🚀 **Getting started** | [Installation](https://docs.powernetbox.dev/getting-started/installation/) · [Connecting](https://docs.powernetbox.dev/getting-started/connecting/) · [Your first device](https://docs.powernetbox.dev/getting-started/your-first-device/) · [Authentication](https://docs.powernetbox.dev/getting-started/authentication/) |
| 📚 **Cmdlet reference** | [docs.powernetbox.dev/reference](https://docs.powernetbox.dev/reference/) — every public cmdlet, generated from source |
| 📝 **Release notes** | [docs.powernetbox.dev/release-notes](https://docs.powernetbox.dev/release-notes/) · [GitHub Releases](https://github.com/ctrl-alt-automate/PowerNetbox/releases) |
| 🧭 **Guides** | [Common workflows](https://docs.powernetbox.dev/guides/common-workflows/) · [Bulk operations](https://docs.powernetbox.dev/guides/bulk-operations/) · [Performance](https://docs.powernetbox.dev/guides/performance/) · [Branching](https://docs.powernetbox.dev/guides/branching/) · [Troubleshooting](https://docs.powernetbox.dev/guides/troubleshooting/) · [Compatibility](https://docs.powernetbox.dev/guides/compatibility/) |
| 🏗️ **Architecture** | [Overview](https://docs.powernetbox.dev/architecture/overview/) · [Error handling](https://docs.powernetbox.dev/architecture/error-handling/) · [Function naming](https://docs.powernetbox.dev/architecture/function-naming/) · [Helpers map](https://docs.powernetbox.dev/architecture/helpers-map/) |

---

## Filter parameter usage in API queries

### Case sensitivity - insensitivity

The NetBox API, by default, treats all query parameter values as case-sensitive. As PowerShell is [as case-insensitive as possible](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_case-sensitivity), the module offers an option to use case-insensitive query values.

#### Activating case insensitive mode

`Set-NBQueryOption -IgnoreCase:$true` or `Connect-NBAPI -IgnoreCase`.

### Using wildcards/regex when filtering queries

By default, the module uses filter queries, that ask for an exact match.\
You can influence this behaviour by choosing between three modes: Exact, Wildcard, Regex. Every API string parameter, which supports regex/iregex operators, is enabled

1. Exact: The search string is sent 1:1 through the API
2. Wildcard: [Wildcard characters](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_wildcards) in the search string, are taken into account for filtering query results.
3. Regex: Search strings accept Regex tokens for filtering result sets. Please keep in mind, that regex is matching parts of a string!

#### Activating advanced match modes

`Set-NBQueryOption -MatchMode Wildcard|Regex` or `Connect-NBAPI -Matchmode`.

### Requirements and limitations

Depending on the version of the NetBox API used, the API supports these options for a specific set of parameters and endpoints. Due to this current limitation, the module can only support case insensitivity and wildcard searches for the same set of cases.

- Minimum version of Netbox API is 4.4+.
- A list of parameters offered by each API version can be found in the repository. See [_IgnoreCaseParameters.ps1](./Functions/Helpers/_IgnoreCaseParameters.ps1).
  Each parameter is paired with an exception list of endpoints. This means it is supported on all endpoints which are not part of the list.

## Requirements

PowerShell **5.1** (Windows Desktop) or **7.0+** (Windows / macOS / Linux), and
NetBox **4.3+** (tested against 4.3.7, 4.4.10, 4.5.10, 4.6.0). Version-specific
behaviour and the support matrix are documented in the
[Compatibility guide](https://docs.powernetbox.dev/guides/compatibility/).

## Contributing

Contributions are welcome. Fork the repo, branch from `dev`, follow the
[PowerShell Practice and Style Guidelines](https://poshcode.gitbook.io/powershell-practice-and-style/),
and open a pull request against `dev`. See
[CONTRIBUTING.md](CONTRIBUTING.md) for the full workflow.

## Security and privacy

- **Vulnerability reporting:** see [SECURITY.md](SECURITY.md). Use GitHub
  Security Advisories for private disclosure.
- **Privacy:** see [PRIVACY.md](PRIVACY.md). PowerNetbox sends requests only to
  the NetBox host you configure — no telemetry, no analytics.
- **Recent security reviews:** `docs/superpowers/reviews/`.

## Authenticity & provenance

PowerNetbox is distributed **unsigned** on PSGallery. Authenticity is anchored
in GitHub's Sigstore-backed build-provenance attestations, produced
automatically for every release by
[`actions/attest-build-provenance`](https://github.com/actions/attest-build-provenance).

Verify a downloaded module:

```powershell
$module = Get-Module -ListAvailable PowerNetbox |
    Sort-Object Version -Descending |
    Select-Object -First 1

gh attestation verify $module.Path `
    --repo ctrl-alt-automate/PowerNetbox
```

Additional trust anchors: PSGallery publisher identity (`ctrl-alt-automate`),
signed git release tags, and the public MIT-licensed source at each tag.

**Note on Authenticode:** PowerNetbox has no Authenticode signature, so
`Get-AuthenticodeSignature` will report `NotSigned` — this is expected. An OSS
code-signing certificate may be revisited if the project grows enough to
qualify for a Foundation-backed program.

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file
for details.

Original copyright (c) 2018 Ben Claussen. Fork maintained by ctrl-alt-automate.
