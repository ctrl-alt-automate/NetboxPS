function New-NBIPAMServiceTemplate {
<#
    .SYNOPSIS
        Create a new service template in Netbox

    .DESCRIPTION
        Creates a new service template object in Netbox.
        Service templates are reusable definitions for creating services.

    .PARAMETER Name
        The name of the service template (required)

    .PARAMETER Ports
        Array of port numbers. Required unless -Port_Mappings is used (Netbox 4.7+).

    .PARAMETER Protocol
        The protocol (tcp, udp, sctp). Defaults to tcp. Only sent together with -Ports.

    .PARAMETER Port_Mappings
        Netbox 4.7+: one or more 'protocol/port' strings (e.g. 'tcp/80', 'udp/53'). Lets a single
        service expose the same port on multiple protocols. Use this instead of -Ports/-Protocol,
        which Netbox 4.7 deprecates (still accepted; removed in Netbox 5.0). Ignored with a warning
        on older Netbox versions.

    .PARAMETER Description
        A description of the service template

    .PARAMETER Comments
        Additional comments

    .PARAMETER Custom_Fields
        A hashtable of custom fields

    .PARAMETER Raw
        Return the raw API response

    .PARAMETER Tags
        One or more tags to assign to this object (tag names or IDs).

    .EXAMPLE
        New-NBIPAMServiceTemplate -Name "HTTPS" -Ports @(443) -Protocol tcp

        Creates an HTTPS service template

    .EXAMPLE
        New-NBIPAMServiceTemplate -Name "Web Server" -Ports @(80, 443) -Protocol tcp

        Creates a web server template with HTTP and HTTPS ports
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

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating IPAM Service Template"
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'service-templates'))

        # Netbox 4.7 replaced protocol/ports with a unified port_mappings list; the legacy pair is
        # still accepted (deprecated). Drop -Port_Mappings (with a warning) on older servers.
        $skipParams = @('Raw')
        $excludePortMappings = Test-NBMinimumVersion -ParameterName 'Port_Mappings' -MinimumVersion '4.7.0' -BoundParameters $PSBoundParameters -FeatureName 'Multi-protocol port mappings (-Port_Mappings)'
        if ($excludePortMappings) { $skipParams += 'Port_Mappings' }
        if (-not $PSBoundParameters.ContainsKey('Ports') -and ($excludePortMappings -or -not $PSBoundParameters.ContainsKey('Port_Mappings'))) {
            throw "Specify -Ports (with -Protocol) or, on Netbox 4.7+, -Port_Mappings (e.g. 'tcp/80', 'udp/53')."
        }

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName $skipParams

        # -Protocol has a default that $PSBoundParameters does not carry; send it alongside -Ports
        if ($PSBoundParameters.ContainsKey('Ports') -and -not $PSBoundParameters.ContainsKey('Protocol')) {
            $URIComponents.Parameters['protocol'] = $Protocol
        }

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create new service template')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
