[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

BeforeAll {
    Import-Module Pester
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

    # Try built module first, fall back to source
    $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
    if (-not (Test-Path $ModulePath)) {
        $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox.psd1"
    }
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -ErrorAction Stop
    }

    $script:TestPath = $PSScriptRoot
}

Describe "BulkOperationResult Class" -Tag 'Bulk', 'Unit' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }

        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }
    }

    Context "Basic Operations" {
        It "Should create a new BulkOperationResult" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = [BulkOperationResult]::new()

                $result | Should -Not -BeNullOrEmpty
                $result.SuccessCount | Should -Be 0
                $result.FailureCount | Should -Be 0
                $result.TotalCount | Should -Be 0
                $result.HasErrors | Should -BeFalse
            }
        }

        It "Should track successful items" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = [BulkOperationResult]::new()
                $item = [PSCustomObject]@{ id = 1; name = "test" }

                $result.AddSuccess($item)

                $result.SuccessCount | Should -Be 1
                $result.TotalCount | Should -Be 1
                $result.HasErrors | Should -BeFalse
                $result.Succeeded.Count | Should -Be 1
            }
        }

        It "Should track failed items" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = [BulkOperationResult]::new()
                $item = [PSCustomObject]@{ name = "test" }

                $result.AddFailure($item, "Validation error")

                $result.FailureCount | Should -Be 1
                $result.TotalCount | Should -Be 1
                $result.HasErrors | Should -BeTrue
                $result.Failed.Count | Should -Be 1
                $result.Errors.Count | Should -Be 1
            }
        }

        It "Should track duration after completion" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = [BulkOperationResult]::new()
                Start-Sleep -Milliseconds 50
                $result.Complete()

                $result.Duration.TotalMilliseconds | Should -BeGreaterThan 40
            }
        }

        It "Should generate summary message" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $result = [BulkOperationResult]::new()
                $result.AddSuccess([PSCustomObject]@{ id = 1 })
                $result.AddSuccess([PSCustomObject]@{ id = 2 })
                $result.AddFailure([PSCustomObject]@{ name = "fail" }, "Error")
                $result.Complete()

                $summary = $result.GetSummary()

                $summary | Should -Match "2/3 succeeded"
                $summary | Should -Match "1 failed"
            }
        }
    }
}

Describe "Send-NBBulkRequest Helper" -Tag 'Bulk', 'Unit' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
        Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
            return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
        }
        Mock -CommandName 'Get-NBHostname' -ModuleName 'PowerNetbox' -MockWith { return 'netbox.domain.com' }
        Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 30 }
        Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }

        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }

        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
            $body = $Body | ConvertFrom-Json
            $response = @()
            $id = 100
            foreach ($item in $body) {
                $response += [PSCustomObject]@{
                    id = $id++
                    name = $item.name
                }
            }
            return $response
        }
    }

    Context "Batching Behavior" {
        It "Should send items in batches" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $uri = BuildNewURI -Segments @('dcim', 'devices')
                $items = 1..5 | ForEach-Object {
                    [PSCustomObject]@{ name = "device$_" }
                }

                $result = Send-NBBulkRequest -URI $uri -Items $items -Method POST -BatchSize 3

                $result | Should -Not -BeNullOrEmpty
                $result.SuccessCount | Should -Be 5
                $result.FailureCount | Should -Be 0
            }

            # With batch size 3 and 5 items: should be 2 API calls (3 + 2)
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 2 -Exactly -ModuleName 'PowerNetbox'
        }

        It "Should return empty result for empty items" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $uri = BuildNewURI -Segments @('dcim', 'devices')
                $items = @()

                $result = Send-NBBulkRequest -URI $uri -Items $items -Method POST

                $result.TotalCount | Should -Be 0
                $result.SuccessCount | Should -Be 0
            }
        }

        It "Should handle single item" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $uri = BuildNewURI -Segments @('dcim', 'devices')
                $items = @([PSCustomObject]@{ name = "single-device" })

                $result = Send-NBBulkRequest -URI $uri -Items $items -Method POST -BatchSize 50

                $result.SuccessCount | Should -Be 1
            }
        }
    }

    Context "Error Handling" {
        It "Should handle API errors gracefully" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw "API Error: Validation failed"
            }

            InModuleScope -ModuleName 'PowerNetbox' {
                $uri = BuildNewURI -Segments @('dcim', 'devices')
                $items = @([PSCustomObject]@{ name = "error-device" })

                $result = Send-NBBulkRequest -URI $uri -Items $items -Method POST

                $result.HasErrors | Should -BeTrue
                $result.FailureCount | Should -Be 1
                $result.SuccessCount | Should -Be 0
            }
        }
    }
}

Describe "New-NBDCIMDevice Bulk Mode" -Tag 'Bulk', 'DCIM' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
        Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
            return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
        }
        Mock -CommandName 'Get-NBHostname' -ModuleName 'PowerNetbox' -MockWith { return 'netbox.domain.com' }
        Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 30 }
        Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }

        InModuleScope -ModuleName 'PowerNetbox' -ArgumentList $script:TestPath -ScriptBlock {
            param($TestPath)
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }

        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
            $body = $Body | ConvertFrom-Json
            if ($body -is [array]) {
                $response = @()
                $id = 200
                foreach ($item in $body) {
                    $response += [PSCustomObject]@{
                        id = $id++
                        name = $item.name
                        role = $item.role
                        device_type = $item.device_type
                        site = $item.site
                    }
                }
                return $response
            }
            else {
                return [PSCustomObject]@{
                    id = 100
                    name = $body.name
                    role = $body.role
                    device_type = $body.device_type
                    site = $body.site
                }
            }
        }
    }

    Context "Parameter Sets" {
        It "Should have Single and Bulk parameter sets" {
            $cmd = Get-Command New-NBDCIMDevice
            $cmd.ParameterSets.Name | Should -Contain 'Single'
            $cmd.ParameterSets.Name | Should -Contain 'Bulk'
        }

        It "Should have InputObject parameter for bulk mode" {
            $cmd = Get-Command New-NBDCIMDevice
            $cmd.Parameters.Keys | Should -Contain 'InputObject'
            $inputObjParam = $cmd.Parameters['InputObject']
            $inputObjParam.ParameterSets.Keys | Should -Contain 'Bulk'
        }

        It "Should have BatchSize parameter with validation" {
            $cmd = Get-Command New-NBDCIMDevice
            $cmd.Parameters.Keys | Should -Contain 'BatchSize'
            $batchSizeParam = $cmd.Parameters['BatchSize']
            $validateRange = $batchSizeParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }
            $validateRange | Should -Not -BeNullOrEmpty
            $validateRange.MinRange | Should -Be 1
            $validateRange.MaxRange | Should -Be 1000
        }

        It "Should have Force parameter for bulk mode" {
            $cmd = Get-Command New-NBDCIMDevice
            $cmd.Parameters.Keys | Should -Contain 'Force'
        }
    }

    Context "Bulk Operations" {
        It "Should create devices in bulk via pipeline" {
            $devices = 1..3 | ForEach-Object {
                [PSCustomObject]@{
                    Name = "bulk-device-$_"
                    Role = 1
                    Device_Type = 1
                    Site = 1
                }
            }

            $results = $devices | New-NBDCIMDevice -BatchSize 10 -Force

            $results.Count | Should -Be 3
            $results[0].name | Should -Be "bulk-device-1"
            $results[1].name | Should -Be "bulk-device-2"
            $results[2].name | Should -Be "bulk-device-3"
        }

        It "Should split large batches into multiple API calls" {
            $devices = 1..7 | ForEach-Object {
                [PSCustomObject]@{
                    Name = "batch-device-$_"
                    Role = 1
                    Device_Type = 1
                    Site = 1
                }
            }

            $results = $devices | New-NBDCIMDevice -BatchSize 3 -Force

            $results.Count | Should -Be 7

            # 7 items with batch size 3 = 3 API calls (3 + 3 + 1)
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 3 -Exactly -ModuleName 'PowerNetbox'
        }

        It "Should handle Device_Role alias in bulk mode" {
            $devices = @(
                [PSCustomObject]@{
                    Name = "alias-test"
                    Device_Role = 5
                    Device_Type = 1
                    Site = 1
                }
            )

            $results = $devices | New-NBDCIMDevice -BatchSize 10 -Force

            $results | Should -Not -BeNullOrEmpty
            $results[0].role | Should -Be 5
        }
    }
}

Describe "New-NBDCIMInterface Bulk Mode" -Tag 'Bulk', 'DCIM' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
        Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
            return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
        }
        Mock -CommandName 'Get-NBHostname' -ModuleName 'PowerNetbox' -MockWith { return 'netbox.domain.com' }
        Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 30 }
        Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }

        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }

        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
            $body = $Body | ConvertFrom-Json
            if ($body -is [array]) {
                $response = @()
                $id = 100
                foreach ($item in $body) {
                    $response += [PSCustomObject]@{
                        id = $id++
                        device = $item.device
                        name = $item.name
                        type = $item.type
                    }
                }
                return $response
            }
            else {
                return [PSCustomObject]@{
                    id = 100
                    device = $body.device
                    name = $body.name
                    type = $body.type
                }
            }
        }
    }

    Context "Parameter Sets" {
        It "Should have Single and Bulk parameter sets" {
            $cmd = Get-Command New-NBDCIMInterface
            $cmd.ParameterSets.Name | Should -Contain 'Single'
            $cmd.ParameterSets.Name | Should -Contain 'Bulk'
        }

        It "Should have InputObject parameter for bulk mode" {
            $cmd = Get-Command New-NBDCIMInterface
            $cmd.Parameters.Keys | Should -Contain 'InputObject'
        }

        It "Should have BatchSize with valid range" {
            $cmd = Get-Command New-NBDCIMInterface
            $batchSizeParam = $cmd.Parameters['BatchSize']
            $validateRange = $batchSizeParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }
            $validateRange.MinRange | Should -Be 1
            $validateRange.MaxRange | Should -Be 1000
        }
    }

    Context "Bulk Operations" {
        It "Should create interfaces in bulk" {
            $interfaces = 0..4 | ForEach-Object {
                [PSCustomObject]@{
                    Device = 42
                    Name = "eth$_"
                    Type = "1000base-t"
                }
            }

            $results = $interfaces | New-NBDCIMInterface -BatchSize 10 -Force

            $results.Count | Should -Be 5
        }

        It "Should batch large requests" {
            $interfaces = 0..9 | ForEach-Object {
                [PSCustomObject]@{ Device = 42; Name = "port$_"; Type = "1000base-t" }
            }

            $results = $interfaces | New-NBDCIMInterface -BatchSize 3 -Force

            # 10 items / 3 batch size = 4 API calls
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 4 -Exactly -ModuleName 'PowerNetbox'
        }
    }
}

Describe "New-NBIPAMPrefix Bulk Mode" -Tag 'Bulk', 'IPAM' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
        Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
            return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
        }
        Mock -CommandName 'Get-NBHostname' -ModuleName 'PowerNetbox' -MockWith { return 'netbox.domain.com' }
        Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 30 }
        Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }

        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }

        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
            $body = $Body | ConvertFrom-Json
            if ($body -is [array]) {
                $response = @()
                $id = 100
                foreach ($item in $body) {
                    $response += [PSCustomObject]@{
                        id = $id++
                        prefix = $item.prefix
                        status = $item.status
                    }
                }
                return $response
            }
            else {
                return [PSCustomObject]@{
                    id = 100
                    prefix = $body.prefix
                    status = $body.status
                }
            }
        }
    }

    Context "Parameter Sets" {
        It "Should have Single and Bulk parameter sets" {
            $cmd = Get-Command New-NBIPAMPrefix
            $cmd.ParameterSets.Name | Should -Contain 'Single'
            $cmd.ParameterSets.Name | Should -Contain 'Bulk'
        }
    }

    Context "Bulk Operations" {
        It "Should create prefixes in bulk" {
            $prefixes = 1..5 | ForEach-Object {
                [PSCustomObject]@{
                    Prefix = "10.$_.0.0/24"
                    Status = "active"
                }
            }

            $results = $prefixes | New-NBIPAMPrefix -BatchSize 10 -Force

            $results.Count | Should -Be 5
        }
    }
}

Describe "New-NBIPAMAddress Bulk Mode" -Tag 'Bulk', 'IPAM' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
        Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
            return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
        }
        Mock -CommandName 'Get-NBHostname' -ModuleName 'PowerNetbox' -MockWith { return 'netbox.domain.com' }
        Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 30 }
        Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }

        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }

        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
            $body = $Body | ConvertFrom-Json
            if ($body -is [array]) {
                $response = @()
                $id = 100
                foreach ($item in $body) {
                    $response += [PSCustomObject]@{
                        id = $id++
                        address = $item.address
                        status = @{ value = $item.status; label = $item.status }
                        description = $item.description
                    }
                }
                return $response
            }
            else {
                return [PSCustomObject]@{
                    id = 100
                    address = $body.address
                    status = @{ value = $body.status; label = $body.status }
                }
            }
        }
    }

    Context "Parameter Sets" {
        It "Should have Single and Bulk parameter sets" {
            $cmd = Get-Command New-NBIPAMAddress
            $cmd.ParameterSets.Name | Should -Contain 'Single'
            $cmd.ParameterSets.Name | Should -Contain 'Bulk'
        }

        It "Should have BatchSize parameter with valid range" {
            $cmd = Get-Command New-NBIPAMAddress
            $batchParam = $cmd.Parameters['BatchSize']
            $validateRange = $batchParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }
            $validateRange.MinRange | Should -Be 1
            $validateRange.MaxRange | Should -Be 1000
        }
    }

    Context "Bulk Operations" {
        It "Should create IP addresses in bulk" {
            $addresses = 1..10 | ForEach-Object {
                [PSCustomObject]@{
                    Address = "192.168.1.$_/24"
                    Status = "active"
                    Description = "Host $_"
                }
            }

            $results = $addresses | New-NBIPAMAddress -BatchSize 5 -Force

            $results.Count | Should -Be 10
            $results[0].address | Should -Be "192.168.1.1/24"
        }

        It "Should batch requests correctly" {
            $addresses = 1..25 | ForEach-Object {
                [PSCustomObject]@{
                    Address = "10.0.0.$_/24"
                    Status = "active"
                }
            }

            $addresses | New-NBIPAMAddress -BatchSize 10 -Force

            # 25 items / 10 batch size = 3 API calls
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 3 -Exactly -ModuleName 'PowerNetbox'
        }

        It "Should error on missing Address property" {
            $invalid = @([PSCustomObject]@{ Status = "active" })

            { $invalid | New-NBIPAMAddress -Force -ErrorAction Stop } | Should -Throw
        }
    }
}

Describe "New-NBVirtualMachine Bulk Mode" -Tag 'Bulk', 'Virtualization' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
        Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
            return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
        }
        Mock -CommandName 'Get-NBHostname' -ModuleName 'PowerNetbox' -MockWith { return 'netbox.domain.com' }
        Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 30 }
        Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }

        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }

        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
            $body = $Body | ConvertFrom-Json
            if ($body -is [array]) {
                $response = @()
                $id = 100
                foreach ($item in $body) {
                    $response += [PSCustomObject]@{
                        id = $id++
                        name = $item.name
                        cluster = $item.cluster
                        vcpus = $item.vcpus
                        memory = $item.memory
                    }
                }
                return $response
            }
            else {
                return [PSCustomObject]@{
                    id = 100
                    name = $body.name
                    cluster = $body.cluster
                }
            }
        }
    }

    Context "Parameter Sets" {
        It "Should have Single and Bulk parameter sets" {
            $cmd = Get-Command New-NBVirtualMachine
            $cmd.ParameterSets.Name | Should -Contain 'Single'
            $cmd.ParameterSets.Name | Should -Contain 'Bulk'
        }
    }

    Context "Bulk Operations" {
        It "Should create VMs in bulk" {
            $vms = 1..5 | ForEach-Object {
                [PSCustomObject]@{
                    Name = "vm-$_"
                    Cluster = 1
                    vCPUs = 2
                    Memory = 4096
                }
            }

            $results = $vms | New-NBVirtualMachine -BatchSize 10 -Force

            $results.Count | Should -Be 5
        }

        It "Should handle Device_Role alias" {
            $vm = [PSCustomObject]@{
                Name = "alias-vm"
                Device_Role = 3
                Cluster = 1
            }

            $results = @($vm) | New-NBVirtualMachine -Force

            $results | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "New-NBIPAMVLAN Bulk Mode" -Tag 'Bulk', 'IPAM' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
        Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
            return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
        }
        Mock -CommandName 'Get-NBHostname' -ModuleName 'PowerNetbox' -MockWith { return 'netbox.domain.com' }
        Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 30 }
        Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }

        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }

        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
            $body = $Body | ConvertFrom-Json
            if ($body -is [array]) {
                $response = @()
                $id = 100
                foreach ($item in $body) {
                    $response += [PSCustomObject]@{
                        id = $id++
                        vid = $item.vid
                        name = $item.name
                        status = $item.status
                    }
                }
                return $response
            }
            else {
                return [PSCustomObject]@{
                    id = 100
                    vid = $body.vid
                    name = $body.name
                }
            }
        }
    }

    Context "Parameter Sets" {
        It "Should have Single and Bulk parameter sets" {
            $cmd = Get-Command New-NBIPAMVLAN
            $cmd.ParameterSets.Name | Should -Contain 'Single'
            $cmd.ParameterSets.Name | Should -Contain 'Bulk'
        }

        It "Should validate VID range in single mode" {
            $cmd = Get-Command New-NBIPAMVLAN
            $vidParam = $cmd.Parameters['VID']
            $validateRange = $vidParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }
            $validateRange.MinRange | Should -Be 1
            $validateRange.MaxRange | Should -Be 4094
        }
    }

    Context "Bulk Operations" {
        It "Should create VLANs in bulk" {
            $vlans = 100..104 | ForEach-Object {
                [PSCustomObject]@{
                    VID = $_
                    Name = "VLAN$_"
                    Status = "active"
                }
            }

            $results = $vlans | New-NBIPAMVLAN -BatchSize 10 -Force

            $results.Count | Should -Be 5
        }
    }
}

Describe "New-NBVirtualMachineInterface Bulk Mode" -Tag 'Bulk', 'Virtualization' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
        Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
            return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
        }
        Mock -CommandName 'Get-NBHostname' -ModuleName 'PowerNetbox' -MockWith { return 'netbox.domain.com' }
        Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 30 }
        Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }

        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }

        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
            $body = $Body | ConvertFrom-Json
            if ($body -is [array]) {
                $response = @()
                $id = 100
                foreach ($item in $body) {
                    $response += [PSCustomObject]@{
                        id = $id++
                        virtual_machine = $item.virtual_machine
                        name = $item.name
                        enabled = $item.enabled
                    }
                }
                return $response
            }
            else {
                return [PSCustomObject]@{
                    id = 100
                    virtual_machine = $body.virtual_machine
                    name = $body.name
                }
            }
        }
    }

    Context "Parameter Sets" {
        It "Should have Single and Bulk parameter sets" {
            $cmd = Get-Command New-NBVirtualMachineInterface
            $cmd.ParameterSets.Name | Should -Contain 'Single'
            $cmd.ParameterSets.Name | Should -Contain 'Bulk'
        }
    }

    Context "Bulk Operations" {
        It "Should create VM interfaces in bulk" {
            $interfaces = 0..4 | ForEach-Object {
                [PSCustomObject]@{
                    Virtual_Machine = 123
                    Name = "eth$_"
                }
            }

            $results = $interfaces | New-NBVirtualMachineInterface -BatchSize 10 -Force

            $results.Count | Should -Be 5
        }

        It "Should default enabled to true in bulk mode" {
            # Test that the function adds enabled=true by default
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                param($Body)
                $body = $Body | ConvertFrom-Json
                # Verify enabled was set to true
                $body[0].enabled | Should -Be $true
                return @([PSCustomObject]@{
                    id = 100
                    virtual_machine = 123
                    name = "eth0"
                    enabled = $body[0].enabled
                })
            }

            $interface = [PSCustomObject]@{
                Virtual_Machine = 123
                Name = "eth0"
            }

            $results = @($interface) | New-NBVirtualMachineInterface -Force

            $results | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Set-NBDCIMDevice Bulk Mode" -Tag 'Bulk', 'DCIM' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
        Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
            return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
        }
        Mock -CommandName 'Get-NBHostname' -ModuleName 'PowerNetbox' -MockWith { return 'netbox.domain.com' }
        Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 30 }
        Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }

        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }

        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
            $body = $Body | ConvertFrom-Json
            if ($body -is [array]) {
                $response = @()
                foreach ($item in $body) {
                    $response += [PSCustomObject]@{
                        id = $item.id
                        name = if ($item.name) { $item.name } else { "device-$($item.id)" }
                        status = $item.status
                    }
                }
                return $response
            }
            else {
                return [PSCustomObject]@{
                    id = $body.id
                    name = $body.name
                    status = $body.status
                }
            }
        }

        Mock -CommandName 'Get-NBDCIMDevice' -ModuleName 'PowerNetbox' -MockWith {
            return [PSCustomObject]@{
                Id = $Id
                Name = "device-$Id"
            }
        }
    }

    Context "Single Mode Operations" {
        It "Should update a single device by Id" {
            $result = Set-NBDCIMDevice -Id 100 -Status "active" -Force

            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -ModuleName 'PowerNetbox'
        }

        # Note: Array Id parameters are not supported for Set- functions
        # Use pipeline with InputObject for bulk operations (see "Bulk Operations" context below)

        It "Should update device name" {
            $result = Set-NBDCIMDevice -Id 100 -Name "renamed-device" -Force

            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -ModuleName 'PowerNetbox'
        }

        It "Should use Id directly without fetching device first (performance optimization)" {
            Set-NBDCIMDevice -Id 100 -Status "active" -Force

            # Should NOT call Get-NBDCIMDevice - uses Id directly for better performance (#177)
            Should -Invoke -CommandName 'Get-NBDCIMDevice' -Times 0 -ModuleName 'PowerNetbox'
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -ModuleName 'PowerNetbox'
        }
    }

    Context "Parameter Sets" {
        It "Should have Single and Bulk parameter sets" {
            $cmd = Get-Command Set-NBDCIMDevice
            $cmd.ParameterSets.Name | Should -Contain 'Single'
            $cmd.ParameterSets.Name | Should -Contain 'Bulk'
        }

        It "Should have Medium ConfirmImpact" {
            $cmd = Get-Command Set-NBDCIMDevice
            $attr = $cmd.ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }
            $attr.ConfirmImpact | Should -Be 'Medium'
        }
    }

    Context "Bulk Operations" {
        It "Should update devices in bulk" {
            $updates = @(
                [PSCustomObject]@{ Id = 100; Status = "active" }
                [PSCustomObject]@{ Id = 101; Status = "active" }
                [PSCustomObject]@{ Id = 102; Status = "planned" }
            )

            $results = $updates | Set-NBDCIMDevice -Force

            $results.Count | Should -Be 3
        }

        It "Should require Id property" {
            $invalidObj = [PSCustomObject]@{ Name = "no-id"; Status = "active" }

            { @($invalidObj) | Set-NBDCIMDevice -Force -ErrorAction Stop } | Should -Throw
        }
    }
}

Describe "Remove-NBDCIMDevice Bulk Mode" -Tag 'Bulk', 'DCIM' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
        Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
            return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
        }
        Mock -CommandName 'Get-NBHostname' -ModuleName 'PowerNetbox' -MockWith { return 'netbox.domain.com' }
        Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 30 }
        Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }

        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }

        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
            # DELETE returns null on success
            return $null
        }

        Mock -CommandName 'Get-NBDCIMDevice' -ModuleName 'PowerNetbox' -MockWith {
            return [PSCustomObject]@{
                Id = $Id
                Name = "device-$Id"
            }
        }
    }

    Context "Single Mode Operations" {
        It "Should delete a single device by Id" {
            { Remove-NBDCIMDevice -Id 100 -Force } | Should -Not -Throw

            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -ModuleName 'PowerNetbox'
        }

        # Note: Array Id parameters are not supported for Remove- functions
        # Use pipeline with InputObject for bulk operations (see "Bulk Operations" context below)

        It "Should use Id directly without fetching device first (performance optimization)" {
            Remove-NBDCIMDevice -Id 100 -Force

            # Should NOT call Get-NBDCIMDevice - uses Id directly for better performance (#182)
            Should -Invoke -CommandName 'Get-NBDCIMDevice' -Times 0 -ModuleName 'PowerNetbox'
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -ModuleName 'PowerNetbox'
        }
    }

    Context "Parameter Sets" {
        It "Should have Single and Bulk parameter sets" {
            $cmd = Get-Command Remove-NBDCIMDevice
            $cmd.ParameterSets.Name | Should -Contain 'Single'
            $cmd.ParameterSets.Name | Should -Contain 'Bulk'
        }

        It "Should have High ConfirmImpact" {
            $cmd = Get-Command Remove-NBDCIMDevice
            $attr = $cmd.ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }
            $attr.ConfirmImpact | Should -Be 'High'
        }
    }

    Context "Bulk Operations" {
        It "Should delete devices in bulk" {
            $devices = @(
                [PSCustomObject]@{ Id = 100; Name = "device-100" }
                [PSCustomObject]@{ Id = 101; Name = "device-101" }
            )

            { $devices | Remove-NBDCIMDevice -Force } | Should -Not -Throw
        }

        It "Should require Id property" {
            $invalidObj = [PSCustomObject]@{ Name = "no-id" }

            { @($invalidObj) | Remove-NBDCIMDevice -Force -ErrorAction Stop } | Should -Throw
        }

        It "Should batch delete requests" {
            $devices = 1..10 | ForEach-Object {
                [PSCustomObject]@{ Id = $_ }
            }

            $devices | Remove-NBDCIMDevice -BatchSize 3 -Force

            # 10 items / 3 batch size = 4 API calls
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 4 -Exactly -ModuleName 'PowerNetbox'
        }
    }
}

Describe "Set-NBIPAMAddress" -Tag 'Bulk', 'IPAM' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
        Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
            return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
        }
        Mock -CommandName 'Get-NBHostname' -ModuleName 'PowerNetbox' -MockWith { return 'netbox.domain.com' }
        Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 30 }
        Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }

        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }

        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
            $body = $Body | ConvertFrom-Json
            if ($body -is [array]) {
                $response = @()
                foreach ($item in $body) {
                    $response += [PSCustomObject]@{
                        id = $item.id
                        address = if ($item.address) { $item.address } else { "192.168.1.$($item.id)/24" }
                        status = @{ value = $item.status; label = $item.status }
                        description = $item.description
                    }
                }
                return $response
            }
            else {
                return [PSCustomObject]@{
                    id = $body.id
                    address = $body.address
                    status = @{ value = $body.status; label = $body.status }
                }
            }
        }

        Mock -CommandName 'Get-NBIPAMAddress' -ModuleName 'PowerNetbox' -MockWith {
            return [PSCustomObject]@{
                Id = $Id
                Address = "192.168.1.$Id/24"
            }
        }
    }

    Context "Single Mode Operations" {
        It "Should update a single IP address by Id" {
            $result = Set-NBIPAMAddress -Id 100 -Status "active" -Force

            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -ModuleName 'PowerNetbox'
        }

        # Note: Array Id parameters are not supported for Set- functions
        # Use pipeline with InputObject for bulk operations (see "Bulk Operations" context below)

        It "Should validate Assigned_Object_Type requires Assigned_Object_Id" {
            { Set-NBIPAMAddress -Id 100 -Assigned_Object_Type "dcim.interface" -Force -ErrorAction Stop } | Should -Throw
        }

        It "Should validate Assigned_Object_Id requires Assigned_Object_Type" {
            { Set-NBIPAMAddress -Id 100 -Assigned_Object_Id 50 -Force -ErrorAction Stop } | Should -Throw
        }

        It "Should accept both Assigned_Object_Type and Assigned_Object_Id together" {
            $result = Set-NBIPAMAddress -Id 100 -Assigned_Object_Type "dcim.interface" -Assigned_Object_Id 50 -Force

            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context "Parameter Sets" {
        It "Should have Single and Bulk parameter sets" {
            $cmd = Get-Command Set-NBIPAMAddress
            $cmd.ParameterSets.Name | Should -Contain 'Single'
            $cmd.ParameterSets.Name | Should -Contain 'Bulk'
        }

        It "Should have InputObject parameter for bulk mode" {
            $cmd = Get-Command Set-NBIPAMAddress
            $cmd.Parameters.Keys | Should -Contain 'InputObject'
            $inputObjParam = $cmd.Parameters['InputObject']
            $inputObjParam.ParameterSets.Keys | Should -Contain 'Bulk'
        }

        It "Should have BatchSize parameter with validation" {
            $cmd = Get-Command Set-NBIPAMAddress
            $cmd.Parameters.Keys | Should -Contain 'BatchSize'
            $batchSizeParam = $cmd.Parameters['BatchSize']
            $validateRange = $batchSizeParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }
            $validateRange | Should -Not -BeNullOrEmpty
            $validateRange.MinRange | Should -Be 1
            $validateRange.MaxRange | Should -Be 1000
        }

        It "Should have Medium ConfirmImpact" {
            $cmd = Get-Command Set-NBIPAMAddress
            $attr = $cmd.ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }
            $attr.ConfirmImpact | Should -Be 'Medium'
        }
    }

    Context "Bulk Operations" {
        It "Should update IP addresses in bulk via pipeline" {
            $updates = @(
                [PSCustomObject]@{ Id = 100; Status = "active" }
                [PSCustomObject]@{ Id = 101; Status = "active" }
                [PSCustomObject]@{ Id = 102; Status = "reserved" }
            )

            $results = $updates | Set-NBIPAMAddress -Force

            $results.Count | Should -Be 3
        }

        It "Should require Id property in InputObject" {
            $invalidObj = [PSCustomObject]@{ Address = "192.168.1.1/24"; Status = "active" }

            { @($invalidObj) | Set-NBIPAMAddress -Force -ErrorAction Stop } | Should -Throw
        }

        It "Should batch update requests" {
            $updates = 1..10 | ForEach-Object {
                [PSCustomObject]@{ Id = $_; Status = "active" }
            }

            $updates | Set-NBIPAMAddress -BatchSize 3 -Force

            # 10 items / 3 batch size = 4 API calls
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 4 -Exactly -ModuleName 'PowerNetbox'
        }
    }
}

Describe "Remove-NBIPAMAddress Bulk Mode" -Tag 'Bulk', 'IPAM' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
        Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
            return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
        }
        Mock -CommandName 'Get-NBHostname' -ModuleName 'PowerNetbox' -MockWith { return 'netbox.domain.com' }
        Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 30 }
        Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }

        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }

        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
            # DELETE returns null on success
            return $null
        }

    }

    Context "Single Mode Operations" {
        It "Should delete a single IP address by Id" {
            { Remove-NBIPAMAddress -Id 100 -Force } | Should -Not -Throw

            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -ModuleName 'PowerNetbox'
        }

        # Note: Array Id parameters are not supported for Remove- functions
        # Use pipeline with InputObject for bulk operations (see "Bulk Operations" context below)
    }

    Context "Parameter Sets" {
        It "Should have Single and Bulk parameter sets" {
            $cmd = Get-Command Remove-NBIPAMAddress
            $cmd.ParameterSets.Name | Should -Contain 'Single'
            $cmd.ParameterSets.Name | Should -Contain 'Bulk'
        }

        It "Should have InputObject parameter for bulk mode" {
            $cmd = Get-Command Remove-NBIPAMAddress
            $cmd.Parameters.Keys | Should -Contain 'InputObject'
            $inputObjParam = $cmd.Parameters['InputObject']
            $inputObjParam.ParameterSets.Keys | Should -Contain 'Bulk'
        }

        It "Should have BatchSize parameter with validation" {
            $cmd = Get-Command Remove-NBIPAMAddress
            $cmd.Parameters.Keys | Should -Contain 'BatchSize'
            $batchSizeParam = $cmd.Parameters['BatchSize']
            $validateRange = $batchSizeParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }
            $validateRange | Should -Not -BeNullOrEmpty
            $validateRange.MinRange | Should -Be 1
            $validateRange.MaxRange | Should -Be 1000
        }

        It "Should have High ConfirmImpact" {
            $cmd = Get-Command Remove-NBIPAMAddress
            $attr = $cmd.ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }
            $attr.ConfirmImpact | Should -Be 'High'
        }
    }

    Context "Bulk Operations" {
        It "Should delete IP addresses in bulk" {
            $addresses = @(
                [PSCustomObject]@{ Id = 100; Address = "192.168.1.100/24" }
                [PSCustomObject]@{ Id = 101; Address = "192.168.1.101/24" }
            )

            { $addresses | Remove-NBIPAMAddress -Force } | Should -Not -Throw
        }

        It "Should require Id property in InputObject" {
            $invalidObj = [PSCustomObject]@{ Address = "192.168.1.1/24" }

            { @($invalidObj) | Remove-NBIPAMAddress -Force -ErrorAction Stop } | Should -Throw
        }

        It "Should batch delete requests" {
            $addresses = 1..10 | ForEach-Object {
                [PSCustomObject]@{ Id = $_ }
            }

            $addresses | Remove-NBIPAMAddress -BatchSize 3 -Force

            # 10 items / 3 batch size = 4 API calls
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 4 -Exactly -ModuleName 'PowerNetbox'
        }
    }
}

Describe "Set-NBVirtualMachine Bulk Mode" -Tag 'Bulk', 'Virtualization' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
        Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
            return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
        }
        Mock -CommandName 'Get-NBHostname' -ModuleName 'PowerNetbox' -MockWith { return 'netbox.domain.com' }
        Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 30 }
        Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }

        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }

        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
            $body = $Body | ConvertFrom-Json
            if ($body -is [array]) {
                $response = @()
                foreach ($item in $body) {
                    $response += [PSCustomObject]@{
                        id = $item.id
                        name = if ($item.name) { $item.name } else { "vm-$($item.id)" }
                        status = @{ value = $item.status; label = $item.status }
                        comments = $item.comments
                    }
                }
                return $response
            }
            else {
                return [PSCustomObject]@{
                    id = $body.id
                    name = $body.name
                    status = @{ value = $body.status; label = $body.status }
                }
            }
        }

        Mock -CommandName 'Get-NBVirtualMachine' -ModuleName 'PowerNetbox' -MockWith {
            return [PSCustomObject]@{
                Id = $Id
                Name = "vm-$Id"
            }
        }
    }

    Context "Single Mode Operations" {
        It "Should update a single VM by Id" {
            $result = Set-NBVirtualMachine -Id 100 -Status "active" -Force

            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -ModuleName 'PowerNetbox'
        }

        It "Should update VM name" {
            $result = Set-NBVirtualMachine -Id 100 -Name "renamed-vm" -Force

            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -ModuleName 'PowerNetbox'
        }

        It "Should update VM with multiple parameters" {
            $result = Set-NBVirtualMachine -Id 100 -Status "active" -VCPUs 4 -Memory 8192 -Force

            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -ModuleName 'PowerNetbox'
        }

        It "Should support pipeline input by Id property" {
            $vm = [PSCustomObject]@{ Id = 100 }
            $result = $vm | Set-NBVirtualMachine -Status "offline" -Force

            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context "Parameter Sets" {
        It "Should have Single and Bulk parameter sets" {
            $cmd = Get-Command Set-NBVirtualMachine
            $cmd.ParameterSets.Name | Should -Contain 'Single'
            $cmd.ParameterSets.Name | Should -Contain 'Bulk'
        }

        It "Should have InputObject parameter for bulk mode" {
            $cmd = Get-Command Set-NBVirtualMachine
            $cmd.Parameters.Keys | Should -Contain 'InputObject'
            $inputObjParam = $cmd.Parameters['InputObject']
            $inputObjParam.ParameterSets.Keys | Should -Contain 'Bulk'
        }

        It "Should have BatchSize parameter with validation" {
            $cmd = Get-Command Set-NBVirtualMachine
            $cmd.Parameters.Keys | Should -Contain 'BatchSize'
            $batchSizeParam = $cmd.Parameters['BatchSize']
            $validateRange = $batchSizeParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }
            $validateRange | Should -Not -BeNullOrEmpty
            $validateRange.MinRange | Should -Be 1
            $validateRange.MaxRange | Should -Be 1000
        }

        It "Should have Medium ConfirmImpact" {
            $cmd = Get-Command Set-NBVirtualMachine
            $attr = $cmd.ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }
            $attr.ConfirmImpact | Should -Be 'Medium'
        }
    }

    Context "Bulk Operations" {
        It "Should update virtual machines in bulk via pipeline" {
            $updates = @(
                [PSCustomObject]@{ Id = 100; Status = "active" }
                [PSCustomObject]@{ Id = 101; Status = "active" }
                [PSCustomObject]@{ Id = 102; Status = "offline" }
            )

            $results = $updates | Set-NBVirtualMachine -Force

            $results.Count | Should -Be 3
        }

        It "Should require Id property in InputObject" {
            $invalidObj = [PSCustomObject]@{ Name = "vm-no-id"; Status = "active" }

            { @($invalidObj) | Set-NBVirtualMachine -Force -ErrorAction Stop } | Should -Throw
        }

        It "Should batch update requests" {
            $updates = 1..10 | ForEach-Object {
                [PSCustomObject]@{ Id = $_; Status = "active" }
            }

            $updates | Set-NBVirtualMachine -BatchSize 3 -Force

            # 10 items / 3 batch size = 4 API calls
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 4 -Exactly -ModuleName 'PowerNetbox'
        }
    }
}

Describe "Remove-NBVirtualMachine Bulk Mode" -Tag 'Bulk', 'Virtualization' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
        Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
            return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
        }
        Mock -CommandName 'Get-NBHostname' -ModuleName 'PowerNetbox' -MockWith { return 'netbox.domain.com' }
        Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 30 }
        Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }

        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }

        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
            # DELETE returns null on success
            return $null
        }

    }

    Context "Single Mode Operations" {
        It "Should delete a single VM by Id" {
            { Remove-NBVirtualMachine -Id 100 -Force } | Should -Not -Throw

            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -ModuleName 'PowerNetbox'
        }

        # Note: Array Id parameters are not supported for Remove- functions
        # Use pipeline with InputObject for bulk operations (see "Bulk Operations" context below)

        It "Should support pipeline input by Id property" {
            $vm = [PSCustomObject]@{ Id = 100 }
            { $vm | Remove-NBVirtualMachine -Force } | Should -Not -Throw

            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -ModuleName 'PowerNetbox'
        }
    }

    Context "Parameter Sets" {
        It "Should have Single and Bulk parameter sets" {
            $cmd = Get-Command Remove-NBVirtualMachine
            $cmd.ParameterSets.Name | Should -Contain 'Single'
            $cmd.ParameterSets.Name | Should -Contain 'Bulk'
        }

        It "Should have InputObject parameter for bulk mode" {
            $cmd = Get-Command Remove-NBVirtualMachine
            $cmd.Parameters.Keys | Should -Contain 'InputObject'
            $inputObjParam = $cmd.Parameters['InputObject']
            $inputObjParam.ParameterSets.Keys | Should -Contain 'Bulk'
        }

        It "Should have BatchSize parameter with validation" {
            $cmd = Get-Command Remove-NBVirtualMachine
            $cmd.Parameters.Keys | Should -Contain 'BatchSize'
            $batchSizeParam = $cmd.Parameters['BatchSize']
            $validateRange = $batchSizeParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }
            $validateRange | Should -Not -BeNullOrEmpty
            $validateRange.MinRange | Should -Be 1
            $validateRange.MaxRange | Should -Be 1000
        }

        It "Should have High ConfirmImpact" {
            $cmd = Get-Command Remove-NBVirtualMachine
            $attr = $cmd.ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }
            $attr.ConfirmImpact | Should -Be 'High'
        }
    }

    Context "Bulk Operations" {
        It "Should delete virtual machines in bulk" {
            $vms = @(
                [PSCustomObject]@{ Id = 100; Name = "vm-100" }
                [PSCustomObject]@{ Id = 101; Name = "vm-101" }
            )

            { $vms | Remove-NBVirtualMachine -Force } | Should -Not -Throw
        }

        It "Should require Id property in InputObject" {
            $invalidObj = [PSCustomObject]@{ Name = "vm-no-id" }

            { @($invalidObj) | Remove-NBVirtualMachine -Force -ErrorAction Stop } | Should -Throw
        }

        It "Should batch delete requests" {
            $vms = 1..10 | ForEach-Object {
                [PSCustomObject]@{ Id = $_ }
            }

            $vms | Remove-NBVirtualMachine -BatchSize 3 -Force

            # 10 items / 3 batch size = 4 API calls
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 4 -Exactly -ModuleName 'PowerNetbox'
        }
    }
}

Describe "Send-NBBulkRequest Edge Cases" -Tag 'Bulk', 'Unit' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
        Mock -CommandName 'Get-NBCredential' -ModuleName 'PowerNetbox' -MockWith {
            return [PSCredential]::new('notapplicable', (ConvertTo-SecureString -String "faketoken" -AsPlainText -Force))
        }
        Mock -CommandName 'Get-NBHostname' -ModuleName 'PowerNetbox' -MockWith { return 'netbox.domain.com' }
        Mock -CommandName 'Get-NBTimeout' -ModuleName 'PowerNetbox' -MockWith { return 30 }
        Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }

        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }
    }

    Context "BatchSize Boundary Tests" {
        BeforeEach {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                $body = $Body | ConvertFrom-Json
                $response = @()
                $id = 100
                foreach ($item in $body) {
                    $response += [PSCustomObject]@{ id = $id++; name = $item.name }
                }
                return $response
            }
        }

        It "Should handle BatchSize = 1 (maximum API calls)" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $uri = BuildNewURI -Segments @('dcim', 'devices')
                $items = 1..5 | ForEach-Object { [PSCustomObject]@{ name = "device$_" } }

                $result = Send-NBBulkRequest -URI $uri -Items $items -Method POST -BatchSize 1

                $result.SuccessCount | Should -Be 5
            }

            # 5 items with batch size 1 = 5 API calls
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 5 -Exactly -ModuleName 'PowerNetbox'
        }

        It "Should handle BatchSize = 1000 (maximum allowed)" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $uri = BuildNewURI -Segments @('dcim', 'devices')
                $items = 1..100 | ForEach-Object { [PSCustomObject]@{ name = "device$_" } }

                $result = Send-NBBulkRequest -URI $uri -Items $items -Method POST -BatchSize 1000

                $result.SuccessCount | Should -Be 100
            }

            # All 100 items in single batch
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Exactly -ModuleName 'PowerNetbox'
        }

        It "Should batch correctly when items exactly match BatchSize" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $uri = BuildNewURI -Segments @('dcim', 'devices')
                $items = 1..10 | ForEach-Object { [PSCustomObject]@{ name = "device$_" } }

                $result = Send-NBBulkRequest -URI $uri -Items $items -Method POST -BatchSize 10

                $result.SuccessCount | Should -Be 10
            }

            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 1 -Exactly -ModuleName 'PowerNetbox'
        }

        It "Should calculate batches correctly with odd remainder" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $uri = BuildNewURI -Segments @('dcim', 'devices')
                # 13 items, batch 5 = [5, 5, 3]
                $items = 1..13 | ForEach-Object { [PSCustomObject]@{ name = "device$_" } }

                $result = Send-NBBulkRequest -URI $uri -Items $items -Method POST -BatchSize 5

                $result.SuccessCount | Should -Be 13
            }

            # Should make 3 API calls (5 + 5 + 3)
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 3 -Exactly -ModuleName 'PowerNetbox'
        }
    }

    Context "Mixed Success/Failure Scenarios" {
        It "Should continue processing remaining batches after one fails" {
            $callCount = 0
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                $script:callCount++
                if ($script:callCount -eq 2) {
                    throw "API Error"
                }
                $body = $Body | ConvertFrom-Json
                $response = @()
                $id = 100 + ($script:callCount - 1) * 10
                foreach ($item in $body) {
                    $response += [PSCustomObject]@{ id = $id++; name = $item.name }
                }
                return $response
            }

            InModuleScope -ModuleName 'PowerNetbox' {
                $script:callCount = 0
                $uri = BuildNewURI -Segments @('dcim', 'devices')
                # 9 items, batch 3 = [3, 3, 3] - middle batch fails
                $items = 1..9 | ForEach-Object { [PSCustomObject]@{ name = "device$_" } }

                $result = Send-NBBulkRequest -URI $uri -Items $items -Method POST -BatchSize 3

                # First batch: 3 success, Second batch: 3 failed, Third batch: 3 success
                $result.SuccessCount | Should -Be 6
                $result.FailureCount | Should -Be 3
                $result.HasErrors | Should -BeTrue
            }

            # Should still call API 3 times (doesn't stop on error)
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 3 -Exactly -ModuleName 'PowerNetbox'
        }

        It "Should preserve error messages in failure records" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw "Validation failed: Invalid role ID"
            }

            InModuleScope -ModuleName 'PowerNetbox' {
                $uri = BuildNewURI -Segments @('dcim', 'devices')
                $originalItem = [PSCustomObject]@{ name = "device1"; role = 999 }
                $items = @($originalItem)

                $result = Send-NBBulkRequest -URI $uri -Items $items -Method POST

                $result.Failed.Count | Should -Be 1
                $result.Failed[0].Error | Should -Match "Validation failed"
                $result.Failed[0].Item.name | Should -Be "device1"
            }
        }
    }

    Context "DELETE Operation Handling" {
        It "Should handle null response from DELETE" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                return $null  # DELETE returns null on success
            }

            InModuleScope -ModuleName 'PowerNetbox' {
                $uri = BuildNewURI -Segments @('dcim', 'devices')
                $items = 1..3 | ForEach-Object { [PSCustomObject]@{ id = $_ } }

                $result = Send-NBBulkRequest -URI $uri -Items $items -Method DELETE

                # Null response = success for DELETE
                $result.SuccessCount | Should -Be 3
                $result.FailureCount | Should -Be 0
            }
        }
    }

    Context "Empty and Null Input Handling" {
        It "Should not invoke API when items collection is empty" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw "Should not be called"
            }

            InModuleScope -ModuleName 'PowerNetbox' {
                $uri = BuildNewURI -Segments @('dcim', 'devices')
                $items = @()

                $result = Send-NBBulkRequest -URI $uri -Items $items -Method POST

                $result.TotalCount | Should -Be 0
                $result.SuccessCount | Should -Be 0
                $result.HasErrors | Should -BeFalse
            }

            # Verify Invoke-RestMethod was never called
            Should -Invoke -CommandName 'Invoke-RestMethod' -Times 0 -Exactly -ModuleName 'PowerNetbox'
        }

        It "Should handle -ShowProgress with empty items" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $uri = BuildNewURI -Segments @('dcim', 'devices')

                { Send-NBBulkRequest -URI $uri -Items @() -Method POST -ShowProgress } | Should -Not -Throw
            }
        }
    }

    Context "Progress and Non-Throwing Behavior" {
        It "Should not throw exception during bulk operation failure" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                throw "Critical API Error"
            }

            InModuleScope -ModuleName 'PowerNetbox' {
                $uri = BuildNewURI -Segments @('dcim', 'devices')
                $items = 1..5 | ForEach-Object { [PSCustomObject]@{ name = "device$_" } }

                # Should NOT throw - should return result with failures
                { Send-NBBulkRequest -URI $uri -Items $items -Method POST -BatchSize 2 } | Should -Not -Throw
            }
        }
    }
}

Describe "BulkOperationResult Edge Cases" -Tag 'Bulk', 'Unit' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }

        InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }
    }

    It "Should report comprehensive error summary with multiple failures" {
        InModuleScope -ModuleName 'PowerNetbox' {
            $result = [BulkOperationResult]::new()

            $result.AddSuccess([PSCustomObject]@{ id = 1 })
            $result.AddSuccess([PSCustomObject]@{ id = 2 })
            $result.AddFailure([PSCustomObject]@{ name = "fail1" }, "Validation error 1")
            $result.AddFailure([PSCustomObject]@{ name = "fail2" }, "Validation error 2")
            $result.AddSuccess([PSCustomObject]@{ id = 3 })
            $result.Complete()

            $summary = $result.GetSummary()

            $summary | Should -Match "3/5 succeeded"
            $summary | Should -Match "2 failed"
        }
    }

    It "Should track all error messages" {
        InModuleScope -ModuleName 'PowerNetbox' {
            $result = [BulkOperationResult]::new()

            $result.AddFailure([PSCustomObject]@{ name = "fail1" }, "Error A")
            $result.AddFailure([PSCustomObject]@{ name = "fail2" }, "Error B")
            $result.Complete()

            $result.Errors.Count | Should -Be 2
            $result.Errors | Should -Contain "Error A"
            $result.Errors | Should -Contain "Error B"
        }
    }
}

Describe "Bulk Operations Live Integration Tests" -Tag 'Bulk', 'Integration', 'Live' -Skip:(-not ($env:NETBOX_HOST -and $env:NETBOX_TOKEN)) {
    BeforeAll {
        Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue
        $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
        if (-not (Test-Path $ModulePath)) {
            $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox.psd1"
        }
        Import-Module $ModulePath -Force

        # Build connect parameters from the environment, mirroring Integration.Tests.ps1:
        # parse "host:port", default the scheme to http for localhost (Docker/Podman CI)
        # and https otherwise, and honour an explicit $env:NETBOX_SCHEME override.
        $secureToken = ConvertTo-SecureString -String $env:NETBOX_TOKEN -AsPlainText -Force
        $credential = [PSCredential]::new('api', $secureToken)

        $hostValue = $env:NETBOX_HOST
        $hostname = $hostValue
        $port = $null
        if ($hostValue -match '^(.+):(\d+)$') {
            $hostname = $Matches[1]
            $port = [int]$Matches[2]
        }

        $scheme = $env:NETBOX_SCHEME
        if ([string]::IsNullOrEmpty($scheme)) {
            if ($hostname -match 'localhost|127\.0\.0\.1') { $scheme = 'http' } else { $scheme = 'https' }
        }

        $connectParams = @{
            Hostname   = $hostname
            Credential = $credential
            Scheme     = $scheme
        }
        if ($port) { $connectParams['Port'] = $port }
        if ($scheme -eq 'https') { $connectParams['SkipCertificateCheck'] = $true }

        Connect-NBAPI @connectParams

        # Create our own fixtures rather than relying on objects pre-existing in the
        # database: a fresh Docker/Podman image has no site/role/device-type/cluster.
        # Everything created here is torn down in AfterAll (reverse dependency order).
        $script:BulkRunId = [guid]::NewGuid().ToString().Substring(0, 8)
        $script:BulkCreated = @{
            ClusterType  = $null
            Cluster      = $null
            DeviceType   = $null
            DeviceRole   = $null
            Manufacturer = $null
            Site         = $null
        }

        $script:TestSite = New-NBDCIMSite -Name "bulk-$($script:BulkRunId)-site" -Slug "bulk-$($script:BulkRunId)-site" -Status 'active'
        $script:BulkCreated.Site = $script:TestSite

        $manufacturer = New-NBDCIMManufacturer -Name "bulk-$($script:BulkRunId)-mfr" -Slug "bulk-$($script:BulkRunId)-mfr"
        $script:BulkCreated.Manufacturer = $manufacturer

        $script:TestType = New-NBDCIMDeviceType -Model "bulk-$($script:BulkRunId)-type" -Slug "bulk-$($script:BulkRunId)-type" -Manufacturer $manufacturer.id
        $script:BulkCreated.DeviceType = $script:TestType

        $script:TestRole = New-NBDCIMDeviceRole -Name "bulk-$($script:BulkRunId)-role" -Slug "bulk-$($script:BulkRunId)-role" -Color '0000ff'
        $script:BulkCreated.DeviceRole = $script:TestRole

        $clusterType = New-NBVirtualizationClusterType -Name "bulk-$($script:BulkRunId)-ct" -Slug "bulk-$($script:BulkRunId)-ct"
        $script:BulkCreated.ClusterType = $clusterType

        $script:TestCluster = New-NBVirtualizationCluster -Name "bulk-$($script:BulkRunId)-cluster" -Type $clusterType.id
        $script:BulkCreated.Cluster = $script:TestCluster

        $script:skipTests = $false
    }

    It "Should bulk create and delete devices (live)" {
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $devices = 1..5 | ForEach-Object {
            [PSCustomObject]@{
                Name = "bulk-test-$_-$timestamp"
                Role = $script:TestRole.id
                Device_Type = $script:TestType.id
                Site = $script:TestSite.id
            }
        }

        # Bulk create
        $created = $devices | New-NBDCIMDevice -BatchSize 3 -Force

        try {
            $created.Count | Should -Be 5
            $created | ForEach-Object { $_.id | Should -BeGreaterThan 0 }
        }
        finally {
            # Bulk delete cleanup
            $created | Remove-NBDCIMDevice -Force
        }
    }

    It "Should bulk create VMs (live)" {
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $vms = 1..3 | ForEach-Object {
            [PSCustomObject]@{
                Name = "bulk-vm-$_-$timestamp"
                Cluster = $script:TestCluster.id
                vCPUs = 2
                Memory = 2048
            }
        }

        $created = $vms | New-NBVirtualMachine -BatchSize 10 -Force

        try {
            $created.Count | Should -Be 3
        }
        finally {
            # Cleanup
            $created | ForEach-Object {
                Remove-NBVirtualMachine -Id $_.id -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It "Should bulk update devices (live)" {
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"

        # Create test devices first
        $devices = 1..3 | ForEach-Object {
            [PSCustomObject]@{
                Name = "bulk-update-$_-$timestamp"
                Role = $script:TestRole.id
                Device_Type = $script:TestType.id
                Site = $script:TestSite.id
                Status = "planned"
            }
        }

        $created = $devices | New-NBDCIMDevice -BatchSize 10 -Force

        try {
            # Bulk update
            $updates = $created | ForEach-Object {
                [PSCustomObject]@{
                    Id = $_.id
                    Status = "active"
                    Comments = "Bulk updated at $timestamp"
                }
            }

            $updated = $updates | Set-NBDCIMDevice -Force

            $updated.Count | Should -Be 3
            $updated | ForEach-Object { $_.status.value | Should -Be "active" }
        }
        finally {
            # Cleanup
            $created | Remove-NBDCIMDevice -Force
        }
    }

    AfterAll {
        # Tear down fixtures in reverse dependency order. Bulk-created Devices/VMs are
        # already removed in each It's finally block; this removes the reference data.
        $cleanup = @(
            @{ Command = 'Remove-NBVirtualizationCluster';     Id = $script:BulkCreated.Cluster.id }
            @{ Command = 'Remove-NBVirtualizationClusterType'; Id = $script:BulkCreated.ClusterType.id }
            @{ Command = 'Remove-NBDCIMDeviceType';            Id = $script:BulkCreated.DeviceType.id }
            @{ Command = 'Remove-NBDCIMDeviceRole';            Id = $script:BulkCreated.DeviceRole.id }
            @{ Command = 'Remove-NBDCIMManufacturer';          Id = $script:BulkCreated.Manufacturer.id }
            @{ Command = 'Remove-NBDCIMSite';                  Id = $script:BulkCreated.Site.id }
        )
        foreach ($item in $cleanup) {
            if ($item.Id) {
                try { & $item.Command -Id $item.Id -Confirm:$false -ErrorAction Stop }
                catch { Write-Warning "Bulk fixture cleanup failed for $($item.Command) ID $($item.Id): $($_.Exception.Message)" }
            }
        }
    }
}
