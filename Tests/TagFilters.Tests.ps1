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

Describe "Tag filters and tag references" -Tag 'Core', 'Tags' {
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
        # Every Get-NB* cmdlet that exposes -Tag must also expose -Tag_Id and route both to the query string
        $script:TagGetCmdlets = Get-Command -Module PowerNetbox -Verb Get | Where-Object { $_.Parameters.ContainsKey('Tag') }
    }
    AfterAll {
        InModuleScope -ModuleName 'PowerNetbox' -Parameters @{ v = $script:pvBefore } { $script:NetboxConfig.ParsedVersion = $v }
        $null = Set-NBQueryOption -TagMatch All
    }

    Context "-Tag / -Tag_Id on Get cmdlets" {
        It "Should exist on (at least) 90 Get cmdlets, always as a pair" {
            $script:TagGetCmdlets.Count | Should -BeGreaterOrEqual 90
            foreach ($c in $script:TagGetCmdlets) {
                $c.Parameters.ContainsKey('Tag_Id') | Should -Be $true -Because "$($c.Name) has -Tag"
                $c.Parameters['Tag'].ParameterType.FullName | Should -Be 'System.String[]' -Because "$($c.Name) -Tag"
                $c.Parameters['Tag_Id'].ParameterType.FullName | Should -Be 'System.UInt64[]' -Because "$($c.Name) -Tag_Id"
            }
        }

        It "Should emit repeat-key tag= and tag_id= filters on every cmdlet that has them" {
            foreach ($c in $script:TagGetCmdlets) {
                $r = & $c.Name -Tag 'edge', 'core' -Tag_Id 7, 8
                $r.Method | Should -Be 'GET' -Because $c.Name
                $r.Uri | Should -Match 'tag=edge' -Because $c.Name
                $r.Uri | Should -Match 'tag=core' -Because $c.Name
                $r.Uri | Should -Match 'tag_id=7' -Because $c.Name
                $r.Uri | Should -Match 'tag_id=8' -Because $c.Name
            }
        }

        It "Should switch to tag__any= with Set-NBQueryOption -TagMatch Any" {
            $null = Set-NBQueryOption -TagMatch Any
            try {
                $r = Get-NBDCIMDevice -Tag 'edge', 'core' -Tag_Id 7
                $r.Uri | Should -Match 'tag__any=edge'
                $r.Uri | Should -Match 'tag__any=core'
                $r.Uri | Should -Match 'tag_id__any=7'
            }
            finally { $null = Set-NBQueryOption -TagMatch All }
        }
    }

    Context "Tag references in request bodies (names become attribute dictionaries)" {
        It "ConvertToNBTagReference should map names, numeric strings, numbers and dictionaries" {
            InModuleScope -ModuleName 'PowerNetbox' {
                $refs = ConvertToNBTagReference -Tags 'web', '12', 13, @{ slug = 'prod' }, ([PSCustomObject]@{ name = 'x' })
                $refs.Count | Should -Be 5
                $refs[0].name | Should -Be 'web'
                $refs[1] | Should -Be 12
                $refs[1] | Should -BeOfType [uint64]
                $refs[2] | Should -Be 13
                $refs[3].slug | Should -Be 'prod'
                $refs[4].name | Should -Be 'x'
                (ConvertToNBTagReference -Tags $null).Count | Should -Be 0
            }
        }

        It "New-NBDCIMSite -Tags 'web', 12 should send [{name:web}, 12] (BuildURIComponents path)" {
            $r = New-NBDCIMSite -Name 's' -Slug 's' -Tags 'web', 12 -Confirm:$false
            $b = $r.Body | ConvertFrom-Json
            $b.tags[0].name | Should -Be 'web'
            $b.tags[1] | Should -Be 12
        }

        It "Set-NBDCIMDevice -Tags should send tag references too" {
            $r = Set-NBDCIMDevice -Id 1 -Tags 'edge' -Confirm:$false
            ($r.Body | ConvertFrom-Json).tags[0].name | Should -Be 'edge'
        }

        It "New-NBIPAMService (manual body) should send tag references" {
            $r = New-NBIPAMService -Name 'HTTP' -Ports 80 -Device 1 -Tags 'web', 3
            $b = $r.Body | ConvertFrom-Json
            $b.tags[0].name | Should -Be 'web'
            $b.tags[1] | Should -Be 3
        }

        It "New-NBDCIMCable (manual body) should send tag references" {
            $aTerm = @(@{ object_type = 'dcim.interface'; object_id = 1 })
            $bTerm = @(@{ object_type = 'dcim.interface'; object_id = 2 })
            $r = New-NBDCIMCable -A_Terminations $aTerm -B_Terminations $bTerm -Tags 'fiber' -Confirm:$false
            ($r.Body | ConvertFrom-Json).tags[0].name | Should -Be 'fiber'
        }
    }
}
