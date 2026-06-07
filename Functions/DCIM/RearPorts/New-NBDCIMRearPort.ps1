<#
.SYNOPSIS
    Creates a new rear port on a device in Netbox.

.DESCRIPTION
    Creates a new rear port on a specified device in the Netbox DCIM module.
    Rear ports represent the back-facing ports on patch panels or other devices
    that connect to front ports for pass-through cabling.

    NOTE: Netbox 4.5+ introduces bidirectional port mappings. You can now specify
    front port mappings directly when creating a rear port using the Front_Ports parameter.

.PARAMETER Device
    The database ID of the device to add the rear port to.

.PARAMETER Name
    The name of the rear port (e.g., 'Rear 1', 'Back-01').

.PARAMETER Type
    The connector type of the rear port. Common types include:
    - Copper: '8p8c' (RJ-45), '8p6c', '8p4c', '110-punch', 'bnc'
    - Fiber: 'lc', 'lc-apc', 'sc', 'sc-apc', 'st', 'mpo', 'mtrj'
    - Coax: 'f', 'n', 'bnc'
    - Other: 'splice', 'other'

.PARAMETER Front_Ports
    Array of front port mappings for Netbox 4.5+ (bidirectional mapping).
    Each mapping should be a hashtable or PSCustomObject with:
    - front_port: (Required) The database ID of the front port
    - front_port_position: (Required) Position on the front port (1-1024)
    - position: (Required) Position on the rear port (1-1024)

.PARAMETER Module
    The database ID of the module within the device (for modular devices).

.PARAMETER Label
    A physical label for the port (what's printed on the device).

.PARAMETER Color
    The color of the port in 6-character hex format (e.g., 'ff0000' for red).

.PARAMETER Positions
    The number of front port positions this rear port supports.
    Defaults to 1. Use higher values for multi-position rear ports.

.PARAMETER Description
    A description of the rear port.

.PARAMETER Mark_Connected
    Whether to mark this port as connected even without a cable object.

.PARAMETER Tags
    Array of tag IDs to assign to this rear port.

.PARAMETER Raw
    Return the raw API response object instead of the .results collection.

.EXAMPLE
    New-NBDCIMRearPort -Device 42 -Name "Rear 1" -Type "8p8c"

    Creates a new RJ-45 rear port named 'Rear 1' on device 42.

.EXAMPLE
    New-NBDCIMRearPort -Device 42 -Name "Fiber-Rear-01" -Type "lc" -Positions 2

    Creates a new LC fiber rear port that supports 2 front port positions.

.EXAMPLE
    New-NBDCIMRearPort -Device 42 -Name "Rear 1" -Type "8p8c" -Front_Ports @(
        @{ front_port = 100; front_port_position = 1; position = 1 }
    )

    Creates a rear port with bidirectional front port mapping (Netbox 4.5+).

.EXAMPLE
    1..24 | ForEach-Object {
        New-NBDCIMRearPort -Device 42 -Name "Rear $_" -Type "8p8c"
    }

    Creates 24 rear ports on a patch panel.

.LINK
    https://netbox.readthedocs.io/en/stable/models/dcim/rearport/
.NOTES
    AddedInVersion: v4.4.7

#>
function New-NBDCIMRearPort {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [uint64]$Device,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('8p8c', '8p6c', '8p4c', '8p2c', '6p6c', '6p4c', '6p2c', '4p4c', '4p2c',
            'gg45', 'tera-4p', 'tera-2p', 'tera-1p', '110-punch', 'bnc', 'f', 'n', 'mrj21',
            'fc', 'fc-pc', 'fc-upc', 'fc-apc',
            'lc', 'lc-pc', 'lc-upc', 'lc-apc', 'lsh', 'lsh-pc', 'lsh-upc', 'lsh-apc',
            'lx5', 'lx5-pc', 'lx5-upc', 'lx5-apc', 'mpo', 'mtrj', 'sc', 'sc-pc', 'sc-upc',
            'sc-apc', 'st', 'cs', 'sn', 'sma-905', 'sma-906', 'urm-p2', 'urm-p4', 'urm-p8',
            'usb-a', 'usb-b', 'usb-c', 'usb-mini-a', 'usb-mini-b',
            'usb-micro-a', 'usb-micro-b', 'usb-micro-ab',
            'splice', 'other', IgnoreCase = $true)]
        [string]$Type,

        [Parameter()]
        [PSObject[]]$Front_Ports,

        [uint64]$Module,

        [string]$Label,

        [ValidatePattern('^[0-9a-fA-F]{6}$')]
        [string]$Color,

        [ValidateRange(1, 1024)]
        [uint16]$Positions = 1,

        [string]$Description,

        [bool]$Mark_Connected,

        [uint64[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating DCIM Rear Port"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'rear-ports'))

        # Use BuildURIComponents but skip Front_Ports (handled separately)
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Front_Ports', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        # Handle Front_Ports for Netbox 4.5+ bidirectional mapping
        if ($Front_Ports) {
            # Check Netbox version (cached by Connect-NBAPI)
            $netboxVersion = $script:NetboxConfig.ParsedVersion
            $is45OrHigher = $netboxVersion -and ($netboxVersion -ge [version]'4.5.0')

            if (-not $is45OrHigher) {
                Write-Warning "Front_Ports parameter is only supported on Netbox 4.5+. This parameter will be ignored on older versions."
            }
            else {
                $URIComponents.Parameters['front_ports'] = $Front_Ports
            }
        }

        if ($PSCmdlet.ShouldProcess("Device $Device", "Create rear port '$Name'")) {
            InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method POST -Raw:$Raw
        }
    }
}
