# Performance Optimization

PowerNetbox implements [NetBox REST API best practices](https://github.com/netboxlabs/netbox-best-practices) to optimize API performance. These features can dramatically reduce response times and payload sizes.

## Overview

| Feature | Parameter | Effect | Best For |
|---------|-----------|--------|----------|
| Brief Mode | `-Brief` | ~90% smaller payload | Dropdowns, lists |
| Field Selection | `-Fields` | Custom fields only | Reports, specific needs |
| Field Omission | `-Omit` | Exclude specific fields | Removing large/unused fields |
| Exclude Config Context | Default behavior | 10-100x faster | Most device/VM queries |
| Include Config Context | `-IncludeConfigContext` | Include config_context | When you need rendered config |

## Brief Mode

The `-Brief` switch returns a minimal representation of objects containing only essential fields: `id`, `url`, `display`, and `name`.

```powershell
# Full response (all fields)
Get-NBDCIMDevice -Name 'server01'

# Brief response (~90% smaller)
Get-NBDCIMDevice -Name 'server01' -Brief
```

### When to Use Brief Mode

- **Dropdowns and select lists** - You only need id and name
- **Reference lookups** - Finding IDs for related objects
- **Large result sets** - When processing many objects
- **Low-bandwidth connections** - Minimize data transfer

### Example: Populate a Dropdown

```powershell
# Get all sites for a dropdown (minimal data)
$sites = Get-NBDCIMSite -Brief

# Returns objects like:
# @{
#     id = 1
#     url = 'https://netbox.example.com/api/dcim/sites/1/'
#     display = 'Main DC'
#     name = 'Main DC'
# }
```

## Field Selection

The `-Fields` parameter allows you to specify exactly which fields to include in the response. This is more flexible than Brief mode when you need specific fields.

```powershell
# Get only specific fields
Get-NBDCIMDevice -Fields 'id','name','status','serial'

# Include nested fields (use dot notation)
Get-NBDCIMDevice -Fields 'id','name','site.name','device_type.model'
```

### When to Use Field Selection

- **Reports** - Extract specific data for reporting
- **Data export** - Get only the fields you need
- **Custom dashboards** - Reduce API overhead
- **Performance-critical scripts** - Minimize data transfer

### Example: Export Device Report

```powershell
# Get device data for a report
$devices = Get-NBDCIMDevice -Status 'active' -Fields 'id','name','serial','site.name','rack.name'

# Export to CSV
$devices | Select-Object id, name, serial,
    @{N='Site';E={$_.site.name}},
    @{N='Rack';E={$_.rack.name}} |
    Export-Csv -Path 'devices.csv' -NoTypeInformation
```

## Field Omission

The `-Omit` parameter allows you to exclude specific fields from the response. This is the inverse of `-Fields` - you specify what to remove rather than what to include.

**Requires Netbox 4.5.0 or later.**

```powershell
# Exclude comments and description fields
Get-NBDCIMDevice -Omit 'comments','description'

# Exclude large nested objects
Get-NBDCIMSite -Omit 'asns','prefixes'
```

### When to Use Field Omission

- **Remove large text fields** - `comments`, `description` can be verbose
- **Exclude unused relationships** - Skip nested objects you don't need
- **Combine with config_context exclusion** - `-Omit` adds to the default exclusion

### Example: Lightweight Device List

```powershell
# Exclude verbose fields for a lightweight response
Get-NBDCIMDevice -All -Omit 'comments','description','local_context_data'
```

## Config Context Exclusion

By default, PowerNetbox excludes `config_context` from device and VM responses. This can improve performance by **10-100x** because config_context requires server-side rendering of hierarchical configuration data.

### Default Behavior (Fast)

```powershell
# config_context is automatically excluded
Get-NBDCIMDevice

# Equivalent to (Netbox 4.5+):
# GET /api/dcim/devices/?omit=config_context
```

### Include Config Context When Needed

```powershell
# Explicitly include config_context
Get-NBDCIMDevice -IncludeConfigContext

# Or for a specific device
Get-NBDCIMDevice -Id 1 -IncludeConfigContext
```

### When to Include Config Context

- **Configuration management** - Generating device configs
- **Ansible/Terraform** - Using Netbox as source of truth
- **Automation scripts** - When you need rendered configuration

### Performance Impact

| Scenario | Without config_context | With config_context |
|----------|------------------------|---------------------|
| 100 devices | ~200ms | ~2-20 seconds |
| 1000 devices | ~2 seconds | ~20-200 seconds |
| Complex hierarchy | Minimal impact | Significant slowdown |

## Query Parameter Warning

The `-Query` parameter performs a broad text search across multiple fields. On large datasets, this can be slow.

```powershell
# This triggers a warning
Get-NBDCIMDevice -Query 'server'
# WARNING: The -Query parameter can be slow on large datasets.
# Consider using specific filters like -Name for better performance.

# Better: Use specific filters
Get-NBDCIMDevice -Name 'server*'
Get-NBDCIMDevice -Name__ic 'server'  # Case-insensitive contains
```

### Filter Alternatives

| Instead of | Use |
|------------|-----|
| `-Query 'server'` | `-Name 'server*'` or `-Name__ic 'server'` |
| `-Query '10.0.0'` | `-Address__startswith '10.0.0'` |
| `-Query 'DC1'` | `-Site_Id 1` or `-Site 'DC1'` |

## Combining Optimizations

For maximum performance, combine multiple optimization techniques:

```powershell
# Most efficient: specific filters + brief mode
Get-NBDCIMDevice -Site_Id 1 -Status 'active' -Brief

# For reports: specific filters + field selection
Get-NBDCIMDevice -Site_Id 1 -Fields 'id','name','status','primary_ip4.address'

# Pagination for large datasets
Get-NBDCIMDevice -Status 'active' -Brief -Limit 100 -Offset 0
```

## Best Practices Summary

1. **Always use specific filters** instead of `-Query`
2. **Use `-Brief`** for dropdowns and reference lists
3. **Use `-Fields`** for reports and custom data extraction
4. **Use `-Omit`** to exclude large or unused fields (Netbox 4.5+)
5. **Let config_context be excluded** by default
6. **Only use `-IncludeConfigContext`** when you need rendered configuration
7. **Use pagination** (`-Limit`, `-Offset`) for large result sets
8. **Use `-All` with `-PageSize`** for automatic pagination

## See Also

- [Getting Started](../getting-started/connecting.md) - Basic setup and connection
- [Bulk Operations](bulk-operations.md) - High-performance batch processing
- [Common Workflows](common-workflows.md) - Real-world examples
- [NetBox Best Practices](https://github.com/netboxlabs/netbox-best-practices) - Official documentation

## Cursor Pagination (NetBox 4.6+)

`-All` pages with `limit`/`offset` by default. On very large tables (IP addresses, interfaces, change log) offset paging gets slower with every page because the database has to skip the preceding rows. NetBox 4.6 added cursor pagination (`?start=<pk>`), which is constant-time per page.

```powershell
Set-NBQueryOption -Pagination Cursor
$ips = Get-NBIPAMAddress -All -PageSize 500     # walks the table by primary key
Set-NBQueryOption -Pagination Offset            # back to the default
```

- Results are ordered by primary key, not by the endpoint's default ordering.
- `count` is not reported per page in cursor mode; the returned array is complete.
- Below NetBox 4.6 the option is ignored (offset paging, with a one-time warning when you set it).
- The pagination `next` URL is still validated against the original host (same SSRF guard as offset paging).

## Background Bulk Writes (NetBox 4.7+)

Large bulk creates/updates can exceed proxy or gateway timeouts. NetBox 4.7 can queue a bulk write as a background job:

```powershell
$devices | New-NBDCIMDevice -BatchSize 500 -Background -Force   # returns job objects (HTTP 202)
Get-NBJob -Id <job id>                                           # status, and the response the sync call would have returned
```

Validation happens in the worker, so a 202 only means "accepted"; check the job for the real outcome. Requires a running RQ worker on the NetBox server.

## Optimistic Concurrency (NetBox 4.6+)

When several people or scripts edit the same objects, enable ETag / If-Match checking so a stale write fails instead of overwriting:

```powershell
Set-NBQueryOption -OptimisticConcurrency
$dev = Get-NBDCIMDevice -Id 42                      # ETag cached
Set-NBDCIMDevice -Id 42 -Description 'changed'      # sent with If-Match; 412 if the device changed in between
```

Needs PowerShell 7+ (response headers are not exposed on Windows PowerShell 5.1; the option then warns once and updates are sent without If-Match).
