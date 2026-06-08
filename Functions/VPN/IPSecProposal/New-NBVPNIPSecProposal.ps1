<#
.SYNOPSIS
    Creates a new IPSec Proposal in Netbox VPN module.

.DESCRIPTION
    Creates a new IPSec (IP Security) Proposal for VPN configuration.

.PARAMETER Name
    The name of the IPSec proposal (required)

.PARAMETER Encryption_Algorithm
    Encryption algorithm (required). Options: 'aes-128-cbc', 'aes-256-cbc', 'aes-256-gcm', etc.

.PARAMETER Authentication_Algorithm
    Authentication/integrity algorithm (e.g., 'hmac-sha1', 'hmac-sha256', 'hmac-sha384', 'hmac-sha512', 'hmac-md5')

.PARAMETER SA_Lifetime_Seconds
    Security Association lifetime in seconds

.PARAMETER SA_Lifetime_Data
    Security Association lifetime in kilobytes

.PARAMETER Description
    Description of the proposal

.PARAMETER Comments
    Additional comments

.PARAMETER Custom_Fields
    Hashtable of custom field values

.PARAMETER Raw
    Return the raw API response

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBVPNIPSecProposal -Name "IPSec-Proposal-1" -Encryption_Algorithm "aes-256-cbc" -Authentication_Algorithm "hmac-sha256"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBVPNIPSecProposal {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('aes-128-cbc', 'aes-192-cbc', 'aes-256-cbc', 'aes-128-gcm', 'aes-192-gcm', 'aes-256-gcm', '3des-cbc', 'des-cbc')]
        [string]$Encryption_Algorithm,

        [ValidateSet('hmac-sha1', 'hmac-sha256', 'hmac-sha384', 'hmac-sha512', 'hmac-md5')]
        [string]$Authentication_Algorithm,

        [uint32]$SA_Lifetime_Seconds,

        [uint32]$SA_Lifetime_Data,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating VPN IPSec Proposal"
        $Segments = [System.Collections.ArrayList]::new(@('vpn', 'ipsec-proposals'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create IPSec proposal')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
