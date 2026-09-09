# Netbox Version Compatibility

PowerNetbox is tested against multiple Netbox versions to ensure broad compatibility.

## Supported Versions

> The exact versions exercised in CI are shown on the
> [home page compatibility table](../index.md#compatibility), which is
> generated from the integration matrix. The families below describe the
> broader support policy.

| Netbox Version | Status | Notes |
|----------------|--------|-------|
| 4.7.x | ✅ Full Support | Primary development target |
| 4.6.x | ✅ Full Support | All integration tests pass |
| 4.5.x | ✅ Full Support | All integration tests pass |
| 4.4.x | ✅ Full Support | All integration tests pass |
| 4.3.x | ✅ Full Support | Minimum supported, all integration tests pass |
| 4.2.x | ❌ Not Supported | Use PowerNetbox v4.4.10.0 or earlier |
| 4.1.x | ❌ Not Supported | Use PowerNetbox v4.4.10.0 or earlier |
| 4.0.x | ❌ Not Supported | Use PowerNetbox v4.4.10.0 or earlier |
| 3.x | ❌ Not Supported | Missing required API endpoints |

**Minimum supported version: Netbox 4.3+**

## Compatibility Testing

PowerNetbox uses automated compatibility testing via GitHub Actions. The workflow tests against multiple Netbox versions using Docker images from [netboxcommunity/netbox](https://hub.docker.com/r/netboxcommunity/netbox).

### Test Matrix

The compatibility workflow runs 94 integration tests against each version:

```
Netbox 4.7.0:  110/110 tests passed ✅ (Primary target)
Netbox 4.6.10: 110/110 tests passed ✅
Netbox 4.5.10: 110/110 tests passed ✅
Netbox 4.4.10: 110/110 tests passed ✅
Netbox 4.3.7:   96/110 tests passed ✅ (Minimum supported; 14 skipped for 4.4+/4.5+ features)
```

## API Endpoint Changes

PowerNetbox handles API changes between Netbox versions automatically:

### Netbox 4.5 Changes

| Change | Description | PowerNetbox Handling |
|--------|-------------|---------------------|
| Token v2 | New `nbt_<KEY>.<TOKEN>` format with Bearer auth | Auto-detected, uses correct auth header |
| is_staff removed | User model no longer has `is_staff` field | `Is_Staff` parameter ignored on 4.5+ |
| Cable Profiles | New `profile` field on cables | `Cable_Profile` parameter on cable functions |
| Object Ownership | New `/api/users/owners/` endpoint | `Get/New/Set/Remove-NBOwner` functions |
| Port Mappings | Bidirectional `front_ports`/`rear_ports` | Full support in port functions |
| Form_Factor removed | Interface `form_factor` replaced by `type` | `-Form_Factor` parameter removed, use `-Type` |
| `?omit=` parameter | Replaces `?exclude=` for field omission | `-Omit` parameter on all 123 Get functions |
| Image Attachments | Upload images to any object | `New-NBImageAttachment` function |

### Content Types / Object Types

| Netbox Version | Endpoint |
|----------------|----------|
| 4.4+ | `/api/core/object-types/` |
| 4.0-4.3 | `/api/extras/object-types/` |

The `Get-NBContentType` function automatically detects your Netbox version and uses the correct endpoint.

### Module Availability

| Module | Available Since |
|--------|-----------------|
| DCIM | All versions |
| IPAM | All versions |
| Virtualization | All versions |
| Circuits | All versions |
| Tenancy | All versions |
| Extras | All versions |
| Core | Netbox 3.5+ |
| VPN | Netbox 3.7+ |
| Wireless | Netbox 3.1+ |
| Users | Netbox 3.0+ |

### Netbox 4.7 Changes

| Change | Description | PowerNetbox Handling |
|--------|-------------|---------------------|
| Service `port_mappings` | `protocol`/`ports` replaced by a unified `port_mappings` list (`tcp/80`, `udp/53`); legacy pair deprecated, removed in 5.0 | New `-Port_Mappings` on `New-/Set-/Get-NBIPAMService` and `-NBIPAMServiceTemplate` (4.7+, warns and is dropped on older servers); `-Ports`/`-Protocol` still work |
| Per-object bulk errors | Failed bulk create/update returns `{"detail", "errors": [{"index", "errors"}]}` | Error message lists each failing index with its field errors |
| Selection custom fields | Returned as `{"value", "label"}` objects instead of the raw value | Passed through unchanged; scripts reading `custom_fields.<name>` must use `.value` on 4.7+ |
| `?exclude=config_context` ignored | Config context is pre-rendered and always included | `-Omit config_context` still works (`?omit=` is honoured) |
| Token plaintext read-only | Clients can no longer choose the token value on create | No impact (`New-NBToken` never exposed it) |
| v2 tokens only in netbox-docker 5.0.2+ | `SUPERUSER_API_TOKEN` alone no longer creates a token | `docker-compose.ci.yml` sets `SUPERUSER_API_KEY` for a deterministic `nbt_` token |
| New interface/port types | `channel`, `100gbase-x-sfp112`, InfiniBand 4X, HPE Synergy; `mdc` port; `breakout-1c8p-8c1p` cable profile | Added to the ValidateSets |
| Cooling infrastructure | `cooling-sources`, `cooling-feeds`, `cooling-intakes`, `cooling-outflows` (+ templates) | `Get/New/Set/Remove-NBDCIMCooling*` (v4.7.1.0) |
| Module bay types | `module-bay-types` + `module_bay_types` on module bays / templates / module types | `Get/New/Set/Remove-NBDCIMModuleBayType`, `-Module_Bay_Types` (v4.7.1.0) |
| New fields | Interface `channels`/`channel_id`/`mac_address`, `cooling_method`, `end_of_life`, Rack `cooling_capability`/`cooling_capacity` | Parameters + filters, version-gated (v4.7.1.0) |
| Background bulk writes | `?background=true` -> 202 + job | `-Background` on bulk-capable cmdlets (v4.7.1.0) |
| `tag__any` (4.6.6) | OR semantics for tag filters | `-Tag`/`-Tag_Id` on all Get cmdlets + `Set-NBQueryOption -TagMatch Any` (v4.7.1.0) |
| Cursor pagination (4.6) | `?start=<pk>` | `Set-NBQueryOption -Pagination Cursor` (v4.7.1.0) |
| ETag / If-Match (4.6) | optimistic concurrency, 412 on conflict | `Set-NBQueryOption -OptimisticConcurrency` (v4.7.1.0) |
| `add_tags` / `remove_tags` (4.6) | partial tag assignment | `Set-NBObjectTag` (v4.7.1.0) |


## Running Compatibility Tests Locally

The quickest way is the helper script, which starts one Docker stack per NetBox version (fixed ports 8000-8004, correct image tag and API token per netbox-docker generation) and exports `NETBOX_HOST` / `NETBOX_TOKEN` / `NETBOX_SCHEME`:

```powershell
./scripts/Start-NetboxDocker.ps1 -Version 4.7.0 -Worker -SetEnvironment
Invoke-Pester ./Tests/Integration.Tests.ps1 -Tag 'Live'
./scripts/Test-AllNetboxVersions.ps1        # whole matrix, one summary table
./scripts/Start-NetboxDocker.ps1 -Version 4.7.0 -Down
```

Or by hand with Docker Compose:

```bash
# Start Netbox with a specific version
export NETBOX_VERSION=v4.3.7-3.3.0
docker compose -f docker-compose.ci.yml up -d

# Wait for Netbox to be healthy
docker inspect --format='{{.State.Health.Status}}' powernetbox-netbox-1

# Run tests
$env:NETBOX_HOST = 'localhost:8000'
# netbox-docker <= 3.x (Netbox <= 4.4): v1 token
$env:NETBOX_TOKEN = '0123456789abcdef0123456789abcdef01234567'
# netbox-docker 5.0.2+ (Netbox 4.6.10 / 4.7+): deterministic v2 token (SUPERUSER_API_KEY + SUPERUSER_API_TOKEN)
$env:NETBOX_TOKEN = 'nbt_powernetbox1.0123456789abcdef0123456789abcdef01234567'
Invoke-Pester ./Tests/Integration.Tests.ps1 -Tag 'Live'

# Cleanup
docker compose -f docker-compose.ci.yml down -v
```

### Available Docker Image Tags

| Netbox Version | Docker Tag | Notes |
|----------------|------------|-------|
| 4.7.0 | `v4.7.0-5.1.0` | netbox-docker 5.1.0 (Django 6.1, PostgreSQL 15+ required, v2 tokens only) |
| 4.6.10 | `v4.6.10-5.0.2` | netbox-docker 5.0.2 (v2 tokens only) |
| 4.5.10 | `v4.5.10-4.0.2` | netbox-docker 4.0.2 (Granian, PostgreSQL 18, Valkey 9) |
| 4.4.10 | `v4.4.10-3.4.2` | netbox-docker 3.4.2 |
| 4.3.7 | `v4.3.7-3.3.0` | netbox-docker 3.3.0 |

## Reporting Compatibility Issues

If you encounter compatibility issues with a specific Netbox version:

1. Check this page for known issues
2. Try updating to the latest PowerNetbox version
3. [Open an issue](https://github.com/ctrl-alt-automate/PowerNetbox/issues) with:
   - Your Netbox version (`Get-NBVersion`)
   - PowerNetbox version (`Get-Module PowerNetbox`)
   - The specific function and error message
