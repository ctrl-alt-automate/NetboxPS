<#
.SYNOPSIS
    Creates a new Wireless LAN in Netbox Wireless module.

.DESCRIPTION
    Creates a new Wireless LAN in Netbox Wireless module.

.PARAMETER SSID
    The SSID of the wireless LAN (required).

.PARAMETER Group
    Wireless LAN group ID.

.PARAMETER Status
    Wireless LAN status.

.PARAMETER VLAN
    Associated VLAN ID.

.PARAMETER Tenant
    Tenant ID.

.PARAMETER Auth_Type
    Authentication type.

.PARAMETER Auth_Cipher
    Authentication cipher.

.PARAMETER Auth_PSK
    Pre-shared key for authentication.

.PARAMETER Description
    Description of the wireless LAN.

.PARAMETER Comments
    Additional comments.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBWirelessLAN -SSID "Corporate-WiFi"

    Creates a new Wireless LAN object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBWirelessLAN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SSID,

        [uint64]$Group,

        [string]$Status,

        [uint64]$VLAN,

        [uint64]$Tenant,

        [string]$Auth_Type,

        [string]$Auth_Cipher,

        [securestring]$Auth_PSK,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Wireless LAN"
        $Segments = [System.Collections.ArrayList]::new(@('wireless', 'wireless-lans'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'Auth_PSK'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSBoundParameters.ContainsKey('Auth_PSK')) {
            $URIComponents.Parameters['auth_psk'] = [System.Net.NetworkCredential]::new('', $Auth_PSK).Password
        }

        if ($PSCmdlet.ShouldProcess($SSID, 'Create wireless LAN')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
