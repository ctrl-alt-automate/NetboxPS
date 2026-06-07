<#
.SYNOPSIS
    Updates an existing DCIM Interface in Netbox DCIM module.

.DESCRIPTION
    Updates an existing DCIM Interface in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Id
    The database ID of the interface to update.

.PARAMETER Device
    The database ID of the device this interface belongs to.

.PARAMETER Name
    The name of the interface (e.g., 'eth0', 'GigabitEthernet0/1').

.PARAMETER Enabled
    Whether the interface is enabled.

.PARAMETER Type
    The interface type. Supports physical types (1000base-t, 10gbase-x-sfpp, etc.),
    virtual types (virtual, bridge, lag), and wireless types (ieee802.11ac, etc.).

.PARAMETER MTU
    Maximum Transmission Unit size (typically 1500 for Ethernet).

.PARAMETER MAC_Address
    The MAC address of the interface in format XX:XX:XX:XX:XX:XX.

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
    Numeric ID of the parent interface (for subinterfaces). Pass $null to clear.

.PARAMETER Bridge
    Numeric ID of the bridge this interface belongs to. Pass $null to clear.

.PARAMETER Speed
    Speed of the interface in Kbps (e.g., 1000000 for 1Gbps). Pass $null to clear.

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
    Numeric ID of the Service VLAN for QinQ. Pass $null to clear.

.PARAMETER VRF
    Numeric ID of the VRF this interface belongs to.

.PARAMETER RF_Role
    Wireless RF role. One of: 'ap', 'station'.

.PARAMETER RF_Channel
    Wireless RF channel identifier (e.g. '2.4g-1-2412-22').

.PARAMETER RF_Channel_Frequency
    Wireless RF channel frequency in MHz (1-1000000). Pass $null to clear.

.PARAMETER RF_Channel_Width
    Wireless RF channel width in MHz (1-10000). Pass $null to clear.

.PARAMETER TX_Power
    Wireless transmit power in dBm. Pass $null to clear.

.PARAMETER Primary_MAC_Address
    Numeric ID of the primary MAC address record. Pass $null to clear.

.PARAMETER Owner
    Numeric ID of the owning user or team. Pass $null to clear.

.PARAMETER Changelog_Message
    Free-form message recorded in the Netbox changelog entry for this operation.

.PARAMETER Tags
    Array of tag objects (e.g. PSCustomObject with slug and color properties).

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Force
    Skip the confirmation prompt.

.EXAMPLE
    Set-NBDCIMInterface -Id 42 -Name "eth0-renamed"

    Renames an existing interface.

.EXAMPLE
    Set-NBDCIMInterface -Id 42 -Parent $null

    Clears the parent interface association (sets parent to null via PATCH).

.LINK
    https://netbox.readthedocs.io/en/stable/models/dcim/interface/
.NOTES
    AddedInVersion: v1.0.4

#>
function Set-NBDCIMInterface {
    [CmdletBinding(ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [uint64]$Device,

        [string]$Name,

        [bool]$Enabled,

        [ValidateSet('virtual', 'bridge', 'lag', '100base-fx', '100base-lfx', '100base-tx', '100base-t1', '1000base-bx10-d', '1000base-bx10-u', '1000base-cwdm', '1000base-cx', '1000base-dwdm', '1000base-ex', '1000base-sx', '1000base-lsx', '1000base-lx', '1000base-lx10', '1000base-t', '1000base-tx', '1000base-zx', '2.5gbase-t', '5gbase-t', '10gbase-br-d', '10gbase-br-u', '10gbase-cu', '10gbase-cx4', '10gbase-er', '10gbase-lr', '10gbase-lrm', '10gbase-lx4', '10gbase-sr', '10gbase-t', '10gbase-zr', '25gbase-cr', '25gbase-er', '25gbase-lr', '25gbase-sr', '25gbase-t', '40gbase-cr4', '40gbase-er4', '40gbase-fr4', '40gbase-lr4', '40gbase-sr4', '40gbase-sr4-bd', '50gbase-cr', '50gbase-er', '50gbase-fr', '50gbase-lr', '50gbase-sr', '100gbase-cr1', '100gbase-cr2', '100gbase-cr4', '100gbase-cr10', '100gbase-cwdm4', '100gbase-dr', '100gbase-fr1', '100gbase-er4', '100gbase-lr1', '100gbase-lr4', '100gbase-sr1', '100gbase-sr1.2', '100gbase-sr2', '100gbase-sr4', '100gbase-sr10', '100gbase-zr', '200gbase-cr2', '200gbase-cr4', '200gbase-sr2', '200gbase-sr4', '200gbase-dr4', '200gbase-fr4', '200gbase-lr4', '200gbase-er4', '200gbase-vr2', '400gbase-cr4', '400gbase-dr4', '400gbase-er8', '400gbase-fr4', '400gbase-fr8', '400gbase-lr4', '400gbase-lr8', '400gbase-sr4', '400gbase-sr4_2', '400gbase-sr8', '400gbase-sr16', '400gbase-vr4', '400gbase-zr', '800gbase-cr8', '800gbase-dr8', '800gbase-sr8', '800gbase-vr8', '1.6tbase-cr8', '1.6tbase-dr8', '1.6tbase-dr8-2', '100base-x-sfp', '1000base-x-gbic', '1000base-x-sfp', '2.5gbase-x-sfp', '10gbase-x-sfpp', '10gbase-x-xfp', '10gbase-x-xenpak', '10gbase-x-x2', '25gbase-x-sfp28', '50gbase-x-sfp56', '40gbase-x-qsfpp', '50gbase-x-sfp28', '100gbase-x-cfp', '100gbase-x-cfp2', '100gbase-x-cfp4', '100gbase-x-cxp', '100gbase-x-cpak', '100gbase-x-dsfp', '100gbase-x-sfpdd', '100gbase-x-qsfp28', '100gbase-x-qsfpdd', '200gbase-x-cfp2', '200gbase-x-qsfp56', '200gbase-x-qsfpdd', '400gbase-x-cfp2', '400gbase-x-qsfp112', '400gbase-x-qsfpdd', '400gbase-x-osfp', '400gbase-x-osfp-rhs', '400gbase-x-cdfp', '400gbase-x-cfp8', '800gbase-x-qsfpdd', '800gbase-x-osfp', '1.6tbase-x-osfp1600', '1.6tbase-x-osfp1600-rhs', '1.6tbase-x-qsfpdd1600', '1000base-kx', '2.5gbase-kx', '5gbase-kr', '10gbase-kr', '10gbase-kx4', '25gbase-kr', '40gbase-kr4', '50gbase-kr', '100gbase-kp4', '100gbase-kr2', '100gbase-kr4', '1.6tbase-kr8', 'ieee802.11a', 'ieee802.11g', 'ieee802.11n', 'ieee802.11ac', 'ieee802.11ad', 'ieee802.11ax', 'ieee802.11ay', 'ieee802.11be', 'ieee802.15.1', 'ieee802.15.4', 'other-wireless', 'gsm', 'cdma', 'lte', '4g', '5g', 'sonet-oc3', 'sonet-oc12', 'sonet-oc48', 'sonet-oc192', 'sonet-oc768', 'sonet-oc1920', 'sonet-oc3840', '1gfc-sfp', '2gfc-sfp', '4gfc-sfp', '8gfc-sfpp', '16gfc-sfpp', '32gfc-sfp28', '32gfc-sfpp', '64gfc-qsfpp', '64gfc-sfpdd', '64gfc-sfpp', '128gfc-qsfp28', 'infiniband-sdr', 'infiniband-ddr', 'infiniband-qdr', 'infiniband-fdr10', 'infiniband-fdr', 'infiniband-edr', 'infiniband-hdr', 'infiniband-ndr', 'infiniband-xdr', 't1', 'e1', 't3', 'e3', 'xdsl', 'docsis', 'moca', 'bpon', 'epon', '10g-epon', 'gpon', 'xg-pon', 'xgs-pon', 'ng-pon2', '25g-pon', '50g-pon', 'cisco-stackwise', 'cisco-stackwise-plus', 'cisco-flexstack', 'cisco-flexstack-plus', 'cisco-stackwise-80', 'cisco-stackwise-160', 'cisco-stackwise-320', 'cisco-stackwise-480', 'cisco-stackwise-1t', 'juniper-vcp', 'extreme-summitstack', 'extreme-summitstack-128', 'extreme-summitstack-256', 'extreme-summitstack-512', 'other', IgnoreCase = $true)]
        [string]$Type,

        [string]$Label,

        [Nullable[uint64]]$Parent,

        [Nullable[uint64]]$Bridge,

        [Nullable[uint64]]$Speed,

        [AllowEmptyString()]
        [ValidateSet('full', 'half', 'auto', '', IgnoreCase = $true)]
        [string]$Duplex,

        [bool]$Mark_Connected,

        [ValidatePattern('^([0-9a-fA-F]{2}:){7}[0-9a-fA-F]{2}$')]
        [string]$WWN,

        [uint64[]]$VDCS,

        [AllowEmptyString()]
        [ValidateSet('pd', 'pse', '', IgnoreCase = $true)]
        [string]$POE_Mode,

        [AllowEmptyString()]
        [ValidateSet('type1-ieee802.3af', 'type2-ieee802.3at', 'type3-ieee802.3bt', 'type4-ieee802.3bt', 'passive-24v-2pair', 'passive-24v-4pair', 'passive-48v-2pair', 'passive-48v-4pair', '', IgnoreCase = $true)]
        [string]$POE_Type,

        [uint64]$Vlan_Group,

        [Nullable[uint64]]$QinQ_SVLAN,

        [uint64]$VRF,

        [AllowEmptyString()]
        [ValidateSet('ap', 'station', '', IgnoreCase = $true)]
        [string]$RF_Role,

        [string]$RF_Channel,

        [Nullable[int]]$RF_Channel_Frequency,

        [Nullable[int]]$RF_Channel_Width,

        [Nullable[int]]$TX_Power,

        [Nullable[uint64]]$Primary_MAC_Address,

        [Nullable[uint64]]$Owner,

        [string]$Changelog_Message,

        [uint16]$MTU,

        [string]$MAC_Address,

        [bool]$MGMT_Only,

        [uint64]$LAG,

        [string]$Description,

        [AllowEmptyString()]
        [ValidateSet('Access', 'Tagged', 'Tagged All', 'Q-in-Q', 'q-in-q', '100', '200', '300', '400', '', IgnoreCase = $true)]
        [string]$Mode,

        [uint64]$Untagged_VLAN,

        [uint64[]]$Tagged_VLANs,

        [switch]$Force,


        [object[]]$Tags,

        [switch]$Raw
    )

    begin {
        if (-not [System.String]::IsNullOrWhiteSpace($Mode)) {
            $PSBoundParameters.Mode = switch ($Mode) {
                'Access' {
                    'access'
                    break
                }

                '100' {
                    'access'
                    break
                }

                'Tagged' {
                    'tagged'
                    break
                }

                '200' {
                    'tagged'
                    break
                }

                'Tagged All' {
                    'tagged-all'
                    break
                }

                '300' {
                    'tagged-all'
                    break
                }

                'Q-in-Q' {
                    'q-in-q'
                    break
                }

                '400' {
                    'q-in-q'
                    break
                }

                default {
                    $_
                }
            }
        }
    }

    process {
        Write-Verbose "Updating DCIM Interface"

        # Translate empty-string sentinel to $null for the 5 clearable enum parameters.
        # Users pass '' to clear a field server-side; BuildURIComponents +
        # ConvertTo-Json emit "field": null on the wire, which NetBox PATCH accepts.
        $clearableEnums = @('Duplex', 'POE_Mode', 'POE_Type', 'RF_Role', 'Mode')
        foreach ($clearable in $clearableEnums) {
            if ($PSBoundParameters.ContainsKey($clearable) -and $PSBoundParameters[$clearable] -eq '') {
                $PSBoundParameters[$clearable] = $null
            }
        }

        foreach ($InterfaceId in $Id) {

            $Segments = [System.Collections.ArrayList]::new(@('dcim', 'interfaces', $InterfaceId))

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

            $URI = BuildNewURI -Segments $Segments

            if ($Force -or $PSCmdlet.ShouldProcess("Interface ID $InterfaceId", "Set")) {
                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method PATCH -Raw:$Raw
            }
        }
    }

}
