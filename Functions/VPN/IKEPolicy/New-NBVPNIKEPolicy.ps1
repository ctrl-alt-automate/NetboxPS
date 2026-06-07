<#
.SYNOPSIS
    Creates a new VPN IKE Policy in Netbox.

.DESCRIPTION
    Creates a new VPN IKE Policy in Netbox VPN module.

.PARAMETER Name
    The IKE policy name.

.PARAMETER Version
    IKE version (1 or 2).

.PARAMETER Mode
    IKE mode (main, aggressive).

.PARAMETER Proposals
    Array of IKE proposal IDs.

.PARAMETER Preshared_Key
    Pre-shared key for the IKE policy.

.PARAMETER Description
    Description of the IKE policy.

.PARAMETER Comments
    Additional comments.

.PARAMETER CustomFields
    Hashtable of custom field values.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBVPNIKEPolicy -Name "Corporate IKE" -Version 2

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBVPNIKEPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [uint16]$Version,

        [ValidateSet('main', 'aggressive')]
        [string]$Mode,

        [uint64[]]$Proposals,

        [securestring]$Preshared_Key,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating VPN IKE Policy"
        $Segments = [System.Collections.ArrayList]::new(@('vpn', 'ike-policies'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'Preshared_Key'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSBoundParameters.ContainsKey('Preshared_Key')) {
            $URIComponents.Parameters['preshared_key'] = [System.Net.NetworkCredential]::new('', $Preshared_Key).Password
        }

        if ($PSCmdlet.ShouldProcess($Name, 'Create IKE policy')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
