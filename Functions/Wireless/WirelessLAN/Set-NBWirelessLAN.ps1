<#
.SYNOPSIS
    Updates an existing Wireless LAN in Netbox Wireless module.

.DESCRIPTION
    Updates an existing Wireless LAN in Netbox Wireless module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to update.

.PARAMETER SSID
    SSID.

.PARAMETER Group
    Group assigned to this object (database ID).

.PARAMETER Status
    Operational status.

.PARAMETER VLAN
    VLAN assigned to this object (database ID).

.PARAMETER Tenant
    Tenant assigned to this object (database ID).

.PARAMETER Auth_Type
    Auth Type.

.PARAMETER Auth_Cipher
    Auth Cipher.

.PARAMETER Auth_PSK
    Auth PSK.

.PARAMETER Description
    Brief description.

.PARAMETER Comments
    Detailed comments (Markdown is supported).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    Set-NBWirelessLAN

    Updates an existing Wireless LAN object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBWirelessLAN {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[string]$SSID,[uint64]$Group,[string]$Status,[uint64]$VLAN,[uint64]$Tenant,
        [string]$Auth_Type,[string]$Auth_Cipher,[securestring]$Auth_PSK,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[object[]]$Tags,[switch]$Raw)
    process {
        Write-Verbose "Updating Wireless LAN"
        $s = [System.Collections.ArrayList]::new(@('wireless','wireless-lans',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw','Auth_PSK'
        if ($PSBoundParameters.ContainsKey('Auth_PSK')) { $u.Parameters['auth_psk'] = [System.Net.NetworkCredential]::new('', $Auth_PSK).Password }
        if ($PSCmdlet.ShouldProcess($Id, 'Update wireless LAN')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}
