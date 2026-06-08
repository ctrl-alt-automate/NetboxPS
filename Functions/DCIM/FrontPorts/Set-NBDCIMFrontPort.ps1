<#
.SYNOPSIS
    Updates an existing front port in Netbox DCIM module.

.DESCRIPTION
    Updates an existing front port in Netbox DCIM module.
    Supports pipeline input for Id parameter.

    NOTE: Netbox 4.5+ uses a new port mapping model. The Rear_Port and Rear_Port_Position
    parameters are deprecated on 4.5+ and will be automatically converted to the new
    Rear_Ports array format.

.PARAMETER Id
    The database ID of the front port to update.

.PARAMETER Device
    The database ID of the device.

.PARAMETER Module
    The database ID of the module within the device.

.PARAMETER Name
    The name of the front port.

.PARAMETER Label
    A physical label for the port.

.PARAMETER Type
    The connector type of the front port.

.PARAMETER Color
    The color of the port in 6-character hex format.

.PARAMETER Rear_Ports
    Array of rear port mappings for Netbox 4.5+. Each mapping should be a hashtable
    or PSCustomObject with the following properties:
    - rear_port: (Required) The database ID of the rear port
    - rear_port_position: (Optional) Position on the rear port (1-1024)
    - position: (Optional) Position on the front port

.PARAMETER Rear_Port
    DEPRECATED on Netbox 4.5+. Use Rear_Ports instead.
    The database ID of the rear port that this front port maps to.

.PARAMETER Rear_Port_Position
    DEPRECATED on Netbox 4.5+. Use Rear_Ports instead.
    The position on the rear port.

.PARAMETER Description
    A description of the front port.

.PARAMETER Mark_Connected
    Whether to mark this port as connected.

.PARAMETER Tags
    Array of tag IDs to assign to this front port.

.PARAMETER Force
    Skip confirmation prompt.

.PARAMETER Raw
    Return the raw API response object instead of the .results collection.

.EXAMPLE
    Set-NBDCIMFrontPort -Id 1 -Name "Port 1 Updated"

    Updates the name of front port with ID 1.

.EXAMPLE
    Set-NBDCIMFrontPort -Id 1 -Rear_Ports @(
        @{ rear_port = 100; rear_port_position = 2; position = 1 }
    )

    Updates the rear port mappings using Netbox 4.5+ format.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.7

#>
function Set-NBDCIMFrontPort {
    [CmdletBinding(ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [uint16]$Device,

        [uint16]$Module,

        [string]$Name,

        [string]$Label,

        [string]$Type,

        [ValidatePattern('^[0-9a-f]{6}$')]
        [string]$Color,

        [Parameter()]
        [PSObject[]]$Rear_Ports,

        [uint64]$Rear_Port,

        [uint16]$Rear_Port_Position,

        [string]$Description,

        [bool]$Mark_Connected,

        [uint64[]]$Tags,

        [switch]$Force,

        [switch]$Raw
    )

    begin {
        # Check Netbox version for port mapping format (cached by Connect-NBAPI)
        $netboxVersion = $script:NetboxConfig.ParsedVersion
        $is45OrHigher = $netboxVersion -and ($netboxVersion -ge [version]'4.5.0')
    }

    process {
        Write-Verbose "Updating DCIM Front Port"

        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'front-ports', $Id))

        # Use BuildURIComponents but skip port mapping params (handled separately)
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'Force', 'Rear_Ports', 'Rear_Port', 'Rear_Port_Position'

        $URI = BuildNewURI -Segments $Segments

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

        if ($Force -or $PSCmdlet.ShouldProcess("Front Port ID $Id", "Set")) {
            InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method PATCH -Raw:$Raw
        }
    }

}
