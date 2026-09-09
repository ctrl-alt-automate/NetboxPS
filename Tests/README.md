# PowerNetbox Test Suite

Comprehensive testing framework for the PowerNetbox module, ensuring reliability across multiple Netbox versions and use cases.

## Table of Contents

- [Test Architecture](#test-architecture)
- [Quick Start](#quick-start)
- [Test Categories](#test-categories)
  - [Unit Tests](#unit-tests)
  - [Integration Tests](#integration-tests)
  - [Scenario Tests](#scenario-tests)
- [Running Tests](#running-tests)
- [Environment Setup](#environment-setup)
- [Test Data Management](#test-data-management)
- [CI/CD Integration](#cicd-integration)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

---

## Test Architecture

PowerNetbox follows a **test pyramid** approach with three layers of testing:

```
                    /\
                   /  \        Scenario Tests (125 tests)
                  /    \       End-to-end workflows, real API calls
                 /------\
                /        \     Integration Tests (139 tests)
               /          \    Docker-based, live API validation
              /------------\
             /              \  Unit Tests (~1200 tests)
            /                \ Mocked, fast, isolated
           ------------------
```

| Layer | Tests | Speed | Dependencies | Purpose |
|-------|-------|-------|--------------|---------|
| Unit | ~1200 | Fast (<1min) | None (mocked) | Function logic, parameter validation |
| Integration | 139 | Medium (~5min) | Docker Netbox | API compatibility, CRUD operations |
| Scenario | 125 | Slow (~10min) | Live Netbox instances | Real-world workflows, data relationships |

### Directory Structure

```
Tests/
├── README.md                    # This file
├── common.ps1                   # Shared test configuration
├── credential.example.ps1       # Credential template
│
├── # Unit Tests (root level)
├── DCIM.Devices.Tests.ps1       # Device function tests
├── DCIM.Interfaces.Tests.ps1    # Interface function tests
├── DCIM.Sites.Tests.ps1         # Site function tests
├── DCIM.Racks.Tests.ps1         # Rack function tests
├── DCIM.Platforms.Tests.ps1     # Platform function tests
├── DCIM.Templates.Tests.ps1     # Template function tests
├── DCIM.Additional.Tests.ps1    # Additional DCIM tests
├── DCIM.RackElevation.Tests.ps1 # Rack elevation tests
├── IPAM.Tests.ps1               # IP Address Management tests
├── Virtualization.Tests.ps1     # VM and Cluster tests
├── Tenancy.Tests.ps1            # Tenant and Contact tests
├── Circuits.Tests.ps1           # Circuit and Provider tests
├── VPN.Tests.ps1                # VPN module tests
├── Wireless.Tests.ps1           # Wireless module tests
├── Extras.Tests.ps1             # Tags, Custom Fields, etc.
├── Core.Tests.ps1               # Core API functions
├── Users.Tests.ps1              # User management tests
├── Setup.Tests.ps1              # Connection and setup tests
├── Helpers.Tests.ps1            # Helper function tests
├── BulkOperations.Tests.ps1     # Bulk create/update/delete tests
├── ErrorHandling.Tests.ps1      # Error handling tests
├── CrossPlatform.Tests.ps1      # Cross-platform compatibility
├── GraphQL.Tests.ps1            # GraphQL API tests
├── Branching.Tests.ps1          # Branching plugin tests
│
├── integration/                 # Integration test helpers
│   └── DCIM.Site.Tests.ps1      # Site-specific integration tests
│
├── Integration.Tests.ps1        # Main integration test suite
│
└── Scenario/                    # Scenario-based tests
    ├── ScenarioTestHelper.psm1  # Shared scenario utilities
    ├── Filters.Tests.ps1        # Filter query tests
    ├── Relationships.Tests.ps1  # Object relationship tests
    ├── BulkOperations.Tests.ps1 # Bulk operation scenarios
    └── Workflows.Tests.ps1      # End-to-end workflows
```

---

## Quick Start

```powershell
# Run all unit tests (fast, no external dependencies)
Invoke-Pester ./Tests/ -ExcludeTag 'Integration', 'Scenario', 'Live'

# Run integration tests (requires Docker)
docker compose -f docker-compose.ci.yml up -d
$env:NETBOX_HOST = 'localhost:8000'
$env:NETBOX_TOKEN = '0123456789abcdef0123456789abcdef01234567'
Invoke-Pester ./Tests/Integration.Tests.ps1 -Tag 'Integration'

# Run scenario tests (requires live Netbox instance)
$env:SCENARIO_ENV = '4.4.9'
Invoke-Pester ./Tests/Scenario/ -Tag 'Scenario'
```

---

## Test Categories

### Unit Tests

Unit tests verify individual function behavior using mocked API responses. They run quickly and don't require any external dependencies.

#### Characteristics
- **Mocked responses**: No actual API calls
- **Fast execution**: Full suite in < 1 minute
- **Isolated**: Each test is independent
- **High coverage**: Tests all parameter combinations

#### Running Unit Tests

```powershell
# All unit tests
Invoke-Pester ./Tests/ -ExcludeTag 'Integration', 'Scenario', 'Live'

# Specific module
Invoke-Pester ./Tests/DCIM.Devices.Tests.ps1

# With code coverage
Invoke-Pester ./Tests/ -ExcludeTag 'Integration', 'Scenario', 'Live' -CodeCoverage ./Functions/**/*.ps1
```

#### Test Files by Module

| Module | Test File | Test Count | Description |
|--------|-----------|------------|-------------|
| DCIM | `DCIM.Devices.Tests.ps1` | ~80 | Device CRUD operations |
| DCIM | `DCIM.Interfaces.Tests.ps1` | ~60 | Interface management |
| DCIM | `DCIM.Sites.Tests.ps1` | ~40 | Site operations |
| DCIM | `DCIM.Racks.Tests.ps1` | ~35 | Rack operations |
| DCIM | `DCIM.Platforms.Tests.ps1` | ~25 | Platform management |
| DCIM | `DCIM.Templates.Tests.ps1` | ~100 | Component templates |
| DCIM | `DCIM.Additional.Tests.ps1` | ~150 | Cables, Locations, etc. |
| DCIM | `DCIM.RackElevation.Tests.ps1` | ~45 | Rack elevation SVG |
| IPAM | `IPAM.Tests.ps1` | ~120 | IP addresses, prefixes, VLANs |
| Virtualization | `Virtualization.Tests.ps1` | ~80 | VMs, clusters |
| Tenancy | `Tenancy.Tests.ps1` | ~50 | Tenants, contacts |
| Circuits | `Circuits.Tests.ps1` | ~70 | Circuits, providers |
| VPN | `VPN.Tests.ps1` | ~60 | Tunnels, IPSec |
| Wireless | `Wireless.Tests.ps1` | ~40 | Wireless LANs |
| Extras | `Extras.Tests.ps1` | ~80 | Tags, webhooks, etc. |
| Core | `Core.Tests.ps1` | ~40 | Data sources, jobs |
| Users | `Users.Tests.ps1` | ~45 | Users, groups, tokens |
| Setup | `Setup.Tests.ps1` | ~15 | Connection functions |
| Helpers | `Helpers.Tests.ps1` | ~100 | Internal utilities |
| Bulk | `BulkOperations.Tests.ps1` | ~200 | Batch operations |
| Errors | `ErrorHandling.Tests.ps1` | ~80 | Error scenarios |

---

### Integration Tests

Integration tests run against a real Netbox instance (typically Docker) to verify API compatibility and CRUD operations work correctly.

#### Characteristics
- **Real API calls**: Actual HTTP requests to Netbox
- **Docker-based**: Uses `docker-compose.ci.yml`
- **Version testing**: Can test multiple Netbox versions
- **CRUD validation**: Create, Read, Update, Delete cycles

#### Test Environment

```yaml
# docker-compose.ci.yml creates:
- Netbox container (configurable version)
- PostgreSQL database
- Redis cache
- Pre-configured admin token
```

#### Running Integration Tests

```powershell
# Start Netbox container
docker compose -f docker-compose.ci.yml up -d
# Wait 2-3 minutes for initialization

# Set environment variables
$env:NETBOX_HOST = 'localhost:8000'
$env:NETBOX_TOKEN = '0123456789abcdef0123456789abcdef01234567'

# Run integration tests
Invoke-Pester ./Tests/Integration.Tests.ps1 -Tag 'Integration'

# Run with specific Netbox version
docker compose -f docker-compose.ci.yml down -v
NETBOX_VERSION=v4.3.7-3.3.0 docker compose -f docker-compose.ci.yml up -d

# Cleanup
docker compose -f docker-compose.ci.yml down -v
```

#### Integration Test Coverage

| Category | Tests | Description |
|----------|-------|-------------|
| Connection | 5 | API connectivity, authentication |
| DCIM Sites | 8 | Site CRUD, filtering |
| DCIM Devices | 12 | Device lifecycle |
| DCIM Interfaces | 10 | Interface management |
| DCIM Racks | 8 | Rack operations |
| IPAM Prefixes | 10 | Prefix hierarchy |
| IPAM Addresses | 12 | IP allocation |
| IPAM VLANs | 8 | VLAN management |
| Virtualization | 15 | VM and cluster ops |
| Tenancy | 10 | Tenant/contact mgmt |
| Circuits | 10 | Circuit lifecycle |
| VPN | 12 | Tunnel configuration |
| Extras | 10 | Tags, custom fields |
| Bulk Operations | 9 | Batch create/update/delete |

---

### Scenario Tests

Scenario tests validate complex, real-world workflows against populated Netbox instances. They use pre-imported test data to verify filter queries, object relationships, and multi-step operations.

#### Characteristics
- **Populated data**: Uses comprehensive test dataset
- **Real workflows**: Server provisioning, network setup, etc.
- **Relationship testing**: Validates object hierarchies
- **Cross-module**: Tests spanning multiple Netbox modules

#### Test Environments

Scenario tests run against the local Docker stacks started with `./scripts/Start-NetboxDocker.ps1` (same matrix as CI):

| Environment | Image tag | Port | Token | Description |
|-------------|-----------|------|-------|-------------|
| `4.7.0` | `v4.7.0-5.1.0` | 8000 | `nbt_powernetbox1.<token>` (v2) | Primary target (default) |
| `4.6.10` | `v4.6.10-5.0.2` | 8001 | `nbt_powernetbox1.<token>` (v2) | Final 4.6.x |
| `4.5.10` | `v4.5.10-4.0.2` | 8002 | v2, created by the script | Stable 4.5.x |
| `4.4.10` | `v4.4.10-3.4.2` | 8003 | `0123...4567` (v1) | Full support |
| `4.3.7` | `v4.3.7-3.3.0` | 8004 | `0123...4567` (v1) | Minimum supported |
| `custom` | - | - | `NETBOX_HOST` / `NETBOX_TOKEN` / `NETBOX_SCHEME` | Any other instance |

```powershell
./scripts/Start-NetboxDocker.ps1 -Version 4.7.0 -SetEnvironment
$env:SCENARIO_ENV = '4.7.0'
Invoke-Pester ./Tests/Scenario/ -Tag Scenario
./scripts/Test-AllNetboxVersions.ps1          # Live integration tests on every version
```

#### Test Data

Scenario tests use the TestData project located at `../TestData/`:

```
TestData/
├── import_testdata.py      # Python script to import test data
├── cleanup_testdata.py     # Python script to cleanup test data
└── Data/
    ├── 00-Tenancy.json          # Tenants, contacts
    ├── 01-DCIM-Base.json        # Regions, sites, manufacturers
    ├── 02-DCIM-Racks.json       # Rack types, racks
    ├── 03-DCIM-Devices.json     # Device types, devices
    ├── 04-IPAM-Base.json        # RIRs, roles, VRFs
    ├── 05-IPAM-Networks.json    # Prefixes, VLANs, IPs
    ├── 06-Virtualization.json   # Clusters, VMs
    ├── 07-Circuits.json         # Providers, circuits
    ├── 08-VPN.json              # Tunnels, IPSec
    ├── 09-Wireless.json         # Wireless LANs
    ├── 10-Extras.json           # Tags, custom fields
    └── ...                      # Additional data files
```

**Test Data Statistics:**
- 116 API endpoints covered
- ~400 objects per environment
- All objects prefixed with `PNB-Test-`

---

## Scenario Test Files

### Filters.Tests.ps1

Tests filter query functionality across all modules.

**Tags:** `Scenario`, `Filters`, `DCIM`, `IPAM`, `Virtualization`, `Tenancy`, `Circuits`, `VPN`, `Extras`, `Pagination`

#### Test Contexts

```
Describe "DCIM Filter Tests"
├── Context "Site Filters"
│   ├── Should filter sites by name prefix
│   ├── Should filter sites by status
│   ├── Should filter sites by region
│   └── Should filter sites by tenant
├── Context "Device Filters"
│   ├── Should filter devices by name prefix
│   ├── Should filter devices by status
│   ├── Should filter devices by site
│   ├── Should filter devices by role
│   ├── Should filter devices by device type
│   ├── Should filter devices by manufacturer
│   ├── Should filter devices by rack
│   └── Should filter devices with has_primary_ip
├── Context "Interface Filters"
│   ├── Should filter interfaces by device
│   ├── Should filter interfaces by type
│   └── Should filter interfaces by enabled status
└── Context "Rack Filters"
    ├── Should filter racks by site
    └── Should filter racks by status

Describe "IPAM Filter Tests"
├── Context "Prefix Filters"
│   ├── Should filter prefixes by VRF
│   ├── Should filter prefixes by status
│   ├── Should filter prefixes by site
│   ├── Should filter prefixes by VLAN
│   └── Should filter prefixes by family (IPv4)
├── Context "IP Address Filters"
│   ├── Should filter addresses by status
│   ├── Should filter addresses by VRF
│   ├── Should filter addresses by tenant
│   └── Should filter addresses by role
└── Context "VLAN Filters"
    ├── Should filter VLANs by VID range
    ├── Should filter VLANs by group
    └── Should filter VLANs by status

Describe "Virtualization Filter Tests"
├── Context "Virtual Machine Filters"
│   ├── Should filter VMs by cluster
│   ├── Should filter VMs by status
│   ├── Should filter VMs by tenant
│   └── Should filter VMs by role
└── Context "Cluster Filters"
    ├── Should filter clusters by type
    └── Should filter clusters by group

Describe "Tenancy Filter Tests"
├── Context "Tenant Filters"
│   ├── Should filter tenants by group
│   └── Should filter tenants by name prefix
└── Context "Contact Filters"
    └── Should filter contacts by group

Describe "Circuits Filter Tests"
└── Context "Circuit Filters"
    ├── Should filter circuits by provider
    ├── Should filter circuits by type
    └── Should filter circuits by status

Describe "VPN Filter Tests"
└── Context "Tunnel Filters"
    ├── Should filter tunnels by status
    └── Should filter tunnels by group

Describe "Tag Filter Tests"
└── Context "Tag-Based Filtering"
    ├── Should filter objects by tag
    └── Should filter sites by tag

Describe "Pagination Tests"
└── Context "Limit and Offset"
    ├── Should respect Limit parameter
    ├── Should paginate correctly with Offset
    └── Should retrieve all results with -All switch
```

---

### Relationships.Tests.ps1

Tests object relationships and hierarchy navigation.

**Tags:** `Scenario`, `Relationships`, `DCIM`, `IPAM`, `Virtualization`, `Tenancy`, `Circuits`, `VPN`, `CrossModule`

#### Test Contexts

```
Describe "DCIM Hierarchy Relationships"
├── Context "Region -> Site -> Location"
│   ├── Should have sites linked to regions
│   ├── Should have locations linked to sites
│   └── Should support nested location hierarchy
├── Context "Site -> Rack -> Device"
│   ├── Should have racks linked to sites
│   ├── Should have devices in racks
│   └── Should have consistent site across rack and devices
├── Context "Device -> Interface -> IP Address"
│   ├── Should have interfaces linked to devices
│   ├── Should have IP addresses assigned to interfaces
│   └── Should have primary IP linked to device
├── Context "Device Type -> Manufacturer"
│   ├── Should have device types linked to manufacturers
│   └── Should have devices using device types
└── Context "Cable Connections"
    └── Should have cables linking interfaces

Describe "IPAM Hierarchy Relationships"
├── Context "Aggregate -> Prefix -> IP Address"
│   ├── Should have aggregates containing prefixes
│   └── Should have prefixes containing IP addresses
├── Context "VRF -> Prefix/Address"
│   └── Should have VRFs with associated prefixes
├── Context "VLAN -> Prefix"
│   └── Should have VLANs linked to prefixes
└── Context "VLAN Group -> VLAN"
    └── Should have VLAN groups containing VLANs

Describe "Virtualization Relationships"
├── Context "Cluster -> Virtual Machine -> Interface"
│   ├── Should have VMs linked to clusters
│   ├── Should have VM interfaces linked to VMs
│   └── Should have IP addresses assigned to VM interfaces
└── Context "Cluster Type/Group -> Cluster"
    └── Should have clusters linked to cluster types

Describe "Tenancy Relationships"
├── Context "Tenant Group -> Tenant"
│   └── Should have tenants linked to tenant groups
├── Context "Tenant -> Resources"
│   ├── Should have tenants associated with sites
│   └── Should have tenants associated with prefixes
└── Context "Contact Assignments"
    └── Should have contacts assigned to objects

Describe "Circuits Relationships"
└── Context "Provider -> Circuit -> Termination"
    ├── Should have circuits linked to providers
    └── Should have circuit terminations linked to sites

Describe "VPN Relationships"
├── Context "IPSec Hierarchy"
│   ├── Should have IPSec profiles linked to policies
│   └── Should have tunnels linked to IPSec profiles
└── Context "Tunnel -> Termination"
    └── Should have tunnel terminations linked to interfaces

Describe "Cross-Module Relationships"
└── Context "Device with full context"
    └── Should retrieve device with all related objects
```

---

### BulkOperations.Tests.ps1

Tests bulk create, update, and delete operations.

**Tags:** `Scenario`, `Bulk`, `DCIM`, `IPAM`, `Virtualization`, `Pipeline`, `Performance`

#### Test Contexts

```
Describe "Bulk Device Operations"
├── Context "Bulk Device Creation"
│   ├── Should create multiple devices via pipeline
│   └── Should create devices with interfaces
├── Context "Bulk Device Updates"
│   ├── Should update multiple devices via pipeline
│   └── Should update device comments in batch
└── Context "Bulk Device Deletion"
    └── Should delete multiple devices via pipeline

Describe "Bulk IP Address Operations"
├── Context "Bulk IP Address Creation"
│   ├── Should create multiple IP addresses in sequence
│   └── Should create IP addresses with VRF assignment
├── Context "Bulk IP Address Updates"
│   └── Should update IP address status in bulk
└── Context "Bulk IP Address Deletion"
    └── Should delete IP addresses via pipeline

Describe "Bulk VM Operations"
├── Context "Bulk VM Creation"
│   ├── Should create multiple VMs via pipeline
│   └── Should create VMs with varying specs
└── Context "Bulk VM Updates"
    └── Should update VM resources in bulk

Describe "Mixed Pipeline Operations"
└── Context "Complex Pipeline Workflows"
    ├── Should chain operations: Create Device -> Add Interfaces -> Assign IPs
    └── Should process mixed object types in sequence

Describe "Batch Size Performance"
└── Context "Batch Size Variations"
    ├── Should handle batch size 1 (many API calls)
    └── Should handle large batch size (few API calls)
```

---

### Workflows.Tests.ps1

Tests end-to-end real-world workflows.

**Tags:** `Scenario`, `Workflow`, `Lifecycle`, `VM`, `Network`, `Inventory`, `ErrorHandling`

#### Test Contexts

```
Describe "Server Lifecycle Workflow"
├── Context "Phase 1: Server Provisioning (Planned)"
│   ├── Should create server in 'planned' state
│   ├── Should provision management interface
│   └── Should assign management IP
├── Context "Phase 2: Server Staging"
│   ├── Should add production interfaces
│   └── Should transition to 'staged' status
├── Context "Phase 3: Server Activation"
│   ├── Should assign production IPs
│   ├── Should set primary IP
│   └── Should transition to 'active' status
├── Context "Phase 4: Verification"
│   └── Should have complete server configuration
└── Context "Phase 5: Decommissioning"
    ├── Should transition to 'decommissioning' status
    └── Should release IP addresses

Describe "VM Provisioning Workflow"
├── Context "VM Creation and Configuration"
│   ├── Should create VM with specifications
│   ├── Should add network interfaces
│   ├── Should assign IP addresses
│   └── Should set primary IP
└── Context "VM Lifecycle Operations"
    ├── Should resize VM resources
    └── Should add comments/documentation

Describe "Network Segment Provisioning Workflow"
├── Context "VLAN and Prefix Setup"
│   ├── Should create VLAN group
│   ├── Should create production VLANs
│   └── Should create prefixes for VLANs
└── Context "IP Address Allocation"
    ├── Should allocate gateway IPs (.1)
    └── Should allocate DHCP range (.100-.200)

Describe "Infrastructure Inventory Workflow"
├── Context "Query and Report Generation"
│   ├── Should generate site inventory report
│   ├── Should generate device type usage report
│   └── Should generate IP utilization report
└── Context "Cross-Reference Queries"
    ├── Should find devices without primary IP
    └── Should find VMs with low resources

Describe "Error Handling Workflow"
└── Context "Graceful Error Recovery"
    ├── Should handle missing referenced object
    ├── Should handle invalid filter values
    └── Should validate required fields on create
```

---

## Running Tests

### Command Reference

```powershell
# ═══════════════════════════════════════════════════════════════════
# UNIT TESTS
# ═══════════════════════════════════════════════════════════════════

# All unit tests
Invoke-Pester ./Tests/ -ExcludeTag 'Integration', 'Scenario', 'Live'

# Specific module
Invoke-Pester ./Tests/DCIM.Devices.Tests.ps1

# Multiple modules
Invoke-Pester ./Tests/DCIM*.Tests.ps1

# With verbose output
Invoke-Pester ./Tests/IPAM.Tests.ps1 -Output Detailed

# With code coverage
$config = New-PesterConfiguration
$config.Run.Path = './Tests/'
$config.Run.ExcludeTag = @('Integration', 'Scenario', 'Live')
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = @('./Functions/**/*.ps1')
Invoke-Pester -Configuration $config


# ═══════════════════════════════════════════════════════════════════
# INTEGRATION TESTS
# ═══════════════════════════════════════════════════════════════════

# Start Docker environment
docker compose -f docker-compose.ci.yml up -d
Start-Sleep -Seconds 120  # Wait for initialization

# Set credentials
$env:NETBOX_HOST = 'localhost:8000'
$env:NETBOX_TOKEN = '0123456789abcdef0123456789abcdef01234567'

# Run all integration tests
Invoke-Pester ./Tests/Integration.Tests.ps1 -Tag 'Integration'

# Run specific integration category
Invoke-Pester ./Tests/Integration.Tests.ps1 -Tag 'Integration', 'DCIM'

# With different Netbox version
docker compose -f docker-compose.ci.yml down -v
$env:NETBOX_VERSION = 'v4.3.7-3.3.0'
docker compose -f docker-compose.ci.yml up -d

# Cleanup
docker compose -f docker-compose.ci.yml down -v


# ═══════════════════════════════════════════════════════════════════
# SCENARIO TESTS
# ═══════════════════════════════════════════════════════════════════

# Set environment (4.3.7, 4.4.9, or 4.5.0)
$env:SCENARIO_ENV = '4.4.9'

# Run all scenario tests
Invoke-Pester ./Tests/Scenario/ -Tag 'Scenario'

# Run specific scenario category
Invoke-Pester ./Tests/Scenario/Filters.Tests.ps1 -Tag 'Filters'
Invoke-Pester ./Tests/Scenario/Relationships.Tests.ps1 -Tag 'Relationships'
Invoke-Pester ./Tests/Scenario/BulkOperations.Tests.ps1 -Tag 'Bulk'
Invoke-Pester ./Tests/Scenario/Workflows.Tests.ps1 -Tag 'Workflow'

# Skip data import (if already populated)
$env:SCENARIO_SKIP_IMPORT = '1'
Invoke-Pester ./Tests/Scenario/

# Run specific workflow
Invoke-Pester ./Tests/Scenario/Workflows.Tests.ps1 -Tag 'Lifecycle'


# ═══════════════════════════════════════════════════════════════════
# FULL TEST SUITE
# ═══════════════════════════════════════════════════════════════════

# Run everything (requires Docker + Scenario environments)
$config = New-PesterConfiguration
$config.Run.Path = './Tests/'
$config.Output.Verbosity = 'Detailed'
$config.TestResult.Enabled = $true
$config.TestResult.OutputPath = './test-results.xml'
Invoke-Pester -Configuration $config
```

### Using Tags

Tests are organized with the following tags:

| Tag | Description | Example |
|-----|-------------|---------|
| `Unit` | Unit tests (mocked) | All root-level test files |
| `Integration` | Integration tests | `Integration.Tests.ps1` |
| `Live` | Requires live API | Bulk operation live tests |
| `Scenario` | Scenario tests | `Scenario/*.Tests.ps1` |
| `Filters` | Filter query tests | Scenario filter tests |
| `Relationships` | Relationship tests | Object hierarchy tests |
| `Bulk` | Bulk operation tests | Pipeline operations |
| `Workflow` | Workflow tests | End-to-end scenarios |
| `DCIM` | DCIM module tests | Device, site, rack tests |
| `IPAM` | IPAM module tests | IP, prefix, VLAN tests |
| `Virtualization` | VM tests | VM, cluster tests |
| `Tenancy` | Tenancy tests | Tenant, contact tests |
| `Circuits` | Circuit tests | Circuit, provider tests |
| `VPN` | VPN tests | Tunnel, IPSec tests |
| `Wireless` | Wireless tests | WLAN tests |
| `Extras` | Extras tests | Tag, webhook tests |
| `Performance` | Performance tests | Batch size tests |

```powershell
# Include tags
Invoke-Pester ./Tests/ -Tag 'DCIM', 'IPAM'

# Exclude tags
Invoke-Pester ./Tests/ -ExcludeTag 'Integration', 'Scenario'

# Combine include and exclude
Invoke-Pester ./Tests/ -Tag 'Bulk' -ExcludeTag 'Live'
```

---

## Environment Setup

### Prerequisites

| Requirement | Version | Purpose |
|-------------|---------|---------|
| PowerShell | 5.1+ or 7.x | Test execution |
| Pester | 5.0+ | Test framework |
| Docker | Latest | Integration tests |
| Python 3 | 3.8+ | Scenario test data import |
| requests | Latest | Python HTTP client |

### Installation

```powershell
# Install Pester
Install-Module Pester -MinimumVersion 5.0 -Force -SkipPublisherCheck

# Verify installation
Get-Module Pester -ListAvailable

# Install Python dependencies (for scenario tests)
pip install requests
```

### Configuration Files

#### credential.example.ps1

Template for integration test credentials:

```powershell
# Copy to credential.ps1 (gitignored)
$env:NETBOX_HOST = 'localhost:8000'
$env:NETBOX_TOKEN = 'your-api-token-here'
```

#### common.ps1

Shared test configuration loaded by all test files:

```powershell
# Module import
Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue
Import-Module (Join-Path $PSScriptRoot ".." "PowerNetbox.psd1") -Force
```

---

## Test Data Management

### Scenario Test Data

The scenario tests use the TestData project to manage test objects in live Netbox instances.

#### Importing Test Data

```bash
# Navigate to TestData directory
cd ../TestData

# Import to specific environment
python3 import_testdata.py 4.4.9    # Netbox 4.4.9
python3 import_testdata.py 4.3.7    # Netbox 4.3.7
python3 import_testdata.py 4.5.0    # Netbox 4.5.0

# Or use PowerShell helper
Import-Module ./Tests/Scenario/ScenarioTestHelper.psm1
Connect-ScenarioTest -Environment '4.4.9'
Import-ScenarioTestData -Force
```

#### Cleaning Up Test Data

```bash
# Cleanup specific environment
python3 cleanup_testdata.py 4.4.9

# Or use PowerShell helper
Remove-ScenarioTestData -Environment '4.4.9'
```

#### Test Data Contents

| Category | Objects | Description |
|----------|---------|-------------|
| Tenancy | ~15 | Tenants, contacts, roles |
| DCIM Base | ~30 | Regions, sites, manufacturers |
| DCIM Racks | ~15 | Rack types, racks, reservations |
| DCIM Devices | ~40 | Device types, devices |
| IPAM Base | ~20 | RIRs, roles, VRFs, aggregates |
| IPAM Networks | ~50 | Prefixes, VLANs, IP addresses |
| Virtualization | ~25 | Clusters, VMs, interfaces |
| Circuits | ~15 | Providers, circuits, terminations |
| VPN | ~20 | Tunnels, IPSec configurations |
| Wireless | ~10 | Wireless LANs, groups |
| Extras | ~30 | Tags, custom fields, webhooks |
| Components | ~50 | Interfaces, cables, modules |
| Users | ~10 | Users, groups, tokens |

**All objects use the prefix `PNB-Test-`** for easy identification and cleanup.

---

## CI/CD Integration

### GitHub Actions Workflows

| Workflow | Trigger | Tests Run |
|----------|---------|-----------|
| `test.yml` | Push/PR | Unit tests (3 OS × 2 PS versions) |
| `integration.yml` | Push/PR | Docker-based integration tests |
| `compatibility.yml` | Manual | All Netbox versions (4.1-4.5) |
| `pre-release-validation.yml` | Manual | Full test suite |

### Running in CI

```yaml
# Example GitHub Actions step
- name: Run Unit Tests
  shell: pwsh
  run: |
    Install-Module Pester -Force -SkipPublisherCheck
    $config = New-PesterConfiguration
    $config.Run.Path = './Tests/'
    $config.Run.ExcludeTag = @('Integration', 'Scenario', 'Live')
    $config.TestResult.Enabled = $true
    $config.TestResult.OutputPath = './test-results.xml'
    Invoke-Pester -Configuration $config

- name: Upload Test Results
  uses: actions/upload-artifact@v4
  with:
    name: test-results
    path: test-results.xml
```

### Pre-Release Validation

Before releasing, run the full validation:

```powershell
# Via GitHub CLI
gh workflow run pre-release-validation.yml --field version=4.4.9.3

# What it tests:
# - Unit tests on 4 platform combinations
# - PSScriptAnalyzer code quality
# - Integration tests against Netbox 4.1, 4.2, 4.3, 4.4
# - Module import verification
```

---

## Troubleshooting

### Common Issues

#### Module Not Loading

```powershell
# Force reimport
Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue
Import-Module ./PowerNetbox.psd1 -Force

# Check for syntax errors
$errors = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile(
    './PowerNetbox.psd1', [ref]$null, [ref]$errors
)
$errors
```

#### Integration Tests Failing

```powershell
# Check Docker is running
docker ps

# Verify Netbox is responding
curl http://localhost:8000/api/status/

# Check credentials
$env:NETBOX_HOST
$env:NETBOX_TOKEN

# Restart Netbox container
docker compose -f docker-compose.ci.yml restart
```

#### Scenario Tests Skipping

```powershell
# Check test data exists
Connect-ScenarioTest -Environment '4.4.9'
Test-ScenarioTestData

# Reimport test data
Import-ScenarioTestData -Force

# Check for API errors in import
python3 ../TestData/import_testdata.py 4.4.9 2>&1 | Select-String "ERROR"
```

#### Slow Test Execution

```powershell
# Run only changed tests
Invoke-Pester ./Tests/DCIM.Devices.Tests.ps1

# Skip slow tests
Invoke-Pester ./Tests/ -ExcludeTag 'Slow', 'Performance'

# Use parallel execution (Pester 5.3+)
$config = New-PesterConfiguration
$config.Run.Path = './Tests/'
$config.Run.Parallel = $true
Invoke-Pester -Configuration $config
```

### Debug Mode

```powershell
# Enable verbose output
$VerbosePreference = 'Continue'
Invoke-Pester ./Tests/DCIM.Devices.Tests.ps1 -Output Diagnostic

# Debug specific test
Invoke-Pester ./Tests/DCIM.Devices.Tests.ps1 -FullNameFilter "*Should create device*"
```

---

## Contributing

### Writing New Tests

1. **Choose the right category:**
   - Unit tests for function logic
   - Integration tests for API compatibility
   - Scenario tests for workflows

2. **Follow naming conventions:**
   - `[Module].Tests.ps1` for unit tests
   - Descriptive test names using "Should..."

3. **Use appropriate tags:**
   ```powershell
   Describe "New Feature Tests" -Tag 'Unit', 'DCIM' {
       It "Should perform expected behavior" {
           # Test code
       }
   }
   ```

4. **Include setup and cleanup:**
   ```powershell
   BeforeAll {
       # Setup mocks or test data
   }

   AfterAll {
       # Cleanup created objects
   }
   ```

### Test Guidelines

- **Isolation**: Each test should be independent
- **Clarity**: Test names should describe expected behavior
- **Completeness**: Cover success paths, error paths, and edge cases
- **Speed**: Keep unit tests fast (<100ms each)
- **Cleanup**: Always clean up created objects in scenario tests

### Pull Request Checklist

- [ ] All existing tests pass
- [ ] New tests added for new functionality
- [ ] Tests run on all supported PowerShell versions
- [ ] No hardcoded credentials or URLs
- [ ] Test data uses `PNB-Test-` prefix

---

## License

This test suite is part of PowerNetbox and is licensed under the MIT License.
