function Set-NBIPAMServiceTemplate {
<#
    .SYNOPSIS
        Update a service template in Netbox

    .DESCRIPTION
        Updates an existing service template object in Netbox.

    .PARAMETER Id
        The ID of the service template to update (required)

    .PARAMETER Name
        The name of the service template

    .PARAMETER Ports
        Array of port numbers

    .PARAMETER Protocol
        The protocol (tcp, udp, sctp)

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
        Set-NBIPAMServiceTemplate -Id 1 -Ports @(80, 443, 8080)

        Updates service template 1 with new ports
.NOTES
    AddedInVersion: v4.4.10.0

#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [uint16[]]$Ports,

        [ValidateSet('tcp', 'udp', 'sctp')]
        [string]$Protocol,

        [ValidatePattern('^(tcp|udp|sctp)/\d{1,5}$')]
        [string[]]$Port_Mappings,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating IPAM Service Template"
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'service-templates', $Id))

        # Netbox 4.7 deprecates -Ports/-Protocol in favour of -Port_Mappings. They still work
        # (removed in Netbox 5.0), so warn but keep sending whichever the caller used.
        foreach ($p in @('Ports', 'Protocol')) {
            $null = Test-NBDeprecatedParameter -ParameterName $p -DeprecatedInVersion '4.7.0' `
                -RemovedInVersion '5.0' -BoundParameters $PSBoundParameters `
                -ReplacementMessage 'Use -Port_Mappings (e.g. tcp/80, udp/53) instead.'
        }

        # Netbox 4.7+ only: drop -Port_Mappings (with a warning) on older servers
        $skipParams = @('Id', 'Raw')
        if (Test-NBMinimumVersion -ParameterName 'Port_Mappings' -MinimumVersion '4.7.0' -BoundParameters $PSBoundParameters -FeatureName 'Multi-protocol port mappings (-Port_Mappings)') { $skipParams += 'Port_Mappings' }

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName $skipParams

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update service template')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
