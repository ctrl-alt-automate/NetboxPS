param()

BeforeAll {
    Import-Module Pester
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -ErrorAction Stop
    }

    $script:TestPath = $PSScriptRoot
}

Describe "Virtualization tests" -Tag 'Virtualization' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
        Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
            return [ordered]@{
                'Method' = if ($Method) { $Method } else { 'GET' }
                'Uri'    = $URI.Uri.AbsoluteUri
                'Body'   = if ($Body) { $Body | ConvertTo-Json -Compress } else { $null }
            }
        }

        InModuleScope -ModuleName 'PowerNetbox' -ArgumentList $script:TestPath -ScriptBlock {
            param($TestPath)
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
        }
    }

    Context "Get-NBVirtualMachine" {
        It "Should request the default number of VMs" {
            $Result = Get-NBVirtualMachine
            $Result.Method | Should -Be 'GET'
            # By default, config_context is excluded for performance
            $Result.Uri | Should -Match 'omit=config_context'
        }

        It "Should request with limit and offset" {
            $Result = Get-NBVirtualMachine -Limit 10 -Offset 12
            $Result.Method | Should -Be 'GET'
            # Parameter order in hashtables is not guaranteed
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=12'
            $Result.Uri | Should -Match 'omit=config_context'
        }

        It "Should request with a query" {
            $Result = Get-NBVirtualMachine -Query 'testvm'
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Match 'q=testvm'
            $Result.Uri | Should -Match 'omit=config_context'
        }

        It "Should request with an escaped query" {
            $Result = Get-NBVirtualMachine -Query 'test vm'
            $Result.Method | Should -Be 'GET'
            # UriBuilder encodes spaces as %20 in the URI
            $Result.Uri | Should -Match 'q=test%20vm'
            $Result.Uri | Should -Match 'omit=config_context'
        }

        It "Should request with a name" {
            $Result = Get-NBVirtualMachine -Name 'testvm'
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Match 'name=testvm'
            $Result.Uri | Should -Match 'omit=config_context'
        }

        It "Should request with a single ID" {
            $Result = Get-NBVirtualMachine -Id 10
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Match 'virtualization/virtual-machines/10/'
            $Result.Uri | Should -Match 'omit=config_context'
        }

        It "Should request with multiple IDs" {
            $Result = Get-NBVirtualMachine -Id 10, 12, 15

            $Result | Should -HaveCount 3
            $Result[0].Method | Should -Be 'GET'
            $Result[0].Uri | Should -Match 'virtualization/virtual-machines/10/'
            $Result[1].Uri | Should -Match 'virtualization/virtual-machines/12/'
            $Result[2].Uri | Should -Match 'virtualization/virtual-machines/15/'
            $Result | ForEach-Object { $_.Uri | Should -Match 'omit=config_context' }
        }

        It "Should request a status" {
            $Result = Get-NBVirtualMachine -Status 'Active'
            $Result.Method | Should -Be 'GET'
            # Status value is passed through to API as-is (no client-side validation)
            $Result.Uri | Should -Match 'status=Active'
            $Result.Uri | Should -Match 'omit=config_context'
        }

        It "Should have ValidateSet for Status parameter" {
            # Status parameter now uses ValidateSet for type safety
            $cmd = Get-Command Get-NBVirtualMachine
            $statusParam = $cmd.Parameters['Status']
            $validateSet = $statusParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.ValidValues | Should -Contain 'active'
        }

        It "Should not exclude config_context when IncludeConfigContext is specified" {
            $Result = Get-NBVirtualMachine -IncludeConfigContext
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Not -Match 'omit=config_context'
        }

        It "Should request with Brief mode" {
            $Result = Get-NBVirtualMachine -Brief
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Match 'brief=True'
        }

        It "Should request with specific fields" {
            $Result = Get-NBVirtualMachine -Fields 'id','name','status','site.name'
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Match 'fields=id(%2C|,)name(%2C|,)status(%2C|,)site.name'
        }

        Context "Status drift fix (#392 item 4)" {
            It "Should accept -Status 'paused'" {
                $Result = Get-NBVirtualMachine -Status 'paused'
                $Result.Uri | Should -Match 'status=paused'
            }
        }

        Context "Brief/Fields/Omit interaction with IncludeConfigContext (#397 PR-2)" {
            It "With -Brief: URI contains brief=True and no config_context omit" {
                $Result = Get-NBVirtualMachine -Brief
                $Result.Uri | Should -Match 'brief=True'
                $Result.Uri | Should -Not -Match 'omit=config_context'
            }

            It "With -Fields: URI contains the fields parameter and no config_context omit" {
                $Result = Get-NBVirtualMachine -Fields 'id', 'name'
                $Result.Uri | Should -Match 'fields=(?=.*id)(?=.*name)'
                $Result.Uri | Should -Not -Match 'omit=config_context'
            }

            It "With -Omit: URI contains the user's omit value merged with config_context" {
                $Result = Get-NBVirtualMachine -Omit 'comments'
                $Result.Uri | Should -Match 'omit='
                $Result.Uri | Should -Match 'comments'
                $Result.Uri | Should -Match 'config_context'
            }

            It "With -IncludeConfigContext -Brief: URI contains brief=True only (IncludeConfigContext silently ignored)" {
                $Result = Get-NBVirtualMachine -IncludeConfigContext -Brief
                $Result.Uri | Should -Match 'brief=True'
                $Result.Uri | Should -Not -Match 'config_context'
            }

            It "With no projection flags: URI contains the default config_context auto-omit" {
                $Result = Get-NBVirtualMachine
                $Result.Uri | Should -Match 'omit=config_context'
            }
        }
    }

    Context "Get-NBVirtualMachineInterface" {
        It "Should request the default number of interfaces" {
            $Result = Get-NBVirtualMachineInterface
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/interfaces/'
        }

        It "Should request with a limit and offset" {
            $Result = Get-NBVirtualMachineInterface -Limit 10 -Offset 12
            $Result.Method | Should -Be 'GET'
            # Parameter order in hashtables is not guaranteed
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=12'
        }

        It "Should request a interface with a specific ID" {
            $Result = Get-NBVirtualMachineInterface -Id 10
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/interfaces/10/'
        }

        It "Should request a name" {
            $Result = Get-NBVirtualMachineInterface -Name 'Ethernet0'
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/interfaces/?name=Ethernet0'
        }

        It "Should request with a VM ID" {
            $Result = Get-NBVirtualMachineInterface -Virtual_Machine_Id 10
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/interfaces/?virtual_machine_id=10'
        }

        It "Should request with Enabled" {
            $Result = Get-NBVirtualMachineInterface -Enabled $true
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/interfaces/?enabled=true'
        }
    }

    Context "Get-NBVirtualMachineCluster" {
        It "Should request the default number of clusters" {
            $Result = Get-NBVirtualizationCluster
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/clusters/'
        }

        It "Should request with limit and offset" {
            $Result = Get-NBVirtualizationCluster -Limit 10 -Offset 12
            $Result.Method | Should -Be 'GET'
            # Parameter order in hashtables is not guaranteed
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=12'
        }

        It "Should request with a query" {
            $Result = Get-NBVirtualizationCluster -Query 'testcluster'
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/clusters/?q=testcluster'
        }

        It "Should request with an escaped query" {
            $Result = Get-NBVirtualizationCluster -Query 'test cluster'
            $Result.Method | Should -Be 'GET'
            # UriBuilder encodes spaces as %20 in the URI
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/clusters/?q=test%20cluster'
        }

        It "Should request with a name" {
            $Result = Get-NBVirtualizationCluster -Name 'testcluster'
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/clusters/?name=testcluster'
        }

        It "Should request with a single ID" {
            $Result = Get-NBVirtualizationCluster -Id 10
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/clusters/10/'
        }

        It "Should request with multiple IDs" {
            $Result = Get-NBVirtualizationCluster -Id 10, 12, 15

            $Result | Should -HaveCount 3
            $Result[0].Method | Should -Be 'GET'
            $Result[0].Uri | Should -Match 'virtualization/clusters/10/'
            $Result[1].Uri | Should -Match 'virtualization/clusters/12/'
            $Result[2].Uri | Should -Match 'virtualization/clusters/15/'
        }
    }

    Context "Get-NBVirtualMachineClusterGroup" {
        It "Should request the default number of cluster groups" {
            $Result = Get-NBVirtualizationClusterGroup
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/cluster-groups/'
        }

        It "Should request with limit and offset" {
            $Result = Get-NBVirtualizationClusterGroup -Limit 10 -Offset 12
            $Result.Method | Should -Be 'GET'
            # Parameter order in hashtables is not guaranteed
            $Result.Uri | Should -Match 'limit=10'
            $Result.Uri | Should -Match 'offset=12'
        }

        It "Should request with a name" {
            $Result = Get-NBVirtualizationClusterGroup -Name 'testclustergroup'
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/cluster-groups/?name=testclustergroup'
        }

        It "Should request with a slug" {
            $Result = Get-NBVirtualizationClusterGroup -Slug 'test-cluster-group'
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/cluster-groups/?slug=test-cluster-group'
        }

        It "Should request a cluster group by ID" {
            $Result = Get-NBVirtualizationClusterGroup -Id 5
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Match '/api/virtualization/cluster-groups/5/'
        }
    }

    Context "New-NBVirtualMachine" {
        It "Should create a basic VM" {
            $Result = New-NBVirtualMachine -Name 'testvm' -Cluster 1
            Should -Invoke -CommandName 'InvokeNetboxRequest' -Times 1 -Exactly -Scope 'It' -ModuleName 'PowerNetbox'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/virtual-machines/'
            # Module no longer adds default status
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'testvm'
            $bodyObj.cluster | Should -Be 1
        }

        It "Should create a device-attached VM without a cluster (NetBox 4.6+, #12024)" {
            $Result = New-NBVirtualMachine -Name 'edge-vm' -Device 7
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.device | Should -Be 7
            $bodyObj.PSObject.Properties.Name | Should -Not -Contain 'cluster'
        }

        It "Should send virtual_machine_type (NetBox 4.6+, #5795)" {
            $Result = New-NBVirtualMachine -Name 'typed-vm' -Cluster 1 -Virtual_Machine_Type 4
            ($Result.Body | ConvertFrom-Json).virtual_machine_type | Should -Be 4
        }

        It "Should create a VM with CPUs, Memory, Disk, tenancy, and comments" {
            $Result = New-NBVirtualMachine -Name 'testvm' -Cluster 1 -Status Active -vCPUs 4 -Memory 4096 -Tenant 11 -Disk 50 -Comments "these are comments"
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/virtual-machines/'
            # Compare as objects since JSON key order is not guaranteed
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'testvm'
            $bodyObj.cluster | Should -Be 1
            $bodyObj.status | Should -Be 'Active'
            $bodyObj.vcpus | Should -Be 4
            $bodyObj.memory | Should -Be 4096
            $bodyObj.tenant | Should -Be 11
            $bodyObj.disk | Should -Be 50
            $bodyObj.comments | Should -Be "these are comments"
        }

        It "Should have ValidateSet for Status parameter" {
            # Status parameter now uses ValidateSet for type safety
            $cmd = Get-Command New-NBVirtualMachine
            $statusParam = $cmd.Parameters['Status']
            $validateSet = $statusParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.ValidValues | Should -Contain 'active'
        }

        It "Should create a VM with Start_On_Boot (Netbox 4.5+)" {
            $Result = New-NBVirtualMachine -Name 'testvm' -Cluster 1 -Start_On_Boot 'on'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.start_on_boot | Should -Be 'on'
        }

        It "Should create a VM with Start_On_Boot set to laststate" {
            $Result = New-NBVirtualMachine -Name 'testvm' -Cluster 1 -Start_On_Boot 'laststate'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.start_on_boot | Should -Be 'laststate'
        }
    }

    Context "New-NBVirtualMachineInterface" {
        It "Should add a basic interface" {
            $Result = New-NBVirtualMachineInterface -Name 'Ethernet0' -Virtual_Machine 10
            Should -Invoke -CommandName 'InvokeNetboxRequest' -Times 1 -Exactly -Scope 'It' -ModuleName 'PowerNetbox'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/interfaces/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'Ethernet0'
            $bodyObj.virtual_machine | Should -Be 10
            $bodyObj.enabled | Should -Be $true
        }

        Context "Mode drift fix (#392 item 7)" {
            It "Should accept -Mode 'q-in-q'" {
                $Result = New-NBVirtualMachineInterface -Virtual_Machine 1 -Name 'eth0' -Mode 'q-in-q'
                ($Result.Body | ConvertFrom-Json).mode | Should -Be 'q-in-q'
            }
        }

        It "Should add an interface with a MAC, MTU, and Description" {
            $Result = New-NBVirtualMachineInterface -Name 'Ethernet0' -Virtual_Machine 10 -Mac_Address '11:22:33:44:55:66' -MTU 1500 -Description "Test description"
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/interfaces/'
            # Compare as objects since JSON key order is not guaranteed
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'Ethernet0'
            $bodyObj.virtual_machine | Should -Be 10
            $bodyObj.mac_address | Should -Be '11:22:33:44:55:66'
            $bodyObj.mtu | Should -Be 1500
            $bodyObj.description | Should -Be "Test description"
            $bodyObj.enabled | Should -Be $true
        }

        Context "Status drift fix (#392 item 4)" {
            It "Should accept -Status 'paused'" {
                $Result = New-NBVirtualMachine -Name 'vm' -Status 'paused' -Cluster 1
                ($Result.Body | ConvertFrom-Json).status | Should -Be 'paused'
            }
        }
    }

    Context "Set-NBVirtualMachine" {
        It "Should set a VM to a new name" {
            $Result = Set-NBVirtualMachine -Id 1234 -Name 'newtestname' -Confirm:$false
            # Set-NBVirtualMachine no longer calls Get-NBVirtualMachine (optimized)
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/virtualization/virtual-machines/1234/'
            $Result.Body | Should -Be '{"name":"newtestname"}'
        }

        It "Should set device + virtual_machine_type (NetBox 4.6+)" {
            $Result = Set-NBVirtualMachine -Id 1234 -Device 7 -Virtual_Machine_Type 4 -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.device | Should -Be 7
            $bodyObj.virtual_machine_type | Should -Be 4
        }

        It "Should clear device with `$null (NetBox 4.6+)" {
            $Result = Set-NBVirtualMachine -Id 1234 -Device $null -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.PSObject.Properties.Name | Should -Contain 'device'
            $bodyObj.device | Should -BeNullOrEmpty
        }

        It "Should set a VM with a new name, cluster, platform, and status" {
            $Result = Set-NBVirtualMachine -Id 1234 -Name 'newtestname' -Cluster 10 -Platform 15 -Status 'Offline' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/virtualization/virtual-machines/1234/'
            # Compare as objects since JSON key order is not guaranteed
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'newtestname'
            $bodyObj.cluster | Should -Be 10
            $bodyObj.platform | Should -Be 15
            # Status is passed through to API as-is
            $bodyObj.status | Should -Be 'Offline'
        }

        It "Should have ValidateSet for Status parameter" {
            # Status parameter now uses ValidateSet for type safety
            $cmd = Get-Command Set-NBVirtualMachine
            $statusParam = $cmd.Parameters['Status']
            $validateSet = $statusParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.ValidValues | Should -Contain 'active'
        }

        It "Should update a VM with Start_On_Boot (Netbox 4.5+)" {
            $Result = Set-NBVirtualMachine -Id 1234 -Start_On_Boot 'off' -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.start_on_boot | Should -Be 'off'
        }

        Context "Status drift fix (#392 item 4)" {
            It "Should accept -Status 'paused'" {
                $Result = Set-NBVirtualMachine -Id 1 -Status 'paused' -Confirm:$false
                ($Result.Body | ConvertFrom-Json).status | Should -Be 'paused'
            }
        }
    }

    Context "Set-NBVirtualMachineInterface" {
        It "Should set an interface to a new name" {
            $Result = Set-NBVirtualMachineInterface -Id 1234 -Name 'newtestname' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/virtualization/interfaces/1234/'
            $Result.Body | Should -Be '{"name":"newtestname"}'
        }

        It "Should set an interface to a new name, MTU, MAC address and description" {
            $paramSetNetboxVirtualMachineInterface = @{
                Id          = 1234
                Name        = 'newtestname'
                MAC_Address = '11:22:33:44:55:66'
                MTU         = 9000
                Description = "Test description"
                Confirm     = $false
            }
            $Result = Set-NBVirtualMachineInterface @paramSetNetboxVirtualMachineInterface
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/virtualization/interfaces/1234/'
            # Compare as objects since JSON key order is not guaranteed
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'newtestname'
            $bodyObj.mac_address | Should -Be '11:22:33:44:55:66'
            $bodyObj.mtu | Should -Be 9000
            $bodyObj.description | Should -Be "Test description"
        }

        It "Should set multiple interfaces to a new name from the pipeline" {
            $Result = @(
                [pscustomobject]@{ 'Id' = 4123 },
                [pscustomobject]@{ 'Id' = 4321 }
            ) | Set-NBVirtualMachineInterface -Name 'newtestname' -Confirm:$false
            $Result.Method | Should -Be 'PATCH', 'PATCH'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/virtualization/interfaces/4123/', 'https://netbox.domain.com/api/virtualization/interfaces/4321/'
            $Result.Body | Should -Be '{"name":"newtestname"}', '{"name":"newtestname"}'
        }
    }

    Context "Remove-NBVirtualMachine" {
        It "Should remove a single VM" {
            $Result = Remove-NBVirtualMachine -Id 4125 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/virtualization/virtual-machines/4125/'
        }

        It "Should remove a VM from the pipeline" {
            # Use a pscustomobject with Id property instead of calling Get-NBVirtualMachine
            $Result = [pscustomobject]@{ 'Id' = 4125 } | Remove-NBVirtualMachine -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/virtualization/virtual-machines/4125/'
        }

        It "Should remove multiple VMs from the pipeline" {
            $Result = @(
                [pscustomobject]@{ 'Id' = 4125 },
                [pscustomobject]@{ 'Id' = 4132 }
            ) | Remove-NBVirtualMachine -Confirm:$false
            $Result.Method | Should -Be 'DELETE', 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/virtualization/virtual-machines/4125/', 'https://netbox.domain.com/api/virtualization/virtual-machines/4132/'
        }
    }

    Context "Remove-NBVirtualMachineInterface" {
        It "Should remove a single interface" {
            $Result = Remove-NBVirtualMachineInterface -Id 100 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Be 'https://netbox.domain.com/api/virtualization/interfaces/100/'
        }

        It "Should remove multiple interfaces via pipeline" {
            # Remove- functions only accept single Id; use pipeline for bulk operations
            $Result = @(
                [pscustomobject]@{ 'Id' = 100 },
                [pscustomobject]@{ 'Id' = 101 }
            ) | Remove-NBVirtualMachineInterface -Confirm:$false
            $Result.Method | Should -Be 'DELETE', 'DELETE'
        }
    }

    #region Cluster CRUD Tests
    Context "New-NBVirtualizationCluster" {
        It "Should create a cluster" {
            $Result = New-NBVirtualizationCluster -Name 'test-cluster' -Type 1
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/clusters/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'test-cluster'
            $bodyObj.type | Should -Be 1
        }

        It "Should create a cluster with site and group" {
            $Result = New-NBVirtualizationCluster -Name 'test-cluster' -Type 1 -Site 5 -Group 2
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.site | Should -Be 5
            $bodyObj.group | Should -Be 2
        }
    }

    Context "Set-NBVirtualizationCluster" {
        BeforeAll {
            Mock -CommandName "Get-NBVirtualizationCluster" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestCluster' }
            }
        }

        It "Should update a cluster" {
            $Result = Set-NBVirtualizationCluster -Id 1 -Name 'updated-cluster' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/virtualization/clusters/1/'
        }

        It "Should update cluster description" {
            $Result = Set-NBVirtualizationCluster -Id 1 -Description 'Updated description' -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.description | Should -Be 'Updated description'
        }
    }

    Context "Remove-NBVirtualizationCluster" {
        BeforeAll {
            Mock -CommandName "Get-NBVirtualizationCluster" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestCluster' }
            }
        }

        It "Should remove a cluster" {
            $Result = Remove-NBVirtualizationCluster -Id 5 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/virtualization/clusters/5/'
        }
    }
    #endregion

    #region ClusterGroup CRUD Tests
    Context "New-NBVirtualizationClusterGroup" {
        It "Should create a cluster group" {
            $Result = New-NBVirtualizationClusterGroup -Name 'test-group' -Slug 'test-group'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/cluster-groups/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'test-group'
            $bodyObj.slug | Should -Be 'test-group'
        }
    }

    Context "Set-NBVirtualizationClusterGroup" {
        BeforeAll {
            Mock -CommandName "Get-NBVirtualizationClusterGroup" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestGroup' }
            }
        }

        It "Should update a cluster group" {
            $Result = Set-NBVirtualizationClusterGroup -Id 1 -Name 'updated-group' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/virtualization/cluster-groups/1/'
        }
    }

    Context "Remove-NBVirtualizationClusterGroup" {
        BeforeAll {
            Mock -CommandName "Get-NBVirtualizationClusterGroup" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestGroup' }
            }
        }

        It "Should remove a cluster group" {
            $Result = Remove-NBVirtualizationClusterGroup -Id 3 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/virtualization/cluster-groups/3/'
        }
    }
    #endregion

    #region ClusterType Tests
    Context "Get-NBVirtualizationClusterType" {
        It "Should request cluster types" {
            $Result = Get-NBVirtualizationClusterType
            $Result.Method | Should -Be 'GET'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/cluster-types/'
        }

        It "Should request a cluster type by ID" {
            $Result = Get-NBVirtualizationClusterType -Id 5
            $Result.Uri | Should -Match '/api/virtualization/cluster-types/5/'
        }

        It "Should request a cluster type by name" {
            $Result = Get-NBVirtualizationClusterType -Name 'VMware'
            $Result.Uri | Should -Match 'name=VMware'
        }

        It "Should request a cluster type by slug" {
            $Result = Get-NBVirtualizationClusterType -Slug 'vmware'
            $Result.Uri | Should -Match 'slug=vmware'
        }
    }

    Context "New-NBVirtualizationClusterType" {
        It "Should create a cluster type" {
            $Result = New-NBVirtualizationClusterType -Name 'Hyper-V' -Slug 'hyper-v'
            $Result.Method | Should -Be 'POST'
            $Result.Uri | Should -Be 'https://netbox.domain.com/api/virtualization/cluster-types/'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.name | Should -Be 'Hyper-V'
            $bodyObj.slug | Should -Be 'hyper-v'
        }

        It "Should create a cluster type with description" {
            $Result = New-NBVirtualizationClusterType -Name 'Hyper-V' -Slug 'hyper-v' -Description 'Microsoft Hyper-V'
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.description | Should -Be 'Microsoft Hyper-V'
        }
    }

    Context "Set-NBVirtualizationClusterType" {
        BeforeAll {
            Mock -CommandName "Get-NBVirtualizationClusterType" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestType' }
            }
        }

        It "Should update a cluster type" {
            $Result = Set-NBVirtualizationClusterType -Id 1 -Name 'updated-type' -Confirm:$false
            $Result.Method | Should -Be 'PATCH'
            $Result.URI | Should -Match '/api/virtualization/cluster-types/1/'
        }

        It "Should update cluster type description" {
            $Result = Set-NBVirtualizationClusterType -Id 1 -Description 'Updated description' -Confirm:$false
            $bodyObj = $Result.Body | ConvertFrom-Json
            $bodyObj.description | Should -Be 'Updated description'
        }
    }

    Context "Remove-NBVirtualizationClusterType" {
        BeforeAll {
            Mock -CommandName "Get-NBVirtualizationClusterType" -ModuleName PowerNetbox -MockWith {
                return [pscustomobject]@{ 'Id' = $Id; 'Name' = 'TestType' }
            }
        }

        It "Should remove a cluster type" {
            $Result = Remove-NBVirtualizationClusterType -Id 2 -Confirm:$false
            $Result.Method | Should -Be 'DELETE'
            $Result.URI | Should -Match '/api/virtualization/cluster-types/2/'
        }
    }
    #endregion

    #region Parameter Validation Tests
    Context "Parameter Validation" {
        It "Should reject invalid Status for New-NBVirtualMachine" {
            { New-NBVirtualMachine -Name 'test' -Status 'invalid' -Confirm:$false } | Should -Throw
        }

        It "Should reject invalid Start_On_Boot for New-NBVirtualMachine" {
            { New-NBVirtualMachine -Name 'test' -Start_On_Boot 'maybe' -Confirm:$false } | Should -Throw
        }

        It "Should reject invalid Mode for New-NBVirtualMachineInterface" {
            { New-NBVirtualMachineInterface -Virtual_Machine 1 -Name 'test' -Mode 'invalid' -Confirm:$false } | Should -Throw
        }

        It "Should reject MTU below minimum (0) for New-NBVirtualMachineInterface" {
            { New-NBVirtualMachineInterface -Virtual_Machine 1 -Name 'test' -MTU 0 -Confirm:$false } | Should -Throw
        }

        It "Should reject MTU above maximum (65536) for New-NBVirtualMachineInterface" {
            { New-NBVirtualMachineInterface -Virtual_Machine 1 -Name 'test' -MTU 65536 -Confirm:$false } | Should -Throw
        }

        It "Should require mandatory Name for New-NBVirtualMachine" {
            { New-NBVirtualMachine -Cluster 1 -Confirm:$false } | Should -Throw
        }

        It "Should require mandatory Type for New-NBVirtualizationCluster" {
            { New-NBVirtualizationCluster -Name 'test' -Confirm:$false } | Should -Throw
        }
    }
    #endregion

    #region WhatIf Tests
    Context "WhatIf Support" {
        $whatIfTestCases = @(
            @{ Command = 'New-NBVirtualizationCluster'; Parameters = @{ Name = 'whatif-test'; Type = 1 } }
            @{ Command = 'New-NBVirtualizationClusterGroup'; Parameters = @{ Name = 'whatif-test' } }
            @{ Command = 'New-NBVirtualizationClusterType'; Parameters = @{ Name = 'whatif-test' } }
            @{ Command = 'New-NBVirtualMachine'; Parameters = @{ Name = 'whatif-test' } }
            @{ Command = 'New-NBVirtualMachineInterface'; Parameters = @{ Name = 'whatif-test'; Virtual_Machine = 1 } }
            @{ Command = 'Set-NBVirtualizationCluster'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBVirtualizationClusterGroup'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBVirtualizationClusterType'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBVirtualMachine'; Parameters = @{ Id = 1 } }
            @{ Command = 'Set-NBVirtualMachineInterface'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBVirtualizationCluster'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBVirtualizationClusterGroup'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBVirtualizationClusterType'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBVirtualMachine'; Parameters = @{ Id = 1 } }
            @{ Command = 'Remove-NBVirtualMachineInterface'; Parameters = @{ Id = 1 } }
        )

        It 'Should support -WhatIf for <Command>' -TestCases $whatIfTestCases {
            param($Command, $Parameters)
            $splat = $Parameters.Clone()
            $splat.Add('WhatIf', $true)
            $Result = & $Command @splat
            $Result | Should -BeNullOrEmpty
        }
    }
    #endregion

    #region All/PageSize Passthrough Tests
    Context "All/PageSize Passthrough" {
        $allPageSizeTestCases = @(
            @{ Command = 'Get-NBVirtualizationCluster' }
            @{ Command = 'Get-NBVirtualizationClusterGroup' }
            @{ Command = 'Get-NBVirtualizationClusterType' }
            @{ Command = 'Get-NBVirtualMachine' }
            @{ Command = 'Get-NBVirtualMachineInterface' }
        )

        It 'Should pass -All to InvokeNetboxRequest for <Command>' -TestCases $allPageSizeTestCases {
            param($Command, $Parameters)
            $splat = @{ All = $true }
            if ($Parameters) { $splat += $Parameters }
            & $Command @splat
            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -ParameterFilter {
                $All -eq $true
            }
        }

        It 'Should pass -PageSize to InvokeNetboxRequest for <Command>' -TestCases $allPageSizeTestCases {
            param($Command, $Parameters)
            $splat = @{ All = $true; PageSize = 500 }
            if ($Parameters) { $splat += $Parameters }
            & $Command @splat
            Should -Invoke -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -ParameterFilter {
                $PageSize -eq 500
            }
        }
    }
    #endregion

    #region Omit Parameter Tests
    Context "Omit Parameter" {
        $omitTestCases = @(
            @{ Command = 'Get-NBVirtualizationCluster' }
            @{ Command = 'Get-NBVirtualizationClusterGroup' }
            @{ Command = 'Get-NBVirtualizationClusterType' }
            @{ Command = 'Get-NBVirtualMachine' }
            @{ Command = 'Get-NBVirtualMachineInterface' }
        )

        It 'Should pass -Omit to query string for <Command>' -TestCases $omitTestCases {
            param($Command)
            $Result = & $Command -Omit @('comments', 'description')
            $Result.Uri | Should -Match 'omit=comments%2Cdescription'
        }
    }
    #endregion

    #region Pipeline Input Tests
    Context "Pipeline Input" {
        $pipelineTestCases = @(
            @{ Command = 'Get-NBVirtualMachine' }
        )

        It 'Should accept pipeline input by property name for <Command>' -TestCases $pipelineTestCases {
            param($Command)
            $Result = [pscustomobject]@{ 'Id' = 10 } | & $Command
            $Result.Uri | Should -Match '/10/'
        }
    }
    #endregion
}
