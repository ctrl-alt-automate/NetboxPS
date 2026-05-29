<#
.SYNOPSIS
    Integration tests for PowerNetbox module.

.DESCRIPTION
    These tests verify API interaction patterns and response parsing using mock responses.
    They can be run against a mock server or actual Netbox instance for full integration testing.

.NOTES
    Run with: Invoke-Pester -Path ./Tests/Integration.Tests.ps1 -Tag 'Integration'

    For live testing, set environment variables:
    $env:NETBOX_HOST = 'your-netbox-host.com'
    $env:NETBOX_TOKEN = 'your-api-token'
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

BeforeDiscovery {
    $script:ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
    $script:LiveTesting = $env:NETBOX_HOST -and $env:NETBOX_TOKEN
}

BeforeAll {
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -ErrorAction Stop
    }
}

Describe "Integration Tests - Mock API Responses" -Tag 'Integration', 'Mock' {
    BeforeAll {
        # Mock standard Netbox API responses
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { $true }
        Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
            [PSCredential]::new('api', (ConvertTo-SecureString -String "testtoken" -AsPlainText -Force))
        }
        Mock -CommandName 'Get-NBHostname' -ModuleName 'PowerNetbox' -MockWith { 'netbox.test.local' }
        Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 30 }
        Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }

        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = 'netbox.test.local'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }
    }

    Context "DCIM Module - API Path Verification" {
        BeforeAll {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    count   = 1
                    results = @(
                        @{
                            id   = 1
                            name = 'test-device'
                            url  = 'https://netbox.test.local/api/dcim/devices/1/'
                        }
                    )
                }
            }
        }

        It "Get-NBDCIMDevice uses correct API path" {
            $result = Get-NBDCIMDevice -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/dcim/devices/'
            }
        }

        It "Get-NBDCIMSite uses correct API path" {
            $result = Get-NBDCIMSite -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/dcim/sites/'
            }
        }

        It "Get-NBDCIMRack uses correct API path" {
            $result = Get-NBDCIMRack -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/dcim/racks/'
            }
        }

        It "Get-NBDCIMManufacturer uses correct API path" {
            $result = Get-NBDCIMManufacturer -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/dcim/manufacturers/'
            }
        }
    }

    Context "IPAM Module - API Path Verification" {
        BeforeAll {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    count   = 1
                    results = @(@{ id = 1; address = '10.0.0.1/24' })
                }
            }
        }

        It "Get-NBIPAMAddress uses correct API path" {
            $result = Get-NBIPAMAddress -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/ipam/ip-addresses/'
            }
        }

        It "Get-NBIPAMPrefix uses correct API path" {
            $result = Get-NBIPAMPrefix -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/ipam/prefixes/'
            }
        }

        It "Get-NBIPAMVLAN uses correct API path" {
            $result = Get-NBIPAMVLAN -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/ipam/vlans/'
            }
        }

        It "Get-NBIPAMVRF uses correct API path" {
            $result = Get-NBIPAMVRF -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/ipam/vrfs/'
            }
        }
    }

    Context "VPN Module - API Path Verification" {
        BeforeAll {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    count   = 0
                    results = @()
                }
            }
        }

        It "Get-NBVPNTunnel uses correct API path" {
            $result = Get-NBVPNTunnel -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/vpn/tunnels/'
            }
        }

        It "Get-NBVPNL2VPN uses correct API path" {
            $result = Get-NBVPNL2VPN -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/vpn/l2vpns/'
            }
        }

        It "Get-NBVPNIKEPolicy uses correct API path" {
            $result = Get-NBVPNIKEPolicy -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/vpn/ike-policies/'
            }
        }

        It "Get-NBVPNIPSecProfile uses correct API path" {
            $result = Get-NBVPNIPSecProfile -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/vpn/ipsec-profiles/'
            }
        }
    }

    Context "Wireless Module - API Path Verification" {
        BeforeAll {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    count   = 0
                    results = @()
                }
            }
        }

        It "Get-NBWirelessLAN uses correct API path" {
            $result = Get-NBWirelessLAN -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/wireless/wireless-lans/'
            }
        }

        It "Get-NBWirelessLANGroup uses correct API path" {
            $result = Get-NBWirelessLANGroup -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/wireless/wireless-lan-groups/'
            }
        }

        It "Get-NBWirelessLink uses correct API path" {
            $result = Get-NBWirelessLink -Limit 1

            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Uri -match '/api/wireless/wireless-links/'
            }
        }
    }

    Context "Response Parsing" {
        It "Should parse paginated response correctly" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    count    = 150
                    next     = 'https://netbox.test.local/api/dcim/devices/?limit=50&offset=50'
                    previous = $null
                    results  = @(
                        @{ id = 1; name = 'device-1' }
                        @{ id = 2; name = 'device-2' }
                    )
                }
            }

            $result = Get-NBDCIMDevice -Limit 2
            # The module calls Invoke-RestMethod and processes results
            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -Times 1
            # Result is returned from InvokeNetboxRequest which extracts .results
            $result | Should -Not -BeNullOrEmpty
        }

        It "Should handle empty results" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    count   = 0
                    results = @()
                }
            }

            $result = Get-NBDCIMDevice -Name 'nonexistent'
            $result | Should -BeNullOrEmpty
        }

        It "Should handle single object response (by ID)" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                return @{
                    id   = 42
                    name = 'specific-device'
                    url  = 'https://netbox.test.local/api/dcim/devices/42/'
                }
            }

            $result = Get-NBDCIMDevice -Id 42
            $result.id | Should -Be 42
            $result.name | Should -Be 'specific-device'
        }
    }

    Context "Error Handling" {
        It "Should handle 404 Not Found gracefully" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [System.Net.WebException]::new("The remote server returned an error: (404) Not Found."),
                    "WebException",
                    [System.Management.Automation.ErrorCategory]::ResourceUnavailable,
                    $null
                )
                throw $errorRecord
            }

            { Get-NBDCIMDevice -Id 99999 } | Should -Throw
        }

        It "Should handle 401 Unauthorized" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [System.Net.WebException]::new("The remote server returned an error: (401) Unauthorized."),
                    "WebException",
                    [System.Management.Automation.ErrorCategory]::PermissionDenied,
                    $null
                )
                throw $errorRecord
            }

            { Get-NBDCIMDevice } | Should -Throw
        }
    }

    Context "SupportsShouldProcess" {
        BeforeAll {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                return @{ id = 1; name = 'test' }
            }
        }

        It "New-NBDCIMSite supports -WhatIf" {
            $result = New-NBDCIMSite -Name 'test-site' -Slug 'test-site' -WhatIf

            # With -WhatIf, Invoke-RestMethod should not be called
            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -Times 0
        }

        It "Set-NBDCIMSite supports -WhatIf" {
            Mock -CommandName 'Get-NBDCIMSite' -ModuleName 'PowerNetbox' -MockWith {
                return @{ id = 1; name = 'test-site' }
            }

            $result = Set-NBDCIMSite -Id 1 -Description 'Updated' -WhatIf

            # The PATCH call should not happen with -WhatIf
            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Method -eq 'PATCH'
            } -Times 0
        }

        It "Remove-NBDCIMSite supports -WhatIf" {
            Mock -CommandName 'Get-NBDCIMSite' -ModuleName 'PowerNetbox' -MockWith {
                return @{ id = 1; name = 'test-site' }
            }

            $result = Remove-NBDCIMSite -Id 1 -WhatIf

            # The DELETE call should not happen with -WhatIf
            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -ParameterFilter {
                $Method -eq 'DELETE'
            } -Times 0
        }
    }
}

Describe "Live Integration Tests" -Tag 'Integration', 'Live' -Skip:(-not $script:LiveTesting) {
    BeforeAll {
        $secureToken = ConvertTo-SecureString -String $env:NETBOX_TOKEN -AsPlainText -Force
        $credential = [PSCredential]::new('api', $secureToken)

        # Parse hostname and port (supports "hostname" or "hostname:port" format)
        $hostValue = $env:NETBOX_HOST
        $hostname = $hostValue
        $port = $null

        if ($hostValue -match '^(.+):(\d+)$') {
            $hostname = $Matches[1]
            $port = [int]$Matches[2]
        }

        # Determine scheme - default to http for Docker CI, https for cloud
        $scheme = $env:NETBOX_SCHEME
        if ([string]::IsNullOrEmpty($scheme)) {
            # Docker CI uses http on localhost
            if ($hostname -match 'localhost|127\.0\.0\.1') {
                $scheme = 'http'
            }
            else {
                $scheme = 'https'
            }
        }

        $connectParams = @{
            Hostname   = $hostname
            Credential = $credential
            Scheme     = $scheme
        }

        # Add port if specified
        if ($port) {
            $connectParams['Port'] = $port
        }

        # Only skip certificate check for https
        if ($scheme -eq 'https') {
            $connectParams['SkipCertificateCheck'] = $true
        }

        Connect-NBAPI @connectParams

        # Generate unique test prefix for this run
        $script:TestRunId = [guid]::NewGuid().ToString().Substring(0, 8)
        $script:TestPrefix = "LiveTest-$($script:TestRunId)"

        # Track created resources for cleanup (order matters - delete dependents first)
        $script:CreatedResources = @{
            # Level 1: Most dependent resources (delete first)
            Devices             = [System.Collections.ArrayList]::new()
            ContactAssignments  = [System.Collections.ArrayList]::new()
            VMs                 = [System.Collections.ArrayList]::new()
            Interfaces          = [System.Collections.ArrayList]::new()
            # Level 2: Mid-level resources
            Addresses           = [System.Collections.ArrayList]::new()
            Prefixes            = [System.Collections.ArrayList]::new()
            VLANs               = [System.Collections.ArrayList]::new()
            # Level 3: Reference data
            DeviceTypes         = [System.Collections.ArrayList]::new()
            DeviceRoles         = [System.Collections.ArrayList]::new()
            Manufacturers       = [System.Collections.ArrayList]::new()
            Clusters            = [System.Collections.ArrayList]::new()
            ClusterTypes        = [System.Collections.ArrayList]::new()
            Sites               = [System.Collections.ArrayList]::new()
            Tenants             = [System.Collections.ArrayList]::new()
            Tags                = [System.Collections.ArrayList]::new()
            Contacts            = [System.Collections.ArrayList]::new()
            ContactRoles        = [System.Collections.ArrayList]::new()
            ContactGroups       = [System.Collections.ArrayList]::new()
        }

        Write-Host "Test Run ID: $script:TestRunId" -ForegroundColor Cyan
    }

    AfterAll {
        Write-Host "`nCleaning up live test resources..." -ForegroundColor Yellow

        # Track cleanup errors for reporting
        $cleanupErrors = [System.Collections.ArrayList]::new()

        # Helper function for safe resource removal
        function Remove-TestResource {
            param($ResourceType, $Id, $RemoveCommand)
            try {
                & $RemoveCommand -Id $Id -Confirm:$false -ErrorAction Stop
            }
            catch {
                [void]$cleanupErrors.Add("Failed to remove $ResourceType ID ${Id}: $($_.Exception.Message)")
            }
        }

        # Cleanup in reverse dependency order (most dependent first)

        # Level 1: Most dependent resources
        # ContactAssignments first — NetBox cascades them when their target (Device/VM/Site/…) is removed,
        # so deleting the target before the assignment causes the explicit cleanup to 404.
        foreach ($id in $script:CreatedResources.ContactAssignments) {
            Remove-TestResource -ResourceType 'ContactAssignment' -Id $id -RemoveCommand { param($Id, $Confirm, $ErrorAction) Remove-NBContactAssignment -Id $Id -Confirm:$Confirm -ErrorAction $ErrorAction }
        }
        foreach ($id in $script:CreatedResources.Devices) {
            Remove-TestResource -ResourceType 'Device' -Id $id -RemoveCommand { param($Id, $Confirm, $ErrorAction) Remove-NBDCIMDevice -Id $Id -Confirm:$Confirm -ErrorAction $ErrorAction }
        }
        foreach ($id in $script:CreatedResources.VMs) {
            Remove-TestResource -ResourceType 'VM' -Id $id -RemoveCommand { param($Id, $Confirm, $ErrorAction) Remove-NBVirtualMachine -Id $Id -Confirm:$Confirm -ErrorAction $ErrorAction }
        }
        foreach ($id in $script:CreatedResources.Interfaces) {
            Remove-TestResource -ResourceType 'Interface' -Id $id -RemoveCommand { param($Id, $Confirm, $ErrorAction) Remove-NBDCIMInterface -Id $Id -Confirm:$Confirm -ErrorAction $ErrorAction }
        }

        # Level 2: Mid-level resources
        foreach ($id in $script:CreatedResources.Addresses) {
            Remove-TestResource -ResourceType 'Address' -Id $id -RemoveCommand { param($Id, $Confirm, $ErrorAction) Remove-NBIPAMAddress -Id $Id -Confirm:$Confirm -ErrorAction $ErrorAction }
        }
        foreach ($id in $script:CreatedResources.Prefixes) {
            Remove-TestResource -ResourceType 'Prefix' -Id $id -RemoveCommand { param($Id, $Confirm, $ErrorAction) Remove-NBIPAMPrefix -Id $Id -Confirm:$Confirm -ErrorAction $ErrorAction }
        }
        foreach ($id in $script:CreatedResources.VLANs) {
            Remove-TestResource -ResourceType 'VLAN' -Id $id -RemoveCommand { param($Id, $Confirm, $ErrorAction) Remove-NBIPAMVLAN -Id $Id -Confirm:$Confirm -ErrorAction $ErrorAction }
        }

        # Level 3: Reference data
        foreach ($id in $script:CreatedResources.DeviceTypes) {
            Remove-TestResource -ResourceType 'DeviceType' -Id $id -RemoveCommand { param($Id, $Confirm, $ErrorAction) Remove-NBDCIMDeviceType -Id $Id -Confirm:$Confirm -ErrorAction $ErrorAction }
        }
        foreach ($id in $script:CreatedResources.DeviceRoles) {
            Remove-TestResource -ResourceType 'DeviceRole' -Id $id -RemoveCommand { param($Id, $Confirm, $ErrorAction) Remove-NBDCIMDeviceRole -Id $Id -Confirm:$Confirm -ErrorAction $ErrorAction }
        }
        foreach ($id in $script:CreatedResources.Manufacturers) {
            Remove-TestResource -ResourceType 'Manufacturer' -Id $id -RemoveCommand { param($Id, $Confirm, $ErrorAction) Remove-NBDCIMManufacturer -Id $Id -Confirm:$Confirm -ErrorAction $ErrorAction }
        }
        foreach ($id in $script:CreatedResources.Clusters) {
            Remove-TestResource -ResourceType 'Cluster' -Id $id -RemoveCommand { param($Id, $Confirm, $ErrorAction) Remove-NBVirtualizationCluster -Id $Id -Confirm:$Confirm -ErrorAction $ErrorAction }
        }
        foreach ($id in $script:CreatedResources.ClusterTypes) {
            Remove-TestResource -ResourceType 'ClusterType' -Id $id -RemoveCommand { param($Id, $Confirm, $ErrorAction) Remove-NBVirtualizationClusterType -Id $Id -Confirm:$Confirm -ErrorAction $ErrorAction }
        }
        foreach ($id in $script:CreatedResources.Sites) {
            Remove-TestResource -ResourceType 'Site' -Id $id -RemoveCommand { param($Id, $Confirm, $ErrorAction) Remove-NBDCIMSite -Id $Id -Confirm:$Confirm -ErrorAction $ErrorAction }
        }
        foreach ($id in $script:CreatedResources.Tenants) {
            Remove-TestResource -ResourceType 'Tenant' -Id $id -RemoveCommand { param($Id, $Confirm, $ErrorAction) Remove-NBTenant -Id $Id -Confirm:$Confirm -ErrorAction $ErrorAction }
        }
        foreach ($id in $script:CreatedResources.Tags) {
            Remove-TestResource -ResourceType 'Tag' -Id $id -RemoveCommand { param($Id, $Confirm, $ErrorAction) Remove-NBTag -Id $Id -Confirm:$Confirm -ErrorAction $ErrorAction }
        }
        foreach ($id in $script:CreatedResources.Contacts) {
             Remove-TestResource -ResourceType 'Contact' -Id $id -RemoveCommand { param($Id, $Confirm, $ErrorAction) Remove-NBContact -Id $Id -Confirm:$Confirm -ErrorAction $ErrorAction }
        }
        foreach ($id in $script:CreatedResources.ContactRoles) {
            Remove-TestResource -ResourceType 'ContactRole' -Id $id -RemoveCommand { param($Id, $Confirm, $ErrorAction) Remove-NBContactRole -Id $Id -Confirm:$Confirm -ErrorAction $ErrorAction }
        }
        foreach ($id in $script:CreatedResources.ContactGroups) {
             Remove-TestResource -ResourceType 'ContactGroup' -Id $id -RemoveCommand { param($Id, $Confirm, $ErrorAction) Remove-NBContactGroup -Id $Id -Confirm:$Confirm -ErrorAction $ErrorAction }
        }

        # Report any cleanup errors
        if ($cleanupErrors.Count -gt 0) {
            Write-Warning "Cleanup completed with $($cleanupErrors.Count) error(s):"
            $cleanupErrors | ForEach-Object { Write-Warning "  - $_" }
        }
        else {
            Write-Host "Cleanup complete." -ForegroundColor Green
        }
    }

    Context "API Connectivity" {
        It "Should connect successfully" {
            Test-NBAPIConnected | Should -Be $true
        }

        It "Should retrieve Netbox version" {
            $version = Get-NBVersion
            $version | Should -Not -BeNullOrEmpty
            $version.'netbox-version' | Should -Match '^\d+\.\d+\.\d+'
            Write-Host "  Netbox version: $($version.'netbox-version')" -ForegroundColor Green
        }

        It "Should have correct hostname" {
            # Get-NBHostname returns just the hostname part (port is stored separately)
            $expectedHostname = if ($env:NETBOX_HOST -match '^(.+):\d+$') { $Matches[1] } else { $env:NETBOX_HOST }
            Get-NBHostname | Should -Be $expectedHostname
        }
    }

    Context "DCIM Sites CRUD" {
        BeforeAll {
            $script:TestSiteName = "$($script:TestPrefix)-Site"
            $script:TestSiteSlug = $script:TestSiteName.ToLower() -replace '[^a-z0-9-]', '-'
        }

        It "Should create a new site" {
            $site = New-NBDCIMSite -Name $script:TestSiteName -Slug $script:TestSiteSlug -Status 'active'

            $site | Should -Not -BeNullOrEmpty
            $site.name | Should -Be $script:TestSiteName

            $script:TestSiteId = $site.id
            [void]$script:CreatedResources.Sites.Add($site.id)

            Write-Host "  Created site: $($site.name) (ID: $($site.id))" -ForegroundColor Green
        }

        It "Should get the site by ID" {
            $site = Get-NBDCIMSite -Id $script:TestSiteId

            $site | Should -Not -BeNullOrEmpty
            $site.id | Should -Be $script:TestSiteId
        }

        It "Should update the site" {
            $site = Set-NBDCIMSite -Id $script:TestSiteId -Description "$script:TestPrefix - Updated"

            $site.description | Should -BeLike "*Updated*"
        }

        It "Should delete the site" {
            { Remove-NBDCIMSite -Id $script:TestSiteId -Confirm:$false } | Should -Not -Throw

            $script:CreatedResources.Sites.Remove($script:TestSiteId)
        }
    }

    Context "IPAM Address CRUD" {
        BeforeAll {
            $octet3 = Get-Random -Minimum 1 -Maximum 254
            $octet4 = Get-Random -Minimum 1 -Maximum 254
            $script:TestAddress = "10.99.$octet3.$octet4/32"
        }

        It "Should create a new IP address" {
            $ip = New-NBIPAMAddress -Address $script:TestAddress -Status 'active' -Description "$script:TestPrefix-IP"

            $ip | Should -Not -BeNullOrEmpty
            $ip.address | Should -Be $script:TestAddress

            $script:TestAddressId = $ip.id
            [void]$script:CreatedResources.Addresses.Add($ip.id)

            Write-Host "  Created IP: $($ip.address) (ID: $($ip.id))" -ForegroundColor Green
        }

        It "Should get the IP address by ID" {
            $ip = Get-NBIPAMAddress -Id $script:TestAddressId

            $ip | Should -Not -BeNullOrEmpty
            $ip.id | Should -Be $script:TestAddressId
        }

        It "Should update the IP address" {
            $ip = Set-NBIPAMAddress -Id $script:TestAddressId -Description "$script:TestPrefix - Updated IP"

            $ip.description | Should -BeLike "*Updated*"
        }

        It "Should delete the IP address" {
            { Remove-NBIPAMAddress -Id $script:TestAddressId -Confirm:$false } | Should -Not -Throw

            $script:CreatedResources.Addresses.Remove($script:TestAddressId)
        }
    }

    Context "IPAM Prefix CRUD" {
        BeforeAll {
            $octet2 = Get-Random -Minimum 1 -Maximum 254
            $script:TestPrefixValue = "10.$octet2.0.0/24"
        }

        It "Should create a new prefix" {
            $prefix = New-NBIPAMPrefix -Prefix $script:TestPrefixValue -Status 'active' -Description "$script:TestPrefix-Prefix"

            $prefix | Should -Not -BeNullOrEmpty
            $prefix.prefix | Should -Be $script:TestPrefixValue

            $script:TestPrefixId = $prefix.id
            [void]$script:CreatedResources.Prefixes.Add($prefix.id)

            Write-Host "  Created prefix: $($prefix.prefix) (ID: $($prefix.id))" -ForegroundColor Green
        }

        It "Should get the prefix by ID" {
            $prefix = Get-NBIPAMPrefix -Id $script:TestPrefixId

            $prefix | Should -Not -BeNullOrEmpty
            $prefix.id | Should -Be $script:TestPrefixId
            $prefix.prefix | Should -Be $script:TestPrefixValue
        }

        It "Should update the prefix" {
            $prefix = Set-NBIPAMPrefix -Id $script:TestPrefixId -Description "$script:TestPrefix - Updated Prefix"

            $prefix.description | Should -BeLike "*Updated*"
        }

        It "Should delete the prefix" {
            { Remove-NBIPAMPrefix -Id $script:TestPrefixId -Confirm:$false } | Should -Not -Throw

            $script:CreatedResources.Prefixes.Remove($script:TestPrefixId)
        }
    }

    Context "Tenancy Tenant CRUD" {
        BeforeAll {
            $script:TestTenantName = "$($script:TestPrefix)-Tenant"
            $script:TestTenantSlug = $script:TestTenantName.ToLower() -replace '[^a-z0-9-]', '-'
        }

        It "Should create a new tenant" {
            $tenant = New-NBTenant -Name $script:TestTenantName -Slug $script:TestTenantSlug

            $tenant | Should -Not -BeNullOrEmpty
            $tenant.name | Should -Be $script:TestTenantName

            $script:TestTenantId = $tenant.id
            [void]$script:CreatedResources.Tenants.Add($tenant.id)

            Write-Host "  Created tenant: $($tenant.name) (ID: $($tenant.id))" -ForegroundColor Green
        }

        It "Should get the tenant by ID" {
            $tenant = Get-NBTenant -Id $script:TestTenantId

            $tenant | Should -Not -BeNullOrEmpty
            $tenant.id | Should -Be $script:TestTenantId
            $tenant.name | Should -Be $script:TestTenantName
        }

        It "Should update the tenant" {
            $tenant = Set-NBTenant -Id $script:TestTenantId -Description "$script:TestPrefix - Updated Tenant"

            $tenant.description | Should -BeLike "*Updated*"
        }

        It "Should delete the tenant" {
            { Remove-NBTenant -Id $script:TestTenantId -Confirm:$false } | Should -Not -Throw

            $script:CreatedResources.Tenants.Remove($script:TestTenantId)
        }
    }

    Context "IPAM VLAN CRUD" {
        BeforeAll {
            $script:TestVlanVid = Get-Random -Minimum 100 -Maximum 4000
            $script:TestVlanName = "$($script:TestPrefix)-VLAN-$($script:TestVlanVid)"
        }

        It "Should create a new VLAN" {
            $vlan = New-NBIPAMVLAN -Vid $script:TestVlanVid -Name $script:TestVlanName -Status 'active'

            $vlan | Should -Not -BeNullOrEmpty
            $vlan.vid | Should -Be $script:TestVlanVid
            $vlan.name | Should -Be $script:TestVlanName

            $script:TestVlanId = $vlan.id
            [void]$script:CreatedResources.VLANs.Add($vlan.id)

            Write-Host "  Created VLAN: $($vlan.name) (VID: $($vlan.vid), ID: $($vlan.id))" -ForegroundColor Green
        }

        It "Should get the VLAN by ID" {
            $vlan = Get-NBIPAMVLAN -Id $script:TestVlanId

            $vlan | Should -Not -BeNullOrEmpty
            $vlan.id | Should -Be $script:TestVlanId
            $vlan.vid | Should -Be $script:TestVlanVid
        }

        It "Should update the VLAN" {
            $vlan = Set-NBIPAMVLAN -Id $script:TestVlanId -Description "$script:TestPrefix - Updated VLAN"

            $vlan.description | Should -BeLike "*Updated*"
        }

        It "Should delete the VLAN" {
            { Remove-NBIPAMVLAN -Id $script:TestVlanId -Confirm:$false } | Should -Not -Throw

            $script:CreatedResources.VLANs.Remove($script:TestVlanId)
        }
    }

    Context "DCIM Manufacturer CRUD" {
        BeforeAll {
            $script:TestManufacturerName = "$($script:TestPrefix)-Manufacturer"
            $script:TestManufacturerSlug = $script:TestManufacturerName.ToLower() -replace '[^a-z0-9-]', '-'
        }

        It "Should create a new manufacturer" {
            $manufacturer = New-NBDCIMManufacturer -Name $script:TestManufacturerName -Slug $script:TestManufacturerSlug

            $manufacturer | Should -Not -BeNullOrEmpty
            $manufacturer.name | Should -Be $script:TestManufacturerName

            $script:TestManufacturerId = $manufacturer.id
            [void]$script:CreatedResources.Manufacturers.Add($manufacturer.id)

            Write-Host "  Created manufacturer: $($manufacturer.name) (ID: $($manufacturer.id))" -ForegroundColor Green
        }

        It "Should get the manufacturer by ID" {
            $manufacturer = Get-NBDCIMManufacturer -Id $script:TestManufacturerId

            $manufacturer | Should -Not -BeNullOrEmpty
            $manufacturer.id | Should -Be $script:TestManufacturerId
        }

        It "Should update the manufacturer" {
            $manufacturer = Set-NBDCIMManufacturer -Id $script:TestManufacturerId -Description "$script:TestPrefix - Updated"

            $manufacturer.description | Should -BeLike "*Updated*"
        }
    }

    Context "DCIM DeviceRole CRUD" {
        BeforeAll {
            $script:TestDeviceRoleName = "$($script:TestPrefix)-Role"
            $script:TestDeviceRoleSlug = $script:TestDeviceRoleName.ToLower() -replace '[^a-z0-9-]', '-'
        }

        It "Should create a new device role" {
            $role = New-NBDCIMDeviceRole -Name $script:TestDeviceRoleName -Slug $script:TestDeviceRoleSlug -Color '0000ff'

            $role | Should -Not -BeNullOrEmpty
            $role.name | Should -Be $script:TestDeviceRoleName

            $script:TestDeviceRoleId = $role.id
            [void]$script:CreatedResources.DeviceRoles.Add($role.id)

            Write-Host "  Created device role: $($role.name) (ID: $($role.id))" -ForegroundColor Green
        }

        It "Should get the device role by ID" {
            $role = Get-NBDCIMDeviceRole -Id $script:TestDeviceRoleId

            $role | Should -Not -BeNullOrEmpty
            $role.id | Should -Be $script:TestDeviceRoleId
        }
    }

    Context "DCIM DeviceType CRUD" {
        BeforeAll {
            $script:TestDeviceTypeName = "$($script:TestPrefix)-Type"
            $script:TestDeviceTypeSlug = $script:TestDeviceTypeName.ToLower() -replace '[^a-z0-9-]', '-'
        }

        It "Should create a new device type" {
            # DeviceType requires a Manufacturer
            $deviceType = New-NBDCIMDeviceType -Model $script:TestDeviceTypeName -Slug $script:TestDeviceTypeSlug -Manufacturer $script:TestManufacturerId

            $deviceType | Should -Not -BeNullOrEmpty
            $deviceType.model | Should -Be $script:TestDeviceTypeName

            $script:TestDeviceTypeId = $deviceType.id
            [void]$script:CreatedResources.DeviceTypes.Add($deviceType.id)

            Write-Host "  Created device type: $($deviceType.model) (ID: $($deviceType.id))" -ForegroundColor Green
        }

        It "Should get the device type by ID" {
            $deviceType = Get-NBDCIMDeviceType -Id $script:TestDeviceTypeId

            $deviceType | Should -Not -BeNullOrEmpty
            $deviceType.id | Should -Be $script:TestDeviceTypeId
        }
    }

    Context "DCIM Device CRUD" {
        BeforeAll {
            # Create a site for the device (if not already created)
            $script:TestDeviceSiteName = "$($script:TestPrefix)-DeviceSite"
            $script:TestDeviceSiteSlug = $script:TestDeviceSiteName.ToLower() -replace '[^a-z0-9-]', '-'

            $site = New-NBDCIMSite -Name $script:TestDeviceSiteName -Slug $script:TestDeviceSiteSlug -Status 'active'
            $script:TestDeviceSiteId = $site.id
            [void]$script:CreatedResources.Sites.Add($site.id)

            $script:TestDeviceName = "$($script:TestPrefix)-Device"
        }

        It "Should create a new device" {
            $device = New-NBDCIMDevice -Name $script:TestDeviceName `
                -Site $script:TestDeviceSiteId `
                -Device_Type $script:TestDeviceTypeId `
                -Role $script:TestDeviceRoleId `
                -Status 'active'

            $device | Should -Not -BeNullOrEmpty
            $device.name | Should -Be $script:TestDeviceName

            $script:TestDeviceId = $device.id
            [void]$script:CreatedResources.Devices.Add($device.id)

            Write-Host "  Created device: $($device.name) (ID: $($device.id))" -ForegroundColor Green
        }

        It "Should get the device by ID" {
            $device = Get-NBDCIMDevice -Id $script:TestDeviceId

            $device | Should -Not -BeNullOrEmpty
            $device.id | Should -Be $script:TestDeviceId
            $device.name | Should -Be $script:TestDeviceName
        }

        It "Should update the device" {
            $device = Set-NBDCIMDevice -Id $script:TestDeviceId -Comments "$script:TestPrefix - Updated device"

            $device.comments | Should -BeLike "*Updated*"
        }

        It "Should delete the device" {
            { Remove-NBDCIMDevice -Id $script:TestDeviceId -Confirm:$false } | Should -Not -Throw

            $script:CreatedResources.Devices.Remove($script:TestDeviceId)
        }
    }

    Context "DCIM Interface CRUD" {
        BeforeAll {
            # Create a device for interface testing
            $script:TestInterfaceDeviceName = "$($script:TestPrefix)-IntfDevice"

            $device = New-NBDCIMDevice -Name $script:TestInterfaceDeviceName `
                -Site $script:TestDeviceSiteId `
                -Device_Type $script:TestDeviceTypeId `
                -Role $script:TestDeviceRoleId `
                -Status 'active'
            $script:TestInterfaceDeviceId = $device.id
            [void]$script:CreatedResources.Devices.Add($device.id)

            $script:TestInterfaceName = "eth0"
        }

        It "Should create a new interface" {
            $interface = New-NBDCIMInterface -Device $script:TestInterfaceDeviceId `
                -Name $script:TestInterfaceName `
                -Type '1000base-t'

            $interface | Should -Not -BeNullOrEmpty
            $interface.name | Should -Be $script:TestInterfaceName

            $script:TestInterfaceId = $interface.id
            [void]$script:CreatedResources.Interfaces.Add($interface.id)

            Write-Host "  Created interface: $($interface.name) (ID: $($interface.id))" -ForegroundColor Green
        }

        It "Should get the interface by ID" {
            $interface = Get-NBDCIMInterface -Id $script:TestInterfaceId

            $interface | Should -Not -BeNullOrEmpty
            $interface.id | Should -Be $script:TestInterfaceId
        }

        It "Should update the interface" {
            $interface = Set-NBDCIMInterface -Id $script:TestInterfaceId -Description "$script:TestPrefix - Updated"

            $interface.description | Should -BeLike "*Updated*"
        }

        It "Should delete the interface" {
            { Remove-NBDCIMInterface -Id $script:TestInterfaceId -Confirm:$false } | Should -Not -Throw

            $script:CreatedResources.Interfaces.Remove($script:TestInterfaceId)
        }
    }

    Context "Virtualization ClusterType CRUD" {
        BeforeAll {
            $script:TestClusterTypeName = "$($script:TestPrefix)-ClusterType"
            $script:TestClusterTypeSlug = $script:TestClusterTypeName.ToLower() -replace '[^a-z0-9-]', '-'
        }

        It "Should create a new cluster type" {
            $clusterType = New-NBVirtualizationClusterType -Name $script:TestClusterTypeName -Slug $script:TestClusterTypeSlug

            $clusterType | Should -Not -BeNullOrEmpty
            $clusterType.name | Should -Be $script:TestClusterTypeName

            $script:TestClusterTypeId = $clusterType.id
            [void]$script:CreatedResources.ClusterTypes.Add($clusterType.id)

            Write-Host "  Created cluster type: $($clusterType.name) (ID: $($clusterType.id))" -ForegroundColor Green
        }

        It "Should get the cluster type by ID" {
            $clusterType = Get-NBVirtualizationClusterType -Id $script:TestClusterTypeId

            $clusterType | Should -Not -BeNullOrEmpty
            $clusterType.id | Should -Be $script:TestClusterTypeId
        }
    }

    Context "Virtualization Cluster CRUD" {
        BeforeAll {
            $script:TestClusterName = "$($script:TestPrefix)-Cluster"
        }

        It "Should create a new cluster" {
            $cluster = New-NBVirtualizationCluster -Name $script:TestClusterName -Type $script:TestClusterTypeId

            $cluster | Should -Not -BeNullOrEmpty
            $cluster.name | Should -Be $script:TestClusterName

            $script:TestClusterId = $cluster.id
            [void]$script:CreatedResources.Clusters.Add($cluster.id)

            Write-Host "  Created cluster: $($cluster.name) (ID: $($cluster.id))" -ForegroundColor Green
        }

        It "Should get the cluster by ID" {
            $cluster = Get-NBVirtualizationCluster -Id $script:TestClusterId

            $cluster | Should -Not -BeNullOrEmpty
            $cluster.id | Should -Be $script:TestClusterId
        }

        It "Should update the cluster" {
            $cluster = Set-NBVirtualizationCluster -Id $script:TestClusterId -Comments "$script:TestPrefix - Updated"

            $cluster.comments | Should -BeLike "*Updated*"
        }
    }

    Context "Virtualization VM CRUD" {
        BeforeAll {
            $script:TestVMName = "$($script:TestPrefix)-VM"
        }

        It "Should create a new virtual machine" {
            $vm = New-NBVirtualMachine -Name $script:TestVMName `
                -Cluster $script:TestClusterId `
                -Status 'active'

            $vm | Should -Not -BeNullOrEmpty
            $vm.name | Should -Be $script:TestVMName

            $script:TestVMId = $vm.id
            [void]$script:CreatedResources.VMs.Add($vm.id)

            Write-Host "  Created VM: $($vm.name) (ID: $($vm.id))" -ForegroundColor Green
        }

        It "Should get the VM by ID" {
            $vm = Get-NBVirtualMachine -Id $script:TestVMId

            $vm | Should -Not -BeNullOrEmpty
            $vm.id | Should -Be $script:TestVMId
            $vm.name | Should -Be $script:TestVMName
        }

        It "Should update the VM" {
            $vm = Set-NBVirtualMachine -Id $script:TestVMId -Comments "$script:TestPrefix - Updated VM"

            $vm.comments | Should -BeLike "*Updated*"
        }

        It "Should delete the VM" {
            { Remove-NBVirtualMachine -Id $script:TestVMId -Confirm:$false } | Should -Not -Throw

            $script:CreatedResources.VMs.Remove($script:TestVMId)
        }
    }

    Context "Pagination" {
        It "Should support -All switch" {
            { Get-NBDCIMSite -All } | Should -Not -Throw
        }

        It "Should support -Limit and -Offset" {
            { Get-NBDCIMSite -Limit 10 -Offset 0 } | Should -Not -Throw
        }
    }

    Context "Error Handling" {
        It "Should throw on non-existent ID" {
            { Get-NBDCIMSite -Id 999999999 } | Should -Throw
        }

        It "Should return empty for non-existent name" {
            $result = Get-NBDCIMSite -Name "NonExistent-$([guid]::NewGuid())"
            $result | Should -BeNullOrEmpty
        }
    }

    Context "VPN Operations (Netbox 4.x)" {
        It "Should query VPN tunnels without error" {
            { Get-NBVPNTunnel -Limit 1 } | Should -Not -Throw
        }

        It "Should query L2VPNs without error" {
            { Get-NBVPNL2VPN -Limit 1 } | Should -Not -Throw
        }
    }

    Context "Wireless Operations (Netbox 4.x)" {
        It "Should query wireless LANs without error" {
            { Get-NBWirelessLAN -Limit 1 } | Should -Not -Throw
        }

        It "Should query wireless links without error" {
            { Get-NBWirelessLink -Limit 1 } | Should -Not -Throw
        }
    }

    Context "Version Compatibility" {
        It "Should query content types with backward-compatible function" {
            # Get-NBContentType automatically detects Netbox version:
            # - Netbox 4.4+: uses /api/core/object-types/
            # - Netbox 4.0-4.3: uses /api/extras/object-types/
            { Get-NBContentType -Limit 1 } | Should -Not -Throw
        }
    }

    Context "Port Mapping (Netbox 4.5+)" -Tag 'PortMapping', 'Netbox45' {
        BeforeAll {
            # Check Netbox version
            $status = Get-NBVersion
            $versionString = $status.'netbox-version'
            if ($versionString -match '^\d+\.\d+') {
                $version = [version]($versionString -replace '-.*$')
                $script:Is45OrHigher = $version -ge [version]'4.5.0'
            }
            else {
                $script:Is45OrHigher = $false
            }

            if ($script:Is45OrHigher) {
                # Find or create a test device
                $script:TestDevice = Get-NBDCIMDevice -Name "$script:TestPrefix-PatchPanel" | Select-Object -First 1
                if (-not $script:TestDevice) {
                    # Need site, manufacturer, device type, device role
                    $site = Get-NBDCIMSite | Select-Object -First 1
                    if (-not $site) {
                        $site = New-NBDCIMSite -Name "$script:TestPrefix-Site" -Slug "$script:TestPrefix-site".ToLower()
                        [void]$script:CreatedResources.Sites.Add($site.id)
                    }
                    $mfr = Get-NBDCIMManufacturer | Select-Object -First 1
                    if (-not $mfr) {
                        $mfr = New-NBDCIMManufacturer -Name "$script:TestPrefix-Mfr" -Slug "$script:TestPrefix-mfr".ToLower()
                        [void]$script:CreatedResources.Manufacturers.Add($mfr.id)
                    }
                    $devType = Get-NBDCIMDeviceType | Select-Object -First 1
                    if (-not $devType) {
                        $devType = New-NBDCIMDeviceType -Model "$script:TestPrefix-PP24" -Slug "$script:TestPrefix-pp24".ToLower() -Manufacturer $mfr.id
                        [void]$script:CreatedResources.DeviceTypes.Add($devType.id)
                    }
                    $devRole = Get-NBDCIMDeviceRole | Select-Object -First 1
                    if (-not $devRole) {
                        $devRole = New-NBDCIMDeviceRole -Name "$script:TestPrefix-PatchPanel" -Slug "$script:TestPrefix-patchpanel".ToLower()
                        [void]$script:CreatedResources.DeviceRoles.Add($devRole.id)
                    }
                    $script:TestDevice = New-NBDCIMDevice -Name "$script:TestPrefix-PatchPanel" -Site $site.id -Device_Type $devType.id -Role $devRole.id
                    [void]$script:CreatedResources.Devices.Add($script:TestDevice.id)
                }

                # Track port resources for cleanup
                $script:CreatedPorts = @{
                    RearPorts  = [System.Collections.ArrayList]::new()
                    FrontPorts = [System.Collections.ArrayList]::new()
                }
            }
        }

        AfterAll {
            if ($script:Is45OrHigher -and $script:CreatedPorts) {
                # Cleanup ports (FrontPorts first, then RearPorts)
                foreach ($id in $script:CreatedPorts.FrontPorts) {
                    try { Remove-NBDCIMFrontPort -Id $id -Confirm:$false -ErrorAction SilentlyContinue } catch {}
                }
                foreach ($id in $script:CreatedPorts.RearPorts) {
                    try { Remove-NBDCIMRearPort -Id $id -Confirm:$false -ErrorAction SilentlyContinue } catch {}
                }
            }
        }

        It "Should create RearPort without port mappings" {
            if (-not $script:Is45OrHigher) { Set-ItResult -Skipped -Because "Requires Netbox 4.5+"; return }
            $rp = New-NBDCIMRearPort -Device $script:TestDevice.id -Name "$script:TestPrefix-RP1" -Type '8p8c' -Positions 2
            $rp | Should -Not -BeNullOrEmpty
            $rp.id | Should -BeGreaterThan 0
            [void]$script:CreatedPorts.RearPorts.Add($rp.id)
            $script:TestRearPort = $rp
        }

        It "Should create FrontPort with Rear_Ports array" {
            if (-not $script:Is45OrHigher) { Set-ItResult -Skipped -Because "Requires Netbox 4.5+"; return }
            $fp = New-NBDCIMFrontPort -Device $script:TestDevice.id -Name "$script:TestPrefix-FP1" -Type '8p8c' -Rear_Ports @(
                @{ rear_port = $script:TestRearPort.id; rear_port_position = 1; position = 1 }
            )
            $fp | Should -Not -BeNullOrEmpty
            $fp.rear_ports | Should -Not -BeNullOrEmpty
            $fp.rear_ports[0].rear_port | Should -Be $script:TestRearPort.id
            [void]$script:CreatedPorts.FrontPorts.Add($fp.id)
            $script:TestFrontPort = $fp
        }

        It "Should update FrontPort Rear_Ports" {
            if (-not $script:Is45OrHigher) { Set-ItResult -Skipped -Because "Requires Netbox 4.5+"; return }
            $fp = Set-NBDCIMFrontPort -Id $script:TestFrontPort.id -Rear_Ports @(
                @{ rear_port = $script:TestRearPort.id; rear_port_position = 2; position = 1 }
            ) -Force
            $fp.rear_ports[0].rear_port_position | Should -Be 2
        }

        It "Should set RearPort Front_Ports via API (bidirectional)" {
            if (-not $script:Is45OrHigher) { Set-ItResult -Skipped -Because "Requires Netbox 4.5+"; return }
            # Create a RearPort (no front_ports initially)
            $rp2 = New-NBDCIMRearPort -Device $script:TestDevice.id -Name "$script:TestPrefix-RP2" -Type '8p8c' -Positions 1
            [void]$script:CreatedPorts.RearPorts.Add($rp2.id)
            $rp2.front_ports | Should -BeNullOrEmpty

            # Create a FrontPort mapped to this RearPort
            $fp2 = New-NBDCIMFrontPort -Device $script:TestDevice.id -Name "$script:TestPrefix-FP2" -Type '8p8c' -Rear_Port $rp2.id -Rear_Port_Position 1
            [void]$script:CreatedPorts.FrontPorts.Add($fp2.id)
            $script:TestFP2 = $fp2

            # Verify bidirectional mapping was created automatically by Netbox
            $rp2Check = Get-NBDCIMRearPort -Id $rp2.id
            $rp2Check.front_ports | Should -Not -BeNullOrEmpty -Because "Creating FrontPort with rear_port should auto-populate RearPort.front_ports"
            $rp2Check.front_ports[0].front_port | Should -Be $fp2.id
        }

        It "Should sync bidirectional mapping to FrontPort" {
            if (-not $script:Is45OrHigher) { Set-ItResult -Skipped -Because "Requires Netbox 4.5+"; return }
            # The FrontPort created above should now have rear_ports populated
            $fp2 = Get-NBDCIMFrontPort -Id $script:TestFP2.id
            $fp2.rear_ports | Should -Not -BeNullOrEmpty
        }
    }

    Context "Extras Tags CRUD" {
        BeforeAll {
            $script:TestTagName = "$($script:TestPrefix)-Tag"
            $script:TestTagSlug = $script:TestTagName.ToLower() -replace '[^a-z0-9-]', '-'

            $script:TestTagName2 = "$($script:TestPrefix)-Tag2"
            $script:TestTagSlug2 = $script:TestTagName2.ToLower() -replace '[^a-z0-9-]', '-'

            $tag2 = New-NBTag -Name $script:TestTagName2 -Slug $script:TestTagSlug2 -Color 'ffff00'
            $script:TestTag2Id = $tag2.id
            [void]$script:CreatedResources.Tags.Add($tag2.id)
        }
        AfterAll {
            { Remove-NBTag -Id $script:TestTag2Id -Confirm:$false } | Should -Not -Throw
            $script:CreatedResources.Tags.Remove($script:TestTag2Id)
            $script:TestTag2Id = $null
        }

        It "Should create a tag" {
            $tag = New-NBTag -Name $script:TestTagName -Slug $script:TestTagSlug -Color 'ff0000'

            $tag | Should -Not -BeNullOrEmpty
            $tag.name | Should -Be $script:TestTagName

            $script:TestTagId = $tag.id
            [void]$script:CreatedResources.Tags.Add($tag.id)

            Write-Host "  Created tag: $($tag.name) (ID: $($tag.id))" -ForegroundColor Green
        }

        It "Should get tag by ID" {
            $tag = Get-NBTag -Id $script:TestTagId

            $tag | Should -Not -BeNullOrEmpty
            $tag.id | Should -Be $script:TestTagId
            $tag.name | Should -Be $script:TestTagName
        }

        It "Should get tag by name" {
            $tag = Get-NBTag -Name $script:TestTagName

            $tag | Should -Not -BeNullOrEmpty
            $tag.id | Should -Be $script:TestTagId
            $tag.name | Should -Be $script:TestTagName
        }

        It "Should get two tags by two name" {
            $tags = Get-NBTag -Name $script:TestTagName, $script:TestTagName2

            $tags | Should -Not -BeNullOrEmpty
            $tags.Count | Should -Be  2
            $tags.id | Should -Contain $script:TestTagId
            $tags.id | Should -Contain $script:TestTag2Id
        }

        It "Should get two tags by two slugs" {
            $tags = Get-NBTag -Slug $script:TestTagSlug, $script:TestTagSlug2

            $tags | Should -Not -BeNullOrEmpty
            $tags.Count | Should -Be  2
            $tags.id | Should -Contain $script:TestTagId
            $tags.id | Should -Contain $script:TestTag2Id
        }

        It "Should update tag" {
            $tag = Set-NBTag -Id $script:TestTagId -Description "$script:TestPrefix - Updated Tag"

            $tag.description | Should -BeLike "*Updated*"
        }

        It "Should delete tag" {
            { Remove-NBTag -Id $script:TestTagId -Confirm:$false } | Should -Not -Throw

            $script:CreatedResources.Tags.Remove($script:TestTagId)
        }
    }

    Context "Contact Group CRUD" {
        BeforeAll {
            # This group will be used for tests of adding/removeing contacts as well, so it's not removed at the end
            $script:TestContactGroupId = @(-1, -1, -1)      # paremt group, chil1, child2
            $script:TestContactGroupName = @("$($script:TestPrefix)-ContactGroup", "$($script:TestPrefix)-ContactGroup-Child", "$($script:TestPrefix)-ContactGroup-Child2")
            $script:TestContactGroupSlug = $script:TestContactGroupName.ToLower() -replace '[^a-z0-9-]', '-'

            $group = New-NBContactGroup -Name $script:TestContactGroupName[0] -Slug $script:TestContactGroupSlug[0]
            $group | Should -Not -BeNullOrEmpty
            $script:TestContactGroupId[0] = $group.id
            [void]$script:CreatedResources.ContactGroups.Add($group.id)
        }

        It "Should create a contact group as child group" {
            $childGroup = New-NBContactGroup -Name $script:TestContactGroupName[1] -Slug $script:TestContactGroupSlug[1] -Parent $script:TestContactGroupId[0]
            $script:TestContactGroupId[1] = $childGroup.id
            [void]$script:CreatedResources.ContactGroups.Add($childGroup.id)

            $childGroup.parent.id | Should -Be $script:TestContactGroupId[0]
        }

        It "Should create child group (search parent by name)" {
            $childGroup = New-NBContactGroup -Name $script:TestContactGroupName[2] -Slug $script:TestContactGroupSlug[2] -Parent $script:TestContactGroupName[0]
            $script:TestContactGroupId[2] = $childGroup.id
            [void]$script:CreatedResources.ContactGroups.Add($childGroup.id)

            $childGroup.parent.id | Should -Be $script:TestContactGroupId[0]
        }
        It "Should get contact group by ID" {
            $group = Get-NBContactGroup -Id $script:TestContactGroupId[0]

            $group | Should -Not -BeNullOrEmpty
            $group.id | Should -Be $script:TestContactGroupId[0]
            $group.name | Should -Be $script:TestContactGroupName[0]
        }

        It "Should get multiple contact groups by id" {
            $groups = Get-NBContactGroup -Id ($script:TestContactGroupId[0], $script:TestContactGroupId[1])

            $groups | Should -Not -BeNullOrEmpty
            $groups | Should -HaveCount 2
            $groups[0].id | Should -Be $script:TestContactGroupId[0]
            $groups[1].id | Should -Be $script:TestContactGroupId[1]
        }

        It "Should update contact group" {
            $group = Set-NBContactGroup -Id $script:TestContactGroupId[0] -Description "$script:TestPrefix - Updated Contact Group"

            $group.description | Should -BeLike "*Updated*"
        }

        It "Should update (rename) a contact group by pipeline Id" {
            $Result = Get-NBContactGroup -Id $script:TestContactGroupId[0] | Set-NBContactGroup -Name "$($script:TestContactGroupName[0]) - Updated" -Confirm:$false

            $Result.name | Should -Be "$($script:TestContactGroupName[0]) - Updated"   # renamed the group
            $Result.slug | Should -Be $script:TestContactGroupSlug[0]  # slug should remain unchanged
        }

        It "Should delete child contact groups by Id" {
            # Remove the child group first, otherwise the parent group deletion would do a cascading delete
            { Remove-NBContactGroup -Id $script:TestContactGroupId[1] -Confirm:$false } | Should -Not -Throw
            $script:CreatedResources.ContactGroups.Remove($script:TestContactGroupId[1])
            $script:TestContactGroupId[1] = $null
        }

        It "Should delete contact group 2 by pipeline" {
            { Get-NBContactGroup -Id $script:TestContactGroupId[2] | Remove-NBContactGroup -Confirm:$false } | Should -Not -Throw
            $script:CreatedResources.ContactGroups.Remove($script:TestContactGroupId[2])
            $script:TestContactGroupId[2] = $null
        }
    }

    Context "Contact Role CRUD" {
        BeforeAll {
            $script:TestContactRoleName = "$($script:TestPrefix)-ContactRole"
            $script:TestContactRoleSlug = $script:TestContactRoleName.ToLower() -replace '[^a-z0-9-]', '-'
        }

        It "Should create a contact role" {
            $role = New-NBContactRole -Name $script:TestContactRoleName -Slug $script:TestContactRoleSlug

            $role | Should -Not -BeNullOrEmpty
            $role.name | Should -Be $script:TestContactRoleName

            $script:TestContactRoleId = $role.id
            [void]$script:CreatedResources.ContactRoles.Add($role.id)

            Write-Host "  Created contact role: $($role.name) (ID: $($role.id))" -ForegroundColor Green
        }

        It "Should get contact role by ID" {
            $role = Get-NBContactRole -Id $script:TestContactRoleId

            $role | Should -Not -BeNullOrEmpty
            $role.id | Should -Be $script:TestContactRoleId
            $role.name | Should -Be $script:TestContactRoleName
        }

        It "Should update contact role" {
            $role = Set-NBContactRole -Id $script:TestContactRoleId -Description "$script:TestPrefix - Updated Contact Role"

            $role.description | Should -BeLike "*Updated*"
        }
    }

    Context "Contact CRUD" {
        BeforeAll {
            $script:TestContactName = "$($script:TestPrefix)-Contact"
            $script:TestContactSlug = $script:TestContactName.ToLower() -replace '[^a-z0-9-]', '-'

            # Create an additional contact group to make context test independent from the "Contact Group CRUD"
            $Script:TestContactGroup2Name = "$($script:TestPrefix)-ContactGroup2"
            $Script:TestContactGroup2Slug = $Script:TestContactGroup2Name.ToLower() -replace '[^a-z0-9-]', '-'
            $group2 = New-NBContactGroup -Name $Script:TestContactGroup2Name -Slug $Script:TestContactGroup2Slug
            $Script:TestContactGroup2Id = $group2.id
            [void]$script:CreatedResources.ContactGroups.Add($group2.id)
        }
        AfterAll {
            # Cleanup the additional contact group created in BeforeAll
            if ($Script:TestContactGroup2Id) {
                { Remove-NBContactGroup -Id $Script:TestContactGroup2Id -Confirm:$false } | Should -Not -Throw
                $script:CreatedResources.ContactGroups.Remove($Script:TestContactGroup2Id)
                $Script:TestContactGroup2Id = $null
            }
        }

        It "Should create a contact" {
            $contact = New-NBContact -Name $script:TestContactName -Group_Id $Script:TestContactGroup2Id

            $contact | Should -Not -BeNullOrEmpty
            $contact.name | Should -Be $script:TestContactName
            $contact.groups.Id | Should -Contain $Script:TestContactGroup2Id

            $script:TestContactId = $contact.id
            [void]$script:CreatedResources.Contacts.Add($contact.id)

            Write-Host "  Created contact: $($contact.name) (ID: $($contact.id))" -ForegroundColor Green
        }

        It "Should get contact by ID" {
            $contact = Get-NBContact -Id $script:TestContactId

            $contact | Should -Not -BeNullOrEmpty
            $contact.id | Should -Be $script:TestContactId
            $contact.name | Should -Be $script:TestContactName
        }

        It "Should update contact" {
            $contact = Set-NBContact -Id $script:TestContactId -Description "$script:TestPrefix - Updated Contact"

            $contact.description | Should -BeLike "*Updated*"
        }

        It "Should add contact to contact group" {
            # create contact
            $contact = New-NBContact -Name "$($script:TestPrefix)-GroupContact"
            [void]$script:CreatedResources.Contacts.Add($contact.id)

            $Result = Set-NBContact -Id $contact.id -Group_Id $Script:TestContactGroup2Id -Confirm:$false

            $Result | Should -Not -BeNullOrEmpty
            $Result.id | Should -Be $contact.id
            $Result.groups.Id | Should -Contain $Script:TestContactGroup2Id

            $group = Get-NBContactGroup -Id $Script:TestContactGroup2Id
            $group.contact_count | Should -Be 2

            # Cleanup: remove contact from group, then delete contact
            # additionally, prove, that renaming parameter -Group to -Groups is not a breaking change
            $contact = Set-NBContact -Id $contact.id -Group_Id @() -Confirm:$false
            $contact.groups | Should -HaveCount 0
            { Remove-NBContact -Id $contact.id -Confirm:$false  } | Should -Not -Throw
            $script:CreatedResources.Contacts.Remove($contact.id)
        }

        It "Should find two contacts in the same group" {
            # create contact
            $contact2 = New-NBContact -Name "$($script:TestPrefix)-GroupContact2" -Group_Id $Script:TestContactGroup2Id
            [void]$script:CreatedResources.Contacts.Add($contact2.id)

            $group = Get-NBContactGroup -Id $Script:TestContactGroup2Id

            $group.contact_count | Should -Be 2

            # now search for contacts by group Id
            $contacts = Get-NBContact -Group_Id $Script:TestContactGroup2Id

            $contacts | Should -Not -BeNullOrEmpty
            $contacts | Should -HaveCount 2

            #Cleanup: delete contact
            { Remove-NBContact -Id $contact2.id -Confirm:$false  } | Should -Not -Throw
            $script:CreatedResources.Contacts.Remove($contact2.id)
        }
    }

    Context "Contact Assignment CRUD" {
        BeforeAll {
            # Create a dedicated site for assignment tests — the earlier "DCIM Sites CRUD"
            # context deletes its site at the end, so $script:TestSiteId points at a
            # now-deleted object once we get here.
            $script:AssignmentSiteName = "$($script:TestPrefix)-AssignmentSite"
            $script:AssignmentSiteSlug = $script:AssignmentSiteName.ToLower() -replace '[^a-z0-9-]', '-'

            $assignmentSite = New-NBDCIMSite -Name $script:AssignmentSiteName -Slug $script:AssignmentSiteSlug -Status 'active'
            $script:AssignmentSiteId = $assignmentSite.id
            [void]$script:CreatedResources.Sites.Add($assignmentSite.id)
        }

        It "Should create a contact assignment to a site" {
            $assignment = New-NBContactAssignment -Object_Type 'dcim.site' -Object_Id $script:AssignmentSiteId -Contact $script:TestContactId -Role $script:TestContactRoleId

            $assignment | Should -Not -BeNullOrEmpty
            $assignment.contact.id | Should -Be $script:TestContactId
            $assignment.role.id | Should -Be $script:TestContactRoleId
            $assignment.priority | Should -BeNullOrEmpty

            $script:TestContactAssignmentId = $assignment.id
            [void]$script:CreatedResources.ContactAssignments.Add($assignment.id)

            Write-Host "  Created contact assignment (ID: $($assignment.id))" -ForegroundColor Green
        }

        It "Should get contact assignment by ID" {
            $assignment = Get-NBContactAssignment -Id $script:TestContactAssignmentId

            $assignment | Should -Not -BeNullOrEmpty
            $assignment.id | Should -Be $script:TestContactAssignmentId
            $assignment.contact.id | Should -Be $script:TestContactId
            $assignment.role.id | Should -Be $script:TestContactRoleId
        }

        It "Should get contact assignment by Contact_ID" {
            $assignment = Get-NBContactAssignment -Contact_Id $script:TestContactId

            $assignment | Should -Not -BeNullOrEmpty
            $assignment.id | Should -Be $script:TestContactAssignmentId
            $assignment.contact.id | Should -Be $script:TestContactId
            $assignment.role.id | Should -Be $script:TestContactRoleId
        }

        It "Should get contact assignment by Object_ID" {
            $assignment = Get-NBContactAssignment -Object_Id $script:AssignmentSiteId

            $assignment | Should -Not -BeNullOrEmpty
            $assignment.id | Should -Be $script:TestContactAssignmentId
            $assignment.contact.id | Should -Be $script:TestContactId
            $assignment.role.id | Should -Be $script:TestContactRoleId
        }

        It "Should get contact assignment by Object_Type_ID" {
            $objectType = Get-NBObjectType -App_Label 'dcim' -model 'site'
            $assignment = Get-NBContactAssignment -Object_Type_Id $objectType.id

            $assignment | Should -Not -BeNullOrEmpty
            $assignment.id | Should -Be $script:TestContactAssignmentId
            $assignment.contact.id | Should -Be $script:TestContactId
            $assignment.role.id | Should -Be $script:TestContactRoleId
        }

        It "Should get contact assignment by Object_Type" {
            $assignment = Get-NBContactAssignment -Object_Type 'dcim.site'

            $assignment | Should -Not -BeNullOrEmpty
            $assignment.id | Should -Be $script:TestContactAssignmentId
            $assignment.contact.id | Should -Be $script:TestContactId
            $assignment.role.id | Should -Be $script:TestContactRoleId
        }

        It "Should update contact assignment" {
            $splat = @{
                Id       = $script:TestContactAssignmentId
                Priority = 'secondary'
                Object_Type = 'dcim.site'
            }
            $assignment = Set-NBContactAssignment @splat

            $assignment.priority.value | Should -Be 'secondary'
        }

        It "Should delete contact assignment" {
            { Remove-NBContactAssignment -Id $script:TestContactAssignmentId -Confirm:$false } | Should -Not -Throw

            $script:CreatedResources.ContactAssignments.Remove($script:TestContactAssignmentId)
        }
    }

    Context "Extras Operations (Netbox 4.x)" {
        It "Should query tags without error" {
            { Get-NBTag -Limit 1 } | Should -Not -Throw
        }

        It "Should query custom fields without error" {
            { Get-NBCustomField -Limit 1 } | Should -Not -Throw
        }

        It "Should query config contexts without error" {
            { Get-NBConfigContext -Limit 1 } | Should -Not -Throw
        }

        It "Should query webhooks without error" {
            { Get-NBWebhook -Limit 1 } | Should -Not -Throw
        }

        It "Should query export templates without error" {
            { Get-NBExportTemplate -Limit 1 } | Should -Not -Throw
        }

        It "Should query custom links without error" {
            { Get-NBCustomLink -Limit 1 } | Should -Not -Throw
        }
    }
}
