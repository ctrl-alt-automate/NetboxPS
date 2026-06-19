<#
.SYNOPSIS
    Creates a new front port on a device in Netbox.

.DESCRIPTION
    Creates a new front port on a specified device in the Netbox DCIM module.
    Front ports represent the front-facing ports on patch panels or other devices
    that connect to rear ports for pass-through cabling.

    NOTE: Netbox 4.5+ uses a new port mapping model. The Rear_Port and Rear_Port_Position
    parameters are deprecated on 4.5+ and will be automatically converted to the new
    Rear_Ports array format.

.PARAMETER Device
    The database ID of the device to add the front port to.

.PARAMETER Name
    The name of the front port (e.g., 'Port 1', 'Front-01').

.PARAMETER Type
    The connector type of the front port. Common types include:
    - Copper: '8p8c' (RJ-45), '8p6c', '8p4c', '110-punch', 'bnc'
    - Fiber: 'lc', 'lc-apc', 'sc', 'sc-apc', 'st', 'mpo', 'mtrj'
    - Coax: 'f', 'n', 'bnc'
    - Other: 'splice', 'other'

.PARAMETER Rear_Ports
    Array of rear port mappings for Netbox 4.5+. Each mapping should be a hashtable
    or PSCustomObject with the following properties:
    - rear_port: (Required) The database ID of the rear port
    - rear_port_position: (Optional) Position on the rear port (1-1024)
    - position: (Optional) Position on the front port (defaults to 1)

.PARAMETER Rear_Port
    DEPRECATED on Netbox 4.5+. Use Rear_Ports instead.
    The database ID of the rear port that this front port maps to.
    On Netbox 4.5+, this will be automatically converted to Rear_Ports format.

.PARAMETER Rear_Port_Position
    DEPRECATED on Netbox 4.5+. Use Rear_Ports instead.
    The position on the rear port (for rear ports with multiple positions).
    Defaults to 1 if not specified.

.PARAMETER Module
    The database ID of the module within the device (for modular devices).

.PARAMETER Label
    A physical label for the port (what's printed on the device).

.PARAMETER Color
    The color of the port in 6-character hex format (e.g., 'ff0000' for red).

.PARAMETER Description
    A description of the front port.

.PARAMETER Mark_Connected
    Whether to mark this port as connected even without a cable object.

.PARAMETER Tags
    Array of tag IDs to assign to this front port.

.PARAMETER Raw
    Return the raw API response object instead of the .results collection.

.EXAMPLE
    New-NBDCIMFrontPort -Device 42 -Name "Port 1" -Type "8p8c" -Rear_Port 100

    Creates a new RJ-45 front port named 'Port 1' on device 42, mapped to rear port 100.
    Works on both Netbox 4.4 and 4.5+ (auto-converts on 4.5+).

.EXAMPLE
    New-NBDCIMFrontPort -Device 42 -Name "Port 1" -Type "8p8c" -Rear_Ports @(
        @{ rear_port = 100; rear_port_position = 1 }
    )

    Creates a front port using the new Netbox 4.5+ port mapping format.

.EXAMPLE
    New-NBDCIMFrontPort -Device 42 -Name "Fiber-01" -Type "lc" -Rear_Ports @(
        @{ rear_port = 100; rear_port_position = 1; position = 1 },
        @{ rear_port = 101; rear_port_position = 1; position = 2 }
    )

    Creates a front port with multiple rear port mappings (fiber pair swapping).

.LINK
    https://netbox.readthedocs.io/en/stable/models/dcim/frontport/
.NOTES
    AddedInVersion: v4.4.7

#>
function New-NBDCIMFrontPort {
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
        [PSObject[]]$Rear_Ports,

        [Parameter()]
        [uint64]$Rear_Port,

        [uint64]$Module,

        [string]$Label,

        [ValidatePattern('^[0-9a-fA-F]{6}$')]
        [string]$Color,

        [ValidateRange(1, 1024)]
        [uint16]$Rear_Port_Position,

        [string]$Description,

        [bool]$Mark_Connected,

        [uint64[]]$Tags,

        [switch]$Raw
    )

    process {

        # Check Netbox version for port mapping format (cached by Connect-NBAPI)
        $netboxVersion = $script:NetboxConfig.ParsedVersion
        $is45OrHigher = $netboxVersion -and ($netboxVersion -ge [version]'4.5.0')


        Write-Verbose "Creating DCIM Front Port"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'front-ports'))

        # Use BuildURIComponents but skip port mapping params (handled separately)
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Rear_Ports', 'Rear_Port', 'Rear_Port_Position', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        # Handle port mappings based on version and provided parameters
        if ($Rear_Ports) {
            # New format explicitly provided
            if (-not $is45OrHigher) {
                Write-Warning "Rear_Ports parameter is only supported on Netbox 4.5+. Current version: $netboxVersion"
            }
            $URIComponents.Parameters['rear_ports'] = $Rear_Ports
        }
        elseif ($PSBoundParameters.ContainsKey('Rear_Port')) {
            # Old format provided
            if ($is45OrHigher) {
                Write-Warning "Rear_Port parameter is deprecated on Netbox 4.5+. Use Rear_Ports instead. Auto-converting to new format."
                # Convert to new format
                $mapping = @{
                    rear_port = $Rear_Port
                    position  = 1
                }
                if ($PSBoundParameters.ContainsKey('Rear_Port_Position')) {
                    $mapping['rear_port_position'] = $Rear_Port_Position
                }
                $URIComponents.Parameters['rear_ports'] = @($mapping)
            }
            else {
                # Netbox 4.4 - use old format
                $URIComponents.Parameters['rear_port'] = $Rear_Port
                if ($PSBoundParameters.ContainsKey('Rear_Port_Position')) {
                    $URIComponents.Parameters['rear_port_position'] = $Rear_Port_Position
                }
            }
        }

        if ($PSCmdlet.ShouldProcess("Device $Device", "Create front port '$Name'")) {
            InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method POST -Raw:$Raw
        }
    }
}
