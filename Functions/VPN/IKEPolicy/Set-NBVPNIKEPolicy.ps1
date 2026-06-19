<#
.SYNOPSIS
    Updates an existing VPN IKEPolicy in Netbox VPN module.

.DESCRIPTION
    Updates an existing VPN IKEPolicy in Netbox VPN module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to update.

.PARAMETER Name
    Name of the object.

.PARAMETER Version
    Version.

.PARAMETER Mode
    Mode.

.PARAMETER Proposals
    Proposals.

.PARAMETER Preshared_Key
    Preshared Key.

.PARAMETER Description
    Brief description.

.PARAMETER Comments
    Detailed comments (Markdown is supported).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    Set-NBVPNIKEPolicy

    Updates an existing VPN IKEPolicy object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBVPNIKEPolicy {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Name,[uint16]$Version,[string]$Mode,[uint64[]]$Proposals,[securestring]$Preshared_Key,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[object[]]$Tags,[switch]$Raw)
    process {
        Write-Verbose "Updating VPN IKE Policy"
        $s = [System.Collections.ArrayList]::new(@('vpn','ike-policies',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw','Preshared_Key'
        if ($PSBoundParameters.ContainsKey('Preshared_Key')) { $u.Parameters['preshared_key'] = [System.Net.NetworkCredential]::new('', $Preshared_Key).Password }
        if ($PSCmdlet.ShouldProcess($Id, 'Update IKE policy')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}
