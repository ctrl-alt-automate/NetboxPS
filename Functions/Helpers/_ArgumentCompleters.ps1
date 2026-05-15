# Argument Completers for PowerNetbox
# Provides tab completion for common parameter values
# Reference: https://github.com/ctrl-alt-automate/PowerNetbox/issues/115

#region Helper Functions

function Get-NBArgumentCompleter {
    <#
    .SYNOPSIS
        Creates a script block for argument completion with the given values.
.NOTES
    AddedInVersion: v4.4.10.0

    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'ValidValues', Justification = 'Used in closure')]
    [OutputType([scriptblock])]
    param(
        [string[]]$ValidValues
    )

    return {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

        $ValidValues | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new(
                $_,                           # completionText
                $_,                           # listItemText
                'ParameterValue',             # resultType
                $_                            # toolTip
            )
        }
    }.GetNewClosure()
}

#endregion

#region Status Completers

# Device/VM Status values
$script:DeviceStatusValues = @(
    'offline'
    'active'
    'planned'
    'staged'
    'failed'
    'inventory'
    'decommissioning'
)

# Prefix/VLAN/IP Status values
$script:IPAMStatusValues = @(
    'container'
    'active'
    'reserved'
    'deprecated'
)

# Cable Status values
$script:CableStatusValues = @(
    'connected'
    'planned'
    'decommissioning'
)

# Circuit Status values
$script:CircuitStatusValues = @(
    'planned'
    'provisioning'
    'active'
    'offline'
    'deprovisioning'
    'decommissioned'
)

#endregion

#region Device/Rack Completers

# Face values (rack side)
$script:FaceValues = @(
    'front'
    'rear'
)

# Airflow values
$script:AirflowValues = @(
    'front-to-rear'
    'rear-to-front'
    'left-to-right'
    'right-to-left'
    'side-to-rear'
    'rear-to-side'
    'bottom-to-top'
    'top-to-bottom'
    'passive'
    'mixed'
)

# Rack Form Factor values
$script:FormFactorValues = @(
    '2-post-frame'
    '4-post-frame'
    '4-post-cabinet'
    'wall-frame'
    'wall-frame-vertical'
    'wall-cabinet'
    'wall-cabinet-vertical'
)

# Subdevice Role values
$script:SubdeviceRoleValues = @(
    'parent'
    'child'
)

#endregion

#region Interface Completers

# Duplex values
$script:DuplexValues = @(
    'half'
    'full'
    'auto'
)

# PoE Mode values
$script:PoeModeValues = @(
    'pd'
    'pse'
)

# PoE Type values
$script:PoeTypeValues = @(
    'type1-ieee802.3af'
    'type2-ieee802.3at'
    'type3-ieee802.3bt'
    'type4-ieee802.3bt'
    'passive-24v-2pair'
    'passive-24v-4pair'
    'passive-48v-2pair'
    'passive-48v-4pair'
)

# Common Interface Types (subset - full list is very long)
$script:InterfaceTypeValues = @(
    # Virtual
    'virtual'
    'bridge'
    'lag'
    # Ethernet
    '100base-tx'
    '1000base-t'
    '2.5gbase-t'
    '5gbase-t'
    '10gbase-t'
    '10gbase-cx4'
    '25gbase-kr'
    '40gbase-kr4'
    '50gbase-kr'
    '100gbase-kr4'
    # SFP
    '1000base-x-sfp'
    '10gbase-x-sfpp'
    '25gbase-x-sfp28'
    '40gbase-x-qsfpp'
    '50gbase-x-sfp56'
    '100gbase-x-qsfp28'
    '200gbase-x-qsfp56'
    '400gbase-x-qsfpdd'
    '400gbase-x-osfp'
    '800gbase-x-qsfpdd'
    '800gbase-x-osfp'
    '2.5gbase-x-sfp'
    '1.6tbase-x-osfp1600'
    '1.6tbase-x-osfp1600-rhs'
    '1.6tbase-x-qsfpdd1600'
    # 1.6TE Fixed
    '1.6tbase-cr8'
    '1.6tbase-dr8'
    '1.6tbase-dr8-2'
    # 1.6TE Backplane
    '1.6tbase-kr8'
    # Wireless
    'ieee802.11a'
    'ieee802.11g'
    'ieee802.11n'
    'ieee802.11ac'
    'ieee802.11ax'
    'ieee802.11be'
    # Cellular
    'gsm'
    'cdma'
    'lte'
    '5g'
    # Other
    'sonet-oc3'
    'sonet-oc12'
    'sonet-oc48'
    'sonet-oc192'
    'sonet-oc768'
    'sonet-oc1920'
    'sonet-oc3840'
    't1'
    'e1'
    't3'
    'e3'
    'xdsl'
    'docsis'
    'gpon'
    'xg-pon'
    'xgs-pon'
    'ng-pon2'
    'epon'
    '10g-epon'
    'cisco-stackwise'
    'cisco-stackwise-plus'
    'cisco-flexstack'
    'cisco-flexstack-plus'
    'cisco-stackwise-80'
    'cisco-stackwise-160'
    'cisco-stackwise-320'
    'cisco-stackwise-480'
    'cisco-stackwise-1t'
    'juniper-vcp'
    'extreme-summitstack'
    'extreme-summitstack-128'
    'extreme-summitstack-256'
    'extreme-summitstack-512'
    'other'
)

#endregion

#region IPAM Completers

# IP Address Family values
$script:FamilyValues = @(
    '4'
    '6'
)

# IP Address Role values
$script:AddressRoleValues = @(
    'loopback'
    'secondary'
    'anycast'
    'vip'
    'vrrp'
    'hsrp'
    'glbp'
    'carp'
)

# Service Protocol values
$script:ProtocolValues = @(
    'tcp'
    'udp'
    'sctp'
)

# VLAN QinQ Role values
$script:QinqRoleValues = @(
    'svlan'
    'cvlan'
)

#endregion

#region VPN Completers

# Tunnel Encapsulation values
$script:EncapsulationValues = @(
    'ipsec-transport'
    'ipsec-tunnel'
    'ip-ip'
    'gre'
    'wireguard'
    'openvpn'
    'l2tp'
    'pptp'
)

# IKE Authentication Method values
$script:AuthMethodValues = @(
    'preshared-keys'
    'certificates'
    'rsa-signatures'
    'dsa-signatures'
)

# Encryption Algorithm values
$script:EncryptionAlgorithmValues = @(
    'aes-128-cbc'
    'aes-128-gcm'
    'aes-192-cbc'
    'aes-192-gcm'
    'aes-256-cbc'
    'aes-256-gcm'
    '3des-cbc'
    'des-cbc'
)

# Authentication Algorithm values
$script:AuthAlgorithmValues = @(
    'hmac-sha1'
    'hmac-sha256'
    'hmac-sha384'
    'hmac-sha512'
    'hmac-md5'
)

#endregion

#region Wireless Completers

# RF Role values
$script:RfRoleValues = @(
    'ap'
    'station'
)

# WiFi Auth Type values
$script:AuthTypeValues = @(
    'open'
    'wep'
    'wpa-personal'
    'wpa-enterprise'
)

# WiFi Auth Cipher values
$script:AuthCipherValues = @(
    'auto'
    'tkip'
    'aes'
)

#endregion

#region Power Completers

# Power Supply values
$script:SupplyValues = @(
    'ac'
    'dc'
)

# Power Phase values
$script:PhaseValues = @(
    'single-phase'
    'three-phase'
)

# Feed Leg values
$script:FeedLegValues = @(
    'A'
    'B'
    'C'
)

#endregion

#region Cable Completers

# Cable Type values (common subset)
$script:CableTypeValues = @(
    'cat3'
    'cat5'
    'cat5e'
    'cat6'
    'cat6a'
    'cat7'
    'cat7a'
    'cat8'
    'dac-active'
    'dac-passive'
    'mrj21-trunk'
    'coaxial'
    'mmf'
    'mmf-om1'
    'mmf-om2'
    'mmf-om3'
    'mmf-om4'
    'mmf-om5'
    'smf'
    'smf-os1'
    'smf-os2'
    'aoc'
    'power'
    'usb'
)

# Cable Termination Side values
$script:TermSideValues = @(
    'A'
    'Z'
)

#endregion

#region Extras Completers

# Webhook HTTP Method values
$script:HttpMethodValues = @(
    'GET'
    'POST'
    'PUT'
    'PATCH'
    'DELETE'
)

# Event Rule Action Type values
$script:ActionTypeValues = @(
    'webhook'
    'script'
    'notification'
)

#endregion

#region Unit Completers

# Length Unit values
$script:LengthUnitValues = @(
    'km'
    'm'
    'cm'
    'mi'
    'ft'
    'in'
)

# Weight Unit values
$script:WeightUnitValues = @(
    'kg'
    'g'
    'lb'
    'oz'
)

#endregion

#region Register Completers

function Register-NBArgumentCompleters {
    <#
    .SYNOPSIS
        Registers all argument completers for PowerNetbox functions.
    .DESCRIPTION
        Call this function to enable tab completion for common parameter values
        across all PowerNetbox functions.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Registers multiple completers')]
    [CmdletBinding()]
    [OutputType([void])]
    param()

    # Resolve exported function names from THIS module's manifest instead of
    # `Get-Command -Module PowerNetbox`. That call triggers PowerShell's module
    # auto-loader, which side-loads any PowerNetbox copy found on
    # $env:PSModulePath. A fork developer who also has a PSGallery build
    # installed then ends up with two PowerNetbox modules in one session,
    # breaking Pester ("Multiple script or manifest modules named
    # 'PowerNetbox'") — see #418. Reading FunctionsToExport from the manifest
    # is auto-load-free, also works under $PSModuleAutoLoadingPreference='None',
    # and mirrors whatever deploy.ps1 wrote (dev build = all functions,
    # prod build = public only).
    #
    # NOTE on $PSScriptRoot: this source file is never imported on its own.
    # deploy.ps1 concatenates every Functions/**/*.ps1 into the built
    # PowerNetbox.psm1, and the module is always loaded from that psm1 (dev
    # build dir or the PSGallery install dir). In both, PowerNetbox.psm1 and
    # PowerNetbox.psd1 are siblings, so for a function defined in the psm1
    # $PSScriptRoot is the module root and the manifest sits right next to it.
    # (Verified: arg completers register correctly at real import.)
    $manifestPath = Join-Path $PSScriptRoot 'PowerNetbox.psd1'
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        Write-Verbose "PowerNetbox manifest not found at $manifestPath, skipping completer registration"
        return
    }

    $exportedNames = (Import-PowerShellDataFile -LiteralPath $manifestPath).FunctionsToExport
    if (-not $exportedNames) {
        Write-Verbose "PowerNetbox manifest exports no functions, skipping completer registration"
        return
    }

    # Shape into objects with a .Name property so the rest of this function,
    # which filters on $_.Name, is unchanged.
    $moduleCommands = foreach ($exportedName in $exportedNames) {
        [pscustomobject]@{ Name = $exportedName }
    }

    # Status completers - context-specific
    $deviceCommands = $moduleCommands | Where-Object { $_.Name -match 'Device|VM|VirtualMachine' }
    $ipamCommands = $moduleCommands | Where-Object { $_.Name -match 'IPAM|Prefix|Address|VLAN' }
    $cableCommands = $moduleCommands | Where-Object { $_.Name -match 'Cable' }
    $circuitCommands = $moduleCommands | Where-Object { $_.Name -match 'Circuit' }

    # Register Status completers
    foreach ($cmd in $deviceCommands) {
        Register-ArgumentCompleter -CommandName $cmd.Name -ParameterName Status -ScriptBlock (Get-NBArgumentCompleter -ValidValues $script:DeviceStatusValues)
    }
    foreach ($cmd in $ipamCommands) {
        Register-ArgumentCompleter -CommandName $cmd.Name -ParameterName Status -ScriptBlock (Get-NBArgumentCompleter -ValidValues $script:IPAMStatusValues)
    }
    foreach ($cmd in $cableCommands) {
        Register-ArgumentCompleter -CommandName $cmd.Name -ParameterName Status -ScriptBlock (Get-NBArgumentCompleter -ValidValues $script:CableStatusValues)
    }
    foreach ($cmd in $circuitCommands) {
        Register-ArgumentCompleter -CommandName $cmd.Name -ParameterName Status -ScriptBlock (Get-NBArgumentCompleter -ValidValues $script:CircuitStatusValues)
    }

    # Face completer for rack-related commands
    $rackCommands = $moduleCommands | Where-Object { $_.Name -match 'Rack|Device' }
    foreach ($cmd in $rackCommands) {
        Register-ArgumentCompleter -CommandName $cmd.Name -ParameterName Face -ScriptBlock (Get-NBArgumentCompleter -ValidValues $script:FaceValues)
    }

    # Interface-related completers
    $interfaceCommands = $moduleCommands | Where-Object { $_.Name -match 'Interface' }
    foreach ($cmd in $interfaceCommands) {
        Register-ArgumentCompleter -CommandName $cmd.Name -ParameterName Type -ScriptBlock (Get-NBArgumentCompleter -ValidValues $script:InterfaceTypeValues)
        Register-ArgumentCompleter -CommandName $cmd.Name -ParameterName Duplex -ScriptBlock (Get-NBArgumentCompleter -ValidValues $script:DuplexValues)
        Register-ArgumentCompleter -CommandName $cmd.Name -ParameterName Poe_Mode -ScriptBlock (Get-NBArgumentCompleter -ValidValues $script:PoeModeValues)
        Register-ArgumentCompleter -CommandName $cmd.Name -ParameterName Poe_Type -ScriptBlock (Get-NBArgumentCompleter -ValidValues $script:PoeTypeValues)
    }

    # IPAM completers
    foreach ($cmd in $ipamCommands) {
        Register-ArgumentCompleter -CommandName $cmd.Name -ParameterName Family -ScriptBlock (Get-NBArgumentCompleter -ValidValues $script:FamilyValues)
    }

    $addressCommands = $moduleCommands | Where-Object { $_.Name -match 'Address' }
    foreach ($cmd in $addressCommands) {
        Register-ArgumentCompleter -CommandName $cmd.Name -ParameterName Role -ScriptBlock (Get-NBArgumentCompleter -ValidValues $script:AddressRoleValues)
    }

    $serviceCommands = $moduleCommands | Where-Object { $_.Name -match 'Service' }
    foreach ($cmd in $serviceCommands) {
        Register-ArgumentCompleter -CommandName $cmd.Name -ParameterName Protocol -ScriptBlock (Get-NBArgumentCompleter -ValidValues $script:ProtocolValues)
    }

    # VPN completers
    $tunnelCommands = $moduleCommands | Where-Object { $_.Name -match 'Tunnel' }
    foreach ($cmd in $tunnelCommands) {
        Register-ArgumentCompleter -CommandName $cmd.Name -ParameterName Encapsulation -ScriptBlock (Get-NBArgumentCompleter -ValidValues $script:EncapsulationValues)
    }

    $ikeCommands = $moduleCommands | Where-Object { $_.Name -match 'IKE' }
    foreach ($cmd in $ikeCommands) {
        Register-ArgumentCompleter -CommandName $cmd.Name -ParameterName Authentication_Method -ScriptBlock (Get-NBArgumentCompleter -ValidValues $script:AuthMethodValues)
        Register-ArgumentCompleter -CommandName $cmd.Name -ParameterName Encryption_Algorithm -ScriptBlock (Get-NBArgumentCompleter -ValidValues $script:EncryptionAlgorithmValues)
        Register-ArgumentCompleter -CommandName $cmd.Name -ParameterName Authentication_Algorithm -ScriptBlock (Get-NBArgumentCompleter -ValidValues $script:AuthAlgorithmValues)
    }

    # Cable completers
    foreach ($cmd in $cableCommands) {
        Register-ArgumentCompleter -CommandName $cmd.Name -ParameterName Type -ScriptBlock (Get-NBArgumentCompleter -ValidValues $script:CableTypeValues)
    }

    # Wireless completers
    $wirelessCommands = $moduleCommands | Where-Object { $_.Name -match 'Wireless' }
    foreach ($cmd in $wirelessCommands) {
        Register-ArgumentCompleter -CommandName $cmd.Name -ParameterName Rf_Role -ScriptBlock (Get-NBArgumentCompleter -ValidValues $script:RfRoleValues)
        Register-ArgumentCompleter -CommandName $cmd.Name -ParameterName Auth_Type -ScriptBlock (Get-NBArgumentCompleter -ValidValues $script:AuthTypeValues)
        Register-ArgumentCompleter -CommandName $cmd.Name -ParameterName Auth_Cipher -ScriptBlock (Get-NBArgumentCompleter -ValidValues $script:AuthCipherValues)
    }

    # Power completers
    $powerCommands = $moduleCommands | Where-Object { $_.Name -match 'Power' }
    foreach ($cmd in $powerCommands) {
        Register-ArgumentCompleter -CommandName $cmd.Name -ParameterName Supply -ScriptBlock (Get-NBArgumentCompleter -ValidValues $script:SupplyValues)
        Register-ArgumentCompleter -CommandName $cmd.Name -ParameterName Phase -ScriptBlock (Get-NBArgumentCompleter -ValidValues $script:PhaseValues)
    }

    # Webhook completers
    $webhookCommands = $moduleCommands | Where-Object { $_.Name -match 'Webhook' }
    foreach ($cmd in $webhookCommands) {
        Register-ArgumentCompleter -CommandName $cmd.Name -ParameterName Http_Method -ScriptBlock (Get-NBArgumentCompleter -ValidValues $script:HttpMethodValues)
    }

    # Rack completers
    foreach ($cmd in $rackCommands) {
        Register-ArgumentCompleter -CommandName $cmd.Name -ParameterName Airflow -ScriptBlock (Get-NBArgumentCompleter -ValidValues $script:AirflowValues)
        Register-ArgumentCompleter -CommandName $cmd.Name -ParameterName Form_Factor -ScriptBlock (Get-NBArgumentCompleter -ValidValues $script:FormFactorValues)
    }

    Write-Verbose "Registered argument completers for PowerNetbox"
}

#endregion

# Auto-register completers when this file is loaded
Register-NBArgumentCompleters
