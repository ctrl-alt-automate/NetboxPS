<#
.SYNOPSIS
    Updates an existing rear port in Netbox DCIM module.

.DESCRIPTION
    Updates an existing rear port in Netbox DCIM module.
    Supports pipeline input for Id parameter.

    NOTE: Netbox 4.5+ introduces bidirectional port mappings. You can now specify
    front port mappings directly when updating a rear port using the Front_Ports parameter.

.PARAMETER Id
    The database ID of the rear port to update.

.PARAMETER Device
    The database ID of the device.

.PARAMETER Module
    The database ID of the module within the device.

.PARAMETER Name
    The name of the rear port.

.PARAMETER Label
    A physical label for the port.

.PARAMETER Type
    The connector type of the rear port.

.PARAMETER Color
    The color of the port in 6-character hex format.

.PARAMETER Positions
    The number of front port positions this rear port supports.

.PARAMETER Front_Ports
    Array of front port mappings for Netbox 4.5+ (bidirectional mapping).
    Each mapping should be a hashtable or PSCustomObject with:
    - front_port: (Required) The database ID of the front port
    - front_port_position: (Required) Position on the front port (1-1024)
    - position: (Required) Position on the rear port (1-1024)

.PARAMETER Description
    A description of the rear port.

.PARAMETER Mark_Connected
    Whether to mark this port as connected.

.PARAMETER Tags
    Array of tag IDs to assign to this rear port.

.PARAMETER Force
    Skip confirmation prompt.

.PARAMETER Raw
    Return the raw API response object instead of the .results collection.

.EXAMPLE
    Set-NBDCIMRearPort -Id 1 -Name "Rear 1 Updated"

    Updates the name of rear port with ID 1.

.EXAMPLE
    Set-NBDCIMRearPort -Id 1 -Front_Ports @(
        @{ front_port = 100; front_port_position = 1; position = 1 }
    )

    Updates the front port mappings using Netbox 4.5+ bidirectional format.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.7

#>

function Set-NBDCIMRearPort {
    [CmdletBinding(ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [uint64]$Device,

        [uint64]$Module,

        [string]$Name,

        [string]$Label,

        [string]$Type,

        [ValidatePattern('^[0-9a-f]{6}$')]
        [string]$Color,

        [uint16]$Positions,

        [Parameter()]
        [PSObject[]]$Front_Ports,

        [string]$Description,

        [bool]$Mark_Connected,

        [uint64[]]$Tags,

        [switch]$Force,

        [switch]$Raw
    )

    begin {
        # Check Netbox version for bidirectional port mapping support (cached by Connect-NBAPI)
        $is45OrHigher = $false
        if ($Front_Ports) {
            $netboxVersion = $script:NetboxConfig.ParsedVersion
            $is45OrHigher = $netboxVersion -and ($netboxVersion -ge [version]'4.5.0')

            if (-not $is45OrHigher) {
                Write-Warning "Front_Ports parameter is only supported on Netbox 4.5+. This parameter will be ignored on older versions."
            }
        }
    }

    process {
        Write-Verbose "Updating DCIM Rear Port"
        foreach ($RearPortID in $Id) {
            $Segments = [System.Collections.ArrayList]::new(@('dcim', 'rear-ports', $RearPortID))

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'Force', 'Front_Ports'

            $URI = BuildNewURI -Segments $Segments

            # Handle Front_Ports for Netbox 4.5+ bidirectional mapping
            if ($Front_Ports -and $is45OrHigher) {
                $URIComponents.Parameters['front_ports'] = $Front_Ports
            }

            if ($Force -or $PSCmdlet.ShouldProcess("Rear Port ID $RearPortID", "Set")) {
                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method PATCH -Raw:$Raw
            }
        }
    }

}
