[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

BeforeAll {
    Import-Module Pester
    Remove-Module PowerNetbox -Force -ErrorAction SilentlyContinue

    $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox/PowerNetbox.psd1"
    if (-not (Test-Path $ModulePath)) {
        $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "PowerNetbox.psd1"
    }
    Import-Module $ModulePath -ErrorAction Stop
}

Describe "Query options added for Netbox 4.6/4.7 (cursor pagination, TagMatch, optimistic concurrency)" -Tag 'Core', 'Setup' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
        Mock -CommandName 'Get-NBRequestHeaders' -ModuleName 'PowerNetbox' -MockWith { return @{ 'Authorization' = 'Token faketoken'; 'Accept' = 'application/json' } }
        Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }

        $script:stateBefore = InModuleScope -ModuleName 'PowerNetbox' {
            @{
                ParsedVersion         = $script:NetboxConfig.ParsedVersion
                Pagination            = $script:NetboxConfig.Pagination
                TagMatch              = $script:NetboxConfig.TagMatch
                OptimisticConcurrency = $script:NetboxConfig.OptimisticConcurrency
            }
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
            $script:NetboxConfig.Connected = $true
            $script:NetboxConfig.Timeout = 30
            $script:NetboxConfig.ParsedVersion = [version]'4.7.0'
        }
    }
    AfterAll {
        InModuleScope -ModuleName 'PowerNetbox' -Parameters @{ s = $script:stateBefore } {
            $script:NetboxConfig.ParsedVersion = $s.ParsedVersion
            $script:NetboxConfig.Pagination = $s.Pagination
            $script:NetboxConfig.TagMatch = $s.TagMatch
            $script:NetboxConfig.OptimisticConcurrency = $s.OptimisticConcurrency
            $script:NetboxConfig.ETagCache = @{}
        }
    }

    Context "Set-NBQueryOption / Get-NBQueryOption" {
        AfterEach {
            $null = Set-NBQueryOption -Pagination Offset
            $null = Set-NBQueryOption -TagMatch All
            $null = Set-NBQueryOption -OptimisticConcurrency:$false
        }

        It "Should expose the three new options with their defaults" {
            $o = Get-NBQueryOption
            ($o | Where-Object Name -eq 'Pagination').Value | Should -Be 'Offset'
            ($o | Where-Object Name -eq 'TagMatch').Value | Should -Be 'All'
            ($o | Where-Object Name -eq 'OptimisticConcurrency').Value | Should -Be $false
        }

        It "Should set and return Pagination" {
            Set-NBQueryOption -Pagination Cursor | Should -Be 'Cursor'
            (Get-NBQueryOption | Where-Object Name -eq 'Pagination').Value | Should -Be 'Cursor'
        }

        It "Should set and return TagMatch" {
            Set-NBQueryOption -TagMatch Any | Should -Be 'Any'
            (Get-NBQueryOption | Where-Object Name -eq 'TagMatch').Value | Should -Be 'Any'
        }

        It "Should set OptimisticConcurrency and clear the ETag cache when disabled" {
            Set-NBQueryOption -OptimisticConcurrency | Should -Be $true
            InModuleScope -ModuleName 'PowerNetbox' { $script:NetboxConfig.ETagCache['https://x/api/dcim/sites/1/'] = 'W/"1"' }
            Set-NBQueryOption -OptimisticConcurrency:$false | Should -Be $false
            InModuleScope -ModuleName 'PowerNetbox' { $script:NetboxConfig.ETagCache.Count | Should -Be 0 }
        }

        It "Should warn when the connected Netbox is too old for the option" {
            InModuleScope -ModuleName 'PowerNetbox' { $script:NetboxConfig.ParsedVersion = [version]'4.5.10' }
            try {
                $null = Set-NBQueryOption -Pagination Cursor -WarningVariable w1 -WarningAction SilentlyContinue
                $w1 | Should -Match 'requires Netbox 4.6.0'
                $null = Set-NBQueryOption -TagMatch Any -WarningVariable w2 -WarningAction SilentlyContinue
                $w2 | Should -Match 'requires Netbox 4.6.6'
                $null = Set-NBQueryOption -OptimisticConcurrency -WarningVariable w3 -WarningAction SilentlyContinue
                $w3 | Should -Match 'requires Netbox 4.6.0'
            }
            finally {
                InModuleScope -ModuleName 'PowerNetbox' { $script:NetboxConfig.ParsedVersion = [version]'4.7.0' }
            }
        }

        It "Should not allow combining the option parameter sets" {
            { Set-NBQueryOption -Pagination Cursor -TagMatch Any } | Should -Throw
        }
    }

    Context "TagMatch Any rewrites tag / tag_id filters (BuildNewURI)" {
        AfterAll { $null = Set-NBQueryOption -TagMatch All }

        It "Should send plain tag= with the default TagMatch All" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $u = BuildNewURI -Segments 'dcim', 'devices' -Parameters @{ tag = @('edge', 'core') } -SkipConnectedCheck
                $u.Query | Should -Match '(^|[?&])tag=edge'
                $u.Query | Should -Not -Match '__any'
            }
        }

        It "Should send tag__any= / tag_id__any= on Netbox 4.6.6+" {
            $null = Set-NBQueryOption -TagMatch Any
            InModuleScope -ModuleName 'PowerNetbox' {
                $u = BuildNewURI -Segments 'dcim', 'devices' -Parameters @{ tag = @('edge', 'core'); tag_id = 7; name = 'x' } -SkipConnectedCheck
                $u.Query | Should -Match 'tag__any=edge'
                $u.Query | Should -Match 'tag__any=core'
                $u.Query | Should -Match 'tag_id__any=7'
                $u.Query | Should -Match '(^|[?&])name=x'
                $u.Query | Should -Not -Match 'name__any'
            }
        }

        It "Should keep plain tag= below Netbox 4.6.6 (unknown lookups would return everything)" {
            $null = Set-NBQueryOption -TagMatch Any -WarningAction SilentlyContinue
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.ParsedVersion = [version]'4.6.3'
                try {
                    $u = BuildNewURI -Segments 'dcim', 'devices' -Parameters @{ tag = 'edge' } -SkipConnectedCheck
                    $u.Query | Should -Match '(^|[?&])tag=edge'
                    $u.Query | Should -Not -Match '__any'
                }
                finally { $script:NetboxConfig.ParsedVersion = [version]'4.7.0' }
            }
        }
    }

    Context "Cursor pagination (InvokeNetboxRequest -All)" {
        BeforeAll {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                [PSCustomObject]@{ count = $null; next = $null; previous = $null; results = @([PSCustomObject]@{ id = 1 }) }
            }
        }
        AfterAll { $null = Set-NBQueryOption -Pagination Offset }

        It "Should not add start= with the default Offset pagination" {
            $null = Set-NBQueryOption -Pagination Offset
            InModuleScope -ModuleName 'PowerNetbox' {
                $r = InvokeNetboxRequest -URI (BuildNewURI -Segments 'dcim', 'sites' -SkipConnectedCheck) -All -PageSize 50
                @($r).Count | Should -Be 1
            }
            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -Times 1 -Exactly -ParameterFilter { $Uri -match 'limit=50' -and $Uri -notmatch 'start=' }
        }

        It "Should add start=0 on Netbox 4.6+ with Cursor pagination" {
            $null = Set-NBQueryOption -Pagination Cursor
            InModuleScope -ModuleName 'PowerNetbox' {
                $null = InvokeNetboxRequest -URI (BuildNewURI -Segments 'dcim', 'sites' -SkipConnectedCheck) -All -PageSize 50
            }
            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -Times 1 -Exactly -ParameterFilter { $Uri -match 'limit=50&start=0' }
        }

        It "Should leave an explicit offset alone" {
            $null = Set-NBQueryOption -Pagination Cursor
            InModuleScope -ModuleName 'PowerNetbox' {
                $null = InvokeNetboxRequest -URI (BuildNewURI -Segments 'dcim', 'sites' -Parameters @{ offset = 200 } -SkipConnectedCheck) -All
            }
            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -Times 1 -Exactly -ParameterFilter { $Uri -match 'offset=200' -and $Uri -notmatch 'start=' }
        }

        It "Should fall back to offset pagination below Netbox 4.6" {
            $null = Set-NBQueryOption -Pagination Cursor
            InModuleScope -ModuleName 'PowerNetbox' {
                $script:NetboxConfig.ParsedVersion = [version]'4.5.10'
                try {
                    $null = InvokeNetboxRequest -URI (BuildNewURI -Segments 'dcim', 'sites' -SkipConnectedCheck) -All
                }
                finally { $script:NetboxConfig.ParsedVersion = [version]'4.7.0' }
            }
            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -Times 1 -Exactly -ParameterFilter { $Uri -notmatch 'start=' }
        }

        It "Should still refuse a next URL on another origin (SSRF guard) in cursor mode" {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                [PSCustomObject]@{ count = $null; next = 'https://evil.example.com/api/dcim/sites/?start=5'; previous = $null; results = @([PSCustomObject]@{ id = 1 }) }
            }
            $null = Set-NBQueryOption -Pagination Cursor
            InModuleScope -ModuleName 'PowerNetbox' {
                { InvokeNetboxRequest -URI (BuildNewURI -Segments 'dcim', 'sites' -SkipConnectedCheck) -All } | Should -Throw '*different origin*'
            }
        }
    }

    Context "Optimistic concurrency (ETag / If-Match)" -Skip:($PSVersionTable.PSEdition -ne 'Core') {
        BeforeAll {
            Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
                # Emulate -ResponseHeadersVariable: the caller reads it with Get-Variable, so a global works in the mock.
                if ($ResponseHeadersVariable) {
                    Set-Variable -Name $ResponseHeadersVariable -Scope Global -Value @{ 'ETag' = @('W/"2026-09-09T00:00:00+00:00"') }
                }
                [PSCustomObject]@{ id = 42; name = 'site-42' }
            }
            $null = Set-NBQueryOption -OptimisticConcurrency
        }
        AfterAll {
            $null = Set-NBQueryOption -OptimisticConcurrency:$false
            Remove-Variable -Name nbResponseHeaders -Scope Global -ErrorAction SilentlyContinue
        }

        It "Should cache the ETag of a single-object GET and send it as If-Match on the next PATCH" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $uri = BuildNewURI -Segments 'dcim', 'sites', 42 -SkipConnectedCheck
                $null = InvokeNetboxRequest -URI $uri
                $script:NetboxConfig.ETagCache[$uri.Uri.GetLeftPart([System.UriPartial]::Path)] | Should -Be 'W/"2026-09-09T00:00:00+00:00"'
                $null = InvokeNetboxRequest -URI $uri -Method PATCH -Body @{ description = 'x' }
            }
            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -Times 1 -Exactly -ParameterFilter { $Method -eq 'PATCH' -and $Headers['If-Match'] -eq 'W/"2026-09-09T00:00:00+00:00"' }
        }

        It "Should not send If-Match for an object it has not read" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $uri = BuildNewURI -Segments 'dcim', 'sites', 99 -SkipConnectedCheck
                $null = InvokeNetboxRequest -URI $uri -Method PATCH -Body @{ description = 'x' }
            }
            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -Times 1 -Exactly -ParameterFilter { $Method -eq 'PATCH' -and $Uri -match '/99/' -and -not $Headers.ContainsKey('If-Match') }
        }

        It "Should drop the cached ETag after DELETE" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $uri = BuildNewURI -Segments 'dcim', 'sites', 42 -SkipConnectedCheck
                $null = InvokeNetboxRequest -URI $uri
                $null = InvokeNetboxRequest -URI $uri -Method DELETE
                $script:NetboxConfig.ETagCache.ContainsKey($uri.Uri.GetLeftPart([System.UriPartial]::Path)) | Should -Be $false
            }
        }

        It "Should never send If-Match or ask for headers while the option is off" {
            $null = Set-NBQueryOption -OptimisticConcurrency:$false
            try {
                InModuleScope -ModuleName 'PowerNetbox' {
                    $uri = BuildNewURI -Segments 'dcim', 'sites', 42 -SkipConnectedCheck
                    $null = InvokeNetboxRequest -URI $uri
                    $null = InvokeNetboxRequest -URI $uri -Method PATCH -Body @{ description = 'x' }
                }
                Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -Times 1 -Exactly -ParameterFilter { $Method -eq 'PATCH' -and -not $Headers.ContainsKey('If-Match') -and -not $ResponseHeadersVariable }
            }
            finally { $null = Set-NBQueryOption -OptimisticConcurrency }
        }
    }

    Context "HTTP 412 Precondition Failed is explained" {
        It "Should name the status and hint at re-reading the object" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $msg = BuildDetailedErrorMessage -StatusCode 412 -StatusName (GetHttpStatusName -StatusCode 412) -Method 'PATCH' -Endpoint 'PATCH /api/dcim/sites/1/' -ErrorMessage 'precondition failed'
                $msg | Should -Match 'Precondition Failed'
                $msg | Should -Match 'Re-read the object'
            }
        }
    }
}

Describe "Set-NBObjectTag (partial tag assignment, Netbox 4.6+)" -Tag 'Extras' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
        Mock -CommandName 'InvokeNetboxRequest' -ModuleName 'PowerNetbox' -MockWith {
            return [ordered]@{
                'Method' = if ($Method) { $Method } else { 'GET' }
                'Uri'    = $URI.Uri.AbsoluteUri
                'Body'   = if ($Body) { $Body | ConvertTo-Json -Compress -Depth 10 } else { $null }
            }
        }
        $script:pvBefore = InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.ParsedVersion
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
            $script:NetboxConfig.ParsedVersion = [version]'4.7.0'
        }
    }
    AfterAll {
        InModuleScope -ModuleName 'PowerNetbox' -Parameters @{ v = $script:pvBefore } { $script:NetboxConfig.ParsedVersion = $v }
    }

    It "Should PATCH add_tags/remove_tags to the object's own path on the configured host" {
        $obj = [PSCustomObject]@{ id = 42; url = 'http://internal-proxy:8080/api/dcim/devices/42/'; display = 'core-01' }
        $r = $obj | Set-NBObjectTag -Add 'maintenance', 12 -Remove 'staging' -Confirm:$false
        $r.Method | Should -Be 'PATCH'
        $r.Uri | Should -Be 'https://netbox.domain.com/api/dcim/devices/42/'
        $b = $r.Body | ConvertFrom-Json
        $b.add_tags[0].name | Should -Be 'maintenance'
        $b.add_tags[1] | Should -Be 12
        $b.remove_tags[0].name | Should -Be 'staging'
    }

    It "Should accept -Url with a bare API path" {
        $r = Set-NBObjectTag -Url '/api/ipam/prefixes/7/' -Add 'audited' -Confirm:$false
        $r.Uri | Should -Be 'https://netbox.domain.com/api/ipam/prefixes/7/'
        ($r.Body | ConvertFrom-Json).add_tags[0].name | Should -Be 'audited'
    }

    It "Should require -Add or -Remove" {
        { Set-NBObjectTag -Url '/api/ipam/prefixes/7/' -Confirm:$false } | Should -Throw '*-Add*-Remove*'
    }

    It "Should reject objects without a url" {
        { [PSCustomObject]@{ id = 1 } | Set-NBObjectTag -Add 'x' -Confirm:$false } | Should -Throw "*no 'url' property*"
    }

    It "Should refuse below Netbox 4.6 instead of silently no-op-ing" {
        InModuleScope -ModuleName 'PowerNetbox' { $script:NetboxConfig.ParsedVersion = [version]'4.5.10' }
        try {
            { Set-NBObjectTag -Url '/api/ipam/prefixes/7/' -Add 'x' -Confirm:$false } | Should -Throw '*requires Netbox 4.6.0*'
        }
        finally {
            InModuleScope -ModuleName 'PowerNetbox' { $script:NetboxConfig.ParsedVersion = [version]'4.7.0' }
        }
    }
}

Describe "Bulk -Background (Netbox 4.7+)" -Tag 'Bulk' {
    BeforeAll {
        Mock -CommandName 'CheckNetboxIsConnected' -ModuleName 'PowerNetbox' -MockWith { return $true }
        Mock -CommandName 'Get-NBRequestHeaders' -ModuleName 'PowerNetbox' -MockWith { return @{ 'Authorization' = 'Token faketoken' } }
        Mock -CommandName 'Get-NBInvokeParams' -ModuleName 'PowerNetbox' -MockWith { return @{} }
        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -MockWith {
            if ($Uri -match 'background=true') {
                # 202 Accepted: {"job": {...}} instead of the created objects
                return [PSCustomObject]@{ job = [PSCustomObject]@{ id = 501; url = 'https://netbox.domain.com/api/core/jobs/501/'; status = 'pending' } }
            }
            $items = $Body | ConvertFrom-Json
            $id = 100
            return @($items | ForEach-Object { [PSCustomObject]@{ id = $id++; name = $_.name } })
        }
        $script:pvBefore = InModuleScope -ModuleName 'PowerNetbox' {
            $script:NetboxConfig.ParsedVersion
            $script:NetboxConfig.Hostname = 'netbox.domain.com'
            $script:NetboxConfig.HostScheme = 'https'
            $script:NetboxConfig.HostPort = 443
            $script:NetboxConfig.Timeout = 30
            $script:NetboxConfig.ParsedVersion = [version]'4.7.0'
        }
    }
    AfterAll {
        InModuleScope -ModuleName 'PowerNetbox' -Parameters @{ v = $script:pvBefore } { $script:NetboxConfig.ParsedVersion = $v }
    }

    It "Send-NBBulkRequest -Background should append ?background=true and return the job" {
        InModuleScope -ModuleName 'PowerNetbox' {
            $uri = BuildNewURI -Segments 'dcim', 'sites' -SkipConnectedCheck
            $r = Send-NBBulkRequest -URI $uri -Items @(@{ name = 'a'; slug = 'a' }, @{ name = 'b'; slug = 'b' }) -Method POST -Background
            $r.Succeeded.Count | Should -Be 1
            $r.Succeeded[0].id | Should -Be 501
        }
        Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -Times 1 -Exactly -ParameterFilter { $Uri -match '/api/dcim/sites/\?background=true$' }
    }

    It "Send-NBBulkRequest without -Background should be unchanged" {
        InModuleScope -ModuleName 'PowerNetbox' {
            $uri = BuildNewURI -Segments 'dcim', 'sites' -SkipConnectedCheck
            $r = Send-NBBulkRequest -URI $uri -Items @(@{ name = 'a'; slug = 'a' }) -Method POST
            $r.Succeeded[0].id | Should -Be 100
        }
        Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -Times 1 -Exactly -ParameterFilter { $Uri -notmatch 'background' }
    }

    It "New-NBDCIMDevice -Background should queue the batch on Netbox 4.7" {
        $r = @([PSCustomObject]@{ Name = 'd1'; Role = 1; Device_Type = 1; Site = 1 }) | New-NBDCIMDevice -BatchSize 10 -Background -Force
        Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -Times 1 -Exactly -ParameterFilter { $Uri -match 'background=true' }
    }

    It "New-NBDCIMDevice -Background should warn and run synchronously below Netbox 4.7" {
        InModuleScope -ModuleName 'PowerNetbox' { $script:NetboxConfig.ParsedVersion = [version]'4.6.10' }
        try {
            $r = @([PSCustomObject]@{ Name = 'd1'; Role = 1; Device_Type = 1; Site = 1 }) | New-NBDCIMDevice -BatchSize 10 -Background -Force -WarningVariable w -WarningAction SilentlyContinue
            $w | Should -Match 'requires Netbox 4.7.0'
            Should -Invoke -CommandName 'Invoke-RestMethod' -ModuleName 'PowerNetbox' -Times 1 -Exactly -ParameterFilter { $Uri -notmatch 'background' }
        }
        finally {
            InModuleScope -ModuleName 'PowerNetbox' { $script:NetboxConfig.ParsedVersion = [version]'4.7.0' }
        }
    }
}
