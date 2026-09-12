function New-NBIPAMService {
<#
    .SYNOPSIS
        Create a new service in Netbox

    .DESCRIPTION
        Creates a new service object in Netbox.
        Services represent network services running on devices or virtual machines.

    .PARAMETER Name
        The name of the service (required)

    .PARAMETER Ports
        Array of port numbers. Required unless -Port_Mappings is used (Netbox 4.7+).

    .PARAMETER Protocol
        The protocol (tcp, udp, sctp). Defaults to tcp. Only sent together with -Ports.

    .PARAMETER Port_Mappings
        Netbox 4.7+: one or more 'protocol/port' strings (e.g. 'tcp/80', 'udp/53'). Lets a single
        service expose the same port on multiple protocols. Use this instead of -Ports/-Protocol,
        which Netbox 4.7 deprecates (still accepted; removed in Netbox 5.0). Ignored with a warning
        on older Netbox versions.

    .PARAMETER Device
        The device ID this service runs on

    .PARAMETER Virtual_Machine
        The virtual machine ID this service runs on

    .PARAMETER IPAddresses
        Array of IP address IDs associated with this service

    .PARAMETER Description
        A description of the service

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .PARAMETER Tags
        One or more tags to assign to this object (tag names or IDs).

    .EXAMPLE
        New-NBIPAMService -Name "HTTPS" -Ports @(443) -Protocol tcp -Device 1

        Creates an HTTPS service on device 1

    .EXAMPLE
        New-NBIPAMService -Name "DNS" -Ports @(53) -Protocol udp -Virtual_Machine 1

        Creates a DNS service on VM 1

    .EXAMPLE
        New-NBIPAMService -Name "DNS" -Port_Mappings 'tcp/53', 'udp/53' -Virtual_Machine 1

        Netbox 4.7+: creates a DNS service listening on both TCP and UDP port 53
.NOTES
    AddedInVersion: v4.4.10.0

#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [uint16[]]$Ports,

        [ValidateSet('tcp', 'udp', 'sctp')]
        [string]$Protocol = 'tcp',

        [ValidatePattern('^(tcp|udp|sctp)/\d{1,5}$')]
        [string[]]$Port_Mappings,

        [uint64]$Device,

        [uint64]$Virtual_Machine,

        [uint64[]]$IPAddresses,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating IPAM Service"
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'services'))

        # Netbox 4.7 replaced protocol/ports with a unified port_mappings list; the legacy pair is
        # Netbox 4.7 deprecates -Ports/-Protocol in favour of -Port_Mappings. They still work
        # (removed in Netbox 5.0), so warn but keep sending whichever the caller used.
        foreach ($p in @('Ports', 'Protocol')) {
            $null = Test-NBDeprecatedParameter -ParameterName $p -DeprecatedInVersion '4.7.0' `
                -RemovedInVersion '5.0' -BoundParameters $PSBoundParameters `
                -ReplacementMessage 'Use -Port_Mappings (e.g. tcp/80, udp/53) instead.'
        }

        # still accepted (deprecated) so we send whichever the caller used.
        $excludePortMappings = Test-NBMinimumVersion -ParameterName 'Port_Mappings' -MinimumVersion '4.7.0' -BoundParameters $PSBoundParameters -FeatureName 'Multi-protocol port mappings (-Port_Mappings)'

        # Build body manually to handle parent object type
        $Body = @{
            name = $Name
        }
        if ($PSBoundParameters.ContainsKey('Port_Mappings') -and -not $excludePortMappings) {
            $Body['port_mappings'] = @($Port_Mappings)
        }
        if ($PSBoundParameters.ContainsKey('Ports')) {
            $Body['ports'] = $Ports
            $Body['protocol'] = $Protocol
        }
        elseif (-not $Body.ContainsKey('port_mappings')) {
            throw "Specify -Ports (with -Protocol) or, on Netbox 4.7+, -Port_Mappings (e.g. 'tcp/80', 'udp/53')."
        }

        if ($Device) {
            $Body['parent_object_type'] = 'dcim.device'
            $Body['parent_object_id'] = $Device
        } elseif ($Virtual_Machine) {
            $Body['parent_object_type'] = 'virtualization.virtualmachine'
            $Body['parent_object_id'] = $Virtual_Machine
        }

        if ($IPAddresses) { $Body['ipaddresses'] = $IPAddresses }
        if ($Description) { $Body['description'] = $Description }
        if ($Comments) { $Body['comments'] = $Comments }
        if ($Custom_Fields) { $Body['custom_fields'] = $Custom_Fields }
        if ($Tags) { $Body['tags'] = ConvertToNBTagReference -Tags $Tags }

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create new service')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $Body -Raw:$Raw
        }
    }
}
