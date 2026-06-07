<#
.SYNOPSIS
    Creates a new IKE Proposal in Netbox VPN module.

.DESCRIPTION
    Creates a new IKE (Internet Key Exchange) Proposal for VPN configuration.

.PARAMETER Name
    The name of the IKE proposal (required)

.PARAMETER Authentication_Method
    Authentication method: 'preshared-keys' or 'certificates' (required)

.PARAMETER Encryption_Algorithm
    Encryption algorithm (required). Options: 'aes-128-cbc', 'aes-192-cbc', 'aes-256-cbc', etc.

.PARAMETER Authentication_Algorithm
    Authentication/integrity algorithm (e.g., 'hmac-sha1', 'hmac-sha256', 'hmac-sha384', 'hmac-sha512', 'hmac-md5')

.PARAMETER Group
    Diffie-Hellman group number (required). Options: 1, 2, 5, 14, 16, 17, 18, 19, 20, 21, 22, 23, 24

.PARAMETER SA_Lifetime
    Security Association lifetime in seconds

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
    New-NBVPNIKEProposal -Name "IKE-Proposal-1" -Authentication_Method "preshared-keys" -Encryption_Algorithm "aes-256-cbc" -Authentication_Algorithm "hmac-sha256" -Group 14

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBVPNIKEProposal {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('preshared-keys', 'certificates', 'rsa-signatures', 'dsa-signatures')]
        [string]$Authentication_Method,

        [Parameter(Mandatory = $true)]
        [ValidateSet('aes-128-cbc', 'aes-192-cbc', 'aes-256-cbc', 'aes-128-gcm', 'aes-192-gcm', 'aes-256-gcm', '3des-cbc', 'des-cbc')]
        [string]$Encryption_Algorithm,

        [ValidateSet('hmac-sha1', 'hmac-sha256', 'hmac-sha384', 'hmac-sha512', 'hmac-md5')]
        [string]$Authentication_Algorithm,

        [Parameter(Mandatory = $true)]
        [ValidateSet(1, 2, 5, 14, 16, 17, 18, 19, 20, 21, 22, 23, 24)]
        [uint16]$Group,

        [uint32]$SA_Lifetime,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating VPN IKE Proposal"
        $Segments = [System.Collections.ArrayList]::new(@('vpn', 'ike-proposals'))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create IKE proposal')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
