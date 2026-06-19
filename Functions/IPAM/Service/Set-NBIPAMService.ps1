function Set-NBIPAMService {
<#
    .SYNOPSIS
        Update a service in Netbox

    .DESCRIPTION
        Updates an existing service object in Netbox.

    .PARAMETER Id
        The ID of the service to update (required)

    .PARAMETER Name
        The name of the service

    .PARAMETER Ports
        Array of port numbers

    .PARAMETER Protocol
        The protocol (tcp, udp, sctp)

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
        Set-NBIPAMService -Id 1 -Ports @(443, 8443)

        Updates service 1 to listen on ports 443 and 8443
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

        [uint64[]]$IPAddresses,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating IPAM Service"
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'services', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update service')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
