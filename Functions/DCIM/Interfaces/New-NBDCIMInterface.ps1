<#
.SYNOPSIS
    Creates one or more interfaces on devices in Netbox DCIM module.

.DESCRIPTION
    Creates new network interfaces on specified devices. Supports both single interface
    creation with individual parameters and bulk creation via pipeline input.

    For bulk operations, use the -BatchSize parameter to control how many
    interfaces are sent per API request. This significantly improves performance
    when creating many interfaces.

.PARAMETER Device
    The database ID of the device to add the interface to.

.PARAMETER Name
    The name of the interface (e.g., 'eth0', 'GigabitEthernet0/1').

.PARAMETER Type
    The interface type. Supports physical types (1000base-t, 10gbase-x-sfpp, etc.),
    virtual types (virtual, bridge, lag), and wireless types (ieee802.11ac, etc.).

.PARAMETER Enabled
    Whether the interface is enabled. Defaults to true if not specified.

.PARAMETER MTU
    Maximum Transmission Unit size (typically 1500 for Ethernet).

.PARAMETER MAC_Address
    The MAC address of the interface in format XX:XX:XX:XX:XX:XX. On NetBox
    4.7+ this creates the MAC address record and sets it as the interface's
    primary MAC in a single call (NetBox #18821). To reference an existing
    MAC address record by its database ID use -Primary_MAC_Address instead.
    Requires NetBox 4.7.0 or later; ignored with a warning on older servers.

.PARAMETER MGMT_Only
    If true, this interface is used for management traffic only.

.PARAMETER LAG
    The database ID of the LAG interface this interface belongs to.

.PARAMETER Description
    A description of the interface.

.PARAMETER Mode
    VLAN mode: 'Access' (untagged), 'Tagged' (trunk), or 'Tagged All'.

.PARAMETER Untagged_VLAN
    The database ID of the VLAN object for the untagged/native VLAN.

.PARAMETER Tagged_VLANs
    Array of database IDs of VLAN objects for tagged VLANs.

.PARAMETER Label
    Physical label assigned to the interface.

.PARAMETER Parent
    Numeric ID of the parent interface (for subinterfaces).

.PARAMETER Bridge
    Numeric ID of the bridge this interface belongs to.

.PARAMETER Speed
    Speed of the interface in Kbps (e.g., 1000000 for 1Gbps).

.PARAMETER Duplex
    Duplex mode. One of: 'full', 'half', 'auto'.

.PARAMETER Mark_Connected
    If $true, the interface is marked as connected independent of cable state.

.PARAMETER WWN
    World Wide Name for Fibre Channel interfaces (8 groups of 2 hex digits,
    colon-separated, e.g. 'AA:BB:CC:DD:EE:FF:00:11').

.PARAMETER VDCS
    Array of Virtual Device Context numeric IDs.

.PARAMETER POE_Mode
    Power-over-Ethernet mode. One of: 'pd', 'pse'.

.PARAMETER POE_Type
    Power-over-Ethernet type. One of: 'type1-ieee802.3af', 'type2-ieee802.3at',
    'type3-ieee802.3bt', 'type4-ieee802.3bt', 'passive-24v-2pair',
    'passive-24v-4pair', 'passive-48v-2pair', 'passive-48v-4pair'.

.PARAMETER Vlan_Group
    Numeric ID of the VLAN group this interface belongs to.

.PARAMETER QinQ_SVLAN
    Numeric ID of the Service VLAN for QinQ.

.PARAMETER VRF
    Numeric ID of the VRF this interface belongs to.

.PARAMETER RF_Role
    Wireless RF role. One of: 'ap', 'station'.

.PARAMETER RF_Channel
    Wireless RF channel identifier (e.g. '2.4g-1-2412-22').

.PARAMETER RF_Channel_Frequency
    Wireless RF channel frequency in MHz (1-1000000).

.PARAMETER RF_Channel_Width
    Wireless RF channel width in MHz (1-10000).

.PARAMETER TX_Power
    Wireless transmit power in dBm.

.PARAMETER Primary_MAC_Address
    Numeric ID of the primary MAC address record. Use New-NBDCIMMACAddress to
    create a MAC address record, then pass its id here. See -MAC_Address to
    set the MAC by value instead (NetBox 4.7+).

.PARAMETER Channels
    Number of channels this (breakout) parent interface is channelized into
    (1-1024). Requires NetBox 4.7.0 or later; ignored with a warning on
    older servers.

.PARAMETER Channel_Id
    For a subinterface of type 'channel': the channel number (1-1024) on the
    parent interface that this subinterface is bound to. Set the parent via
    -Parent. Requires NetBox 4.7.0 or later; ignored with a warning on older
    servers.

.PARAMETER Owner
    Numeric ID of the owning user or team.

.PARAMETER Changelog_Message
    Free-form message recorded in the Netbox changelog entry for this operation.

.PARAMETER Tags
    Array of tag objects (e.g. PSCustomObject with slug and color properties).

.PARAMETER InputObject
    Pipeline input for bulk operations. Each object should contain
    the required properties: Device, Name, Type.

.PARAMETER BatchSize
    Number of interfaces to create per API request in bulk mode.
    Default: 50, Range: 1-1000

.PARAMETER Force
    Skip confirmation prompts for bulk operations.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    New-NBDCIMInterface -Device 42 -Name "eth0" -Type "1000base-t"

    Creates a new 1GbE interface named 'eth0' on device ID 42.

.EXAMPLE
    New-NBDCIMInterface -Device 42 -Name "bond0" -Type "lag" -Description "Server uplink LAG"

    Creates a new LAG interface for link aggregation.

.EXAMPLE
    $interfaces = 0..47 | ForEach-Object {
        [PSCustomObject]@{Device=42; Name="eth$_"; Type="1000base-t"}
    }
    $interfaces | New-NBDCIMInterface -BatchSize 50 -Force

    Creates 48 interfaces in bulk using a single API call.

.EXAMPLE
    Import-Csv interfaces.csv | New-NBDCIMInterface -BatchSize 100 -Force

    Bulk import interfaces from CSV file.

.LINK
    https://netbox.readthedocs.io/en/stable/models/dcim/interface/
.NOTES
    AddedInVersion: v1.0.4

#>
function New-NBDCIMInterface {
    [CmdletBinding(SupportsShouldProcess = $true,
        ConfirmImpact = 'Low',
        DefaultParameterSetName = 'Single')]
    [OutputType([PSCustomObject])]
    param(
        # Single mode parameters
        [Parameter(ParameterSetName = 'Single', Mandatory = $true)]
        [uint64]$Device,

        [Parameter(ParameterSetName = 'Single', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('virtual', 'bridge', 'lag', 'channel', '100base-fx', '100base-lfx', '100base-tx', '100base-t1', '1000base-bx10-d', '1000base-bx10-u', '1000base-cwdm', '1000base-cx', '1000base-dwdm', '1000base-ex', '1000base-sx', '1000base-lsx', '1000base-lx', '1000base-lx10', '1000base-t', '1000base-tx', '1000base-zx', '2.5gbase-t', '5gbase-t', '10gbase-br-d', '10gbase-br-u', '10gbase-cu', '10gbase-cx4', '10gbase-er', '10gbase-lr', '10gbase-lrm', '10gbase-lx4', '10gbase-sr', '10gbase-t', '10gbase-zr', '25gbase-cr', '25gbase-er', '25gbase-lr', '25gbase-sr', '25gbase-t', '40gbase-cr4', '40gbase-er4', '40gbase-fr4', '40gbase-lr4', '40gbase-sr4', '40gbase-sr4-bd', '50gbase-cr', '50gbase-er', '50gbase-fr', '50gbase-lr', '50gbase-sr', '100gbase-cr1', '100gbase-cr2', '100gbase-cr4', '100gbase-cr10', '100gbase-cwdm4', '100gbase-dr', '100gbase-fr1', '100gbase-er4', '100gbase-lr1', '100gbase-lr4', '100gbase-sr1', '100gbase-sr1.2', '100gbase-sr2', '100gbase-sr4', '100gbase-sr10', '100gbase-zr', '200gbase-cr2', '200gbase-cr4', '200gbase-sr2', '200gbase-sr4', '200gbase-dr4', '200gbase-fr4', '200gbase-lr4', '200gbase-er4', '200gbase-vr2', '400gbase-cr4', '400gbase-dr4', '400gbase-er8', '400gbase-fr4', '400gbase-fr8', '400gbase-lr4', '400gbase-lr8', '400gbase-sr4', '400gbase-sr4_2', '400gbase-sr8', '400gbase-sr16', '400gbase-vr4', '400gbase-zr', '800gbase-cr8', '800gbase-dr8', '800gbase-sr8', '800gbase-vr8', '1.6tbase-cr8', '1.6tbase-dr8', '1.6tbase-dr8-2', '100base-x-sfp', '1000base-x-gbic', '1000base-x-sfp', '2.5gbase-x-sfp', '10gbase-x-sfpp', '10gbase-x-xfp', '10gbase-x-xenpak', '10gbase-x-x2', '25gbase-x-sfp28', '50gbase-x-sfp56', '40gbase-x-qsfpp', '50gbase-x-sfp28', '100gbase-x-cfp', '100gbase-x-cfp2', '100gbase-x-cfp4', '100gbase-x-cxp', '100gbase-x-cpak', '100gbase-x-dsfp', '100gbase-x-sfpdd', '100gbase-x-sfp112', '100gbase-x-qsfp28', '100gbase-x-qsfpdd', '200gbase-x-cfp2', '200gbase-x-qsfp56', '200gbase-x-qsfpdd', '400gbase-x-cfp2', '400gbase-x-qsfp112', '400gbase-x-qsfpdd', '400gbase-x-osfp', '400gbase-x-osfp-rhs', '400gbase-x-cdfp', '400gbase-x-cfp8', '800gbase-x-qsfpdd', '800gbase-x-osfp', '1.6tbase-x-osfp1600', '1.6tbase-x-osfp1600-rhs', '1.6tbase-x-qsfpdd1600', '1000base-kx', '2.5gbase-kx', '5gbase-kr', '10gbase-kr', '10gbase-kx4', '25gbase-kr', '40gbase-kr4', '50gbase-kr', '100gbase-kp4', '100gbase-kr2', '100gbase-kr4', '1.6tbase-kr8', 'ieee802.11a', 'ieee802.11g', 'ieee802.11n', 'ieee802.11ac', 'ieee802.11ad', 'ieee802.11ax', 'ieee802.11ay', 'ieee802.11be', 'ieee802.15.1', 'ieee802.15.4', 'other-wireless', 'gsm', 'cdma', 'lte', '4g', '5g', 'sonet-oc3', 'sonet-oc12', 'sonet-oc48', 'sonet-oc192', 'sonet-oc768', 'sonet-oc1920', 'sonet-oc3840', '1gfc-sfp', '2gfc-sfp', '4gfc-sfp', '8gfc-sfpp', '16gfc-sfpp', '32gfc-sfp28', '32gfc-sfpp', '64gfc-qsfpp', '64gfc-sfpdd', '64gfc-sfpp', '128gfc-qsfp28', 'infiniband-sdr', 'infiniband-ddr', 'infiniband-qdr', 'infiniband-fdr10', 'infiniband-fdr', 'infiniband-edr', 'infiniband-hdr', 'infiniband-ndr', 'infiniband-xdr', 'infiniband-sdr-4x', 'infiniband-ddr-4x', 'infiniband-qdr-4x', 'infiniband-fdr10-4x', 'infiniband-fdr-4x', 'infiniband-edr-4x', 'infiniband-hdr-4x', 'infiniband-ndr-4x', 'infiniband-xdr-4x', 't1', 'e1', 't3', 'e3', 'xdsl', 'docsis', 'moca', 'bpon', 'epon', '10g-epon', 'gpon', 'xg-pon', 'xgs-pon', 'ng-pon2', '25g-pon', '50g-pon', 'cisco-stackwise', 'cisco-stackwise-plus', 'cisco-flexstack', 'cisco-flexstack-plus', 'cisco-stackwise-80', 'cisco-stackwise-160', 'cisco-stackwise-320', 'cisco-stackwise-480', 'cisco-stackwise-1t', 'juniper-vcp', 'extreme-summitstack', 'extreme-summitstack-128', 'extreme-summitstack-256', 'extreme-summitstack-512', 'hpe-synergy-interconnect-link', 'other', IgnoreCase = $true)]
        [string]$Type,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Label,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Parent,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Bridge,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Speed,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('full', 'half', 'auto', IgnoreCase = $true)]
        [string]$Duplex,

        [Parameter(ParameterSetName = 'Single')]
        [bool]$Mark_Connected,

        [Parameter(ParameterSetName = 'Single')]
        [ValidatePattern('^([0-9a-fA-F]{2}:){7}[0-9a-fA-F]{2}$')]
        [string]$WWN,

        [Parameter(ParameterSetName = 'Single')]
        [uint64[]]$VDCS,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('pd', 'pse', IgnoreCase = $true)]
        [string]$POE_Mode,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('type1-ieee802.3af', 'type2-ieee802.3at', 'type3-ieee802.3bt', 'type4-ieee802.3bt', 'passive-24v-2pair', 'passive-24v-4pair', 'passive-48v-2pair', 'passive-48v-4pair', IgnoreCase = $true)]
        [string]$POE_Type,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Vlan_Group,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$QinQ_SVLAN,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$VRF,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('ap', 'station', IgnoreCase = $true)]
        [string]$RF_Role,

        [Parameter(ParameterSetName = 'Single')]
        [string]$RF_Channel,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateRange(1, 1000000)]
        [int]$RF_Channel_Frequency,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateRange(1, 10000)]
        [int]$RF_Channel_Width,

        [Parameter(ParameterSetName = 'Single')]
        [int]$TX_Power,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Primary_MAC_Address,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateRange(1, 1024)]
        [uint16]$Channels,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateRange(1, 1024)]
        [uint16]$Channel_Id,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Owner,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Changelog_Message,

        [Parameter(ParameterSetName = 'Single')]
        [bool]$Enabled,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateRange(1, 65535)]
        [uint16]$MTU,

        [Parameter(ParameterSetName = 'Single')]
        [ValidatePattern('^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$')]
        [string]$MAC_Address,

        [Parameter(ParameterSetName = 'Single')]
        [bool]$MGMT_Only,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$LAG,

        [Parameter(ParameterSetName = 'Single')]
        [string]$Description,

        [Parameter(ParameterSetName = 'Single')]
        [ValidateSet('Access', 'Tagged', 'Tagged All', 'Q-in-Q', 'q-in-q', '100', '200', '300', '400', IgnoreCase = $true)]
        [string]$Mode,

        [Parameter(ParameterSetName = 'Single')]
        [uint64]$Untagged_VLAN,

        [Parameter(ParameterSetName = 'Single')]
        [uint64[]]$Tagged_VLANs,

        # Bulk mode parameters
        [Parameter(ParameterSetName = 'Bulk', Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]$InputObject,

        [Parameter(ParameterSetName = 'Bulk')]
        [ValidateRange(1, 1000)]
        [int]$BatchSize = 100,

        [Parameter(ParameterSetName = 'Bulk')]
        [switch]$Force,

        # Common parameters
        [Parameter()]

        [object[]]$Tags,

        [switch]$Raw
    )

    begin {
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'interfaces'))
        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ParameterSetName -eq 'Bulk') {
            $bulkItems = [System.Collections.ArrayList]::new()
        }
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Single') {
            # Convert Mode friendly names to API values
            if (-not [System.String]::IsNullOrWhiteSpace($Mode)) {
                $PSBoundParameters.Mode = switch ($Mode) {
                    'Access' { 'access' }
                    '100' { 'access' }
                    'Tagged' { 'tagged' }
                    '200' { 'tagged' }
                    'Tagged All' { 'tagged-all' }
                    '300' { 'tagged-all' }
                    'Q-in-Q' { 'q-in-q' }
                    '400' { 'q-in-q' }
                    default { $_ }
                }
            }

            # NetBox 4.7+ only fields (channelized interfaces, writable MAC):
            # drop them with a warning when connected to an older server.
            $skipParams = @('Raw')
            foreach ($p in @('Channels', 'Channel_Id', 'MAC_Address')) {
                if (Test-NBMinimumVersion -ParameterName $p -MinimumVersion '4.7.0' -BoundParameters $PSBoundParameters -FeatureName "The -$p parameter") {
                    $skipParams += $p
                }
            }

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName $skipParams

            if ($PSCmdlet.ShouldProcess("Device $Device", "Create interface '$Name'")) {
                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method POST -Raw:$Raw
            }
        }
        else {
            # Bulk mode - collect items
            if ($InputObject) {
                $item = @{}
                foreach ($prop in $InputObject.PSObject.Properties) {
                    $key = $prop.Name.ToLower()
                    $value = $prop.Value

                    # Convert Mode friendly names
                    if ($key -eq 'mode' -and $value -is [string]) {
                        $value = switch ($value) {
                            'Access' { 'access' }
                            'Tagged' { 'tagged' }
                            'Tagged All' { 'tagged-all' }
                            default { $value.ToLower() }
                        }
                    }

                    $item[$key] = $value
                }
                [void]$bulkItems.Add([PSCustomObject]$item)
            }
        }
    }

    end {
        if ($PSCmdlet.ParameterSetName -eq 'Bulk' -and $bulkItems.Count -gt 0) {
            $target = "$($bulkItems.Count) interface(s)"

            if ($Force -or $PSCmdlet.ShouldProcess($target, 'Create interfaces (bulk)')) {
                Write-Verbose "Processing $($bulkItems.Count) interfaces in bulk mode with batch size $BatchSize"

                $bulkParams = @{
                    URI          = $URI
                    Items        = $bulkItems.ToArray()
                    Method       = 'POST'
                    BatchSize    = $BatchSize
                    ShowProgress = $true
                    ActivityName = 'Creating interfaces'
                }
                $result = Send-NBBulkRequest @bulkParams

                # Output succeeded items to pipeline
                foreach ($item in $result.Succeeded) {
                    Write-Output $item
                }

                # Write errors for failed items
                foreach ($failure in $result.Failed) {
                    Write-Error "Failed to create interface: $($failure.Error)" -TargetObject $failure.Item
                }

                # Write summary
                if ($result.HasErrors) {
                    Write-Warning $result.GetSummary()
                }
                else {
                    Write-Verbose $result.GetSummary()
                }
            }
        }
    }
}
