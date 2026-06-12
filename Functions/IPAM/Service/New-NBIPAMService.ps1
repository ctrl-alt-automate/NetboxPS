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
        Array of port numbers (required)

    .PARAMETER Protocol
        The protocol (tcp, udp, sctp). Defaults to tcp.

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

        [Parameter(Mandatory = $true)]
        [uint16[]]$Ports,

        [ValidateSet('tcp', 'udp', 'sctp')]
        [string]$Protocol = 'tcp',

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

        # Build body manually to handle parent object type
        $Body = @{
            name = $Name
            ports = $Ports
            protocol = $Protocol
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

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create new service')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $Body -Raw:$Raw
        }
    }
}
