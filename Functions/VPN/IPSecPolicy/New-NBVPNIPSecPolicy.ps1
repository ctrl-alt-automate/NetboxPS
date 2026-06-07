<#
.SYNOPSIS
    Creates a new IPSec Policy in Netbox VPN module.

.DESCRIPTION
    Creates a new IPSec Policy in Netbox VPN module.

.PARAMETER Name
    The name of the IPSec policy (required).

.PARAMETER Proposals
    Array of IPSec proposal IDs to associate with this policy.

.PARAMETER Pfs_Group
    Diffie-Hellman group ID for Perfect Forward Secrecy (e.g., 1, 2, 5, 14, 19, 20, 21).

.PARAMETER Description
    Description of the IPSec policy.

.PARAMETER Comments
    Additional comments.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBVPNIPSecPolicy -Name "IPSec-Policy-1"

    Creates a new IPSec Policy object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBVPNIPSecPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [uint64[]]$Proposals,

        [uint16]$Pfs_Group,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating VPN IPSec Policy"
        $Segments = [System.Collections.ArrayList]::new(@('vpn', 'ipsec-policies'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create IPSec policy')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
