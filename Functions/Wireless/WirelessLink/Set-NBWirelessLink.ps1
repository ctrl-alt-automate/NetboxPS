<#
.SYNOPSIS
    Updates an existing Wireless Link in Netbox Wireless module.

.DESCRIPTION
    Updates an existing Wireless Link in Netbox Wireless module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to update.

.PARAMETER Interface_A
    Interface A.

.PARAMETER Interface_B
    Interface B.

.PARAMETER SSID
    SSID.

.PARAMETER Status
    Operational status.

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
    Set-NBWirelessLink

    Updates an existing Wireless Link object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBWirelessLink {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[uint64]$Interface_A,[uint64]$Interface_B,
        [string]$SSID,[string]$Status,[uint64]$Tenant,[string]$Auth_Type,[string]$Auth_Cipher,[securestring]$Auth_PSK,
        [string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[object[]]$Tags,[switch]$Raw)
    process {
        Write-Verbose "Updating Wireless Link"
        $s = [System.Collections.ArrayList]::new(@('wireless','wireless-links',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw','Auth_PSK'
        if ($PSBoundParameters.ContainsKey('Auth_PSK')) { $u.Parameters['auth_psk'] = [System.Net.NetworkCredential]::new('', $Auth_PSK).Password }
        if ($PSCmdlet.ShouldProcess($Id, 'Update wireless link')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}
