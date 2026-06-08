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
        Array of port numbers (required)

    .PARAMETER Protocol
        The protocol (tcp, udp, sctp). Defaults to tcp.

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

        [Parameter(Mandatory = $true)]
        [uint16[]]$Ports,

        [ValidateSet('tcp', 'udp', 'sctp')]
        [string]$Protocol = 'tcp',

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating IPAM Service Template"
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'service-templates'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create new service template')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
