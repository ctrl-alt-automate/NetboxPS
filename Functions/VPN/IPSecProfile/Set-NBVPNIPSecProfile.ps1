<#
.SYNOPSIS
    Updates an existing VPN IPSecProfile in Netbox VPN module.

.DESCRIPTION
    Updates an existing VPN IPSecProfile in Netbox VPN module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to update.

.PARAMETER Name
    Name of the object.

.PARAMETER Mode
    Mode.

.PARAMETER IKE_Policy
    IKE Policy.

.PARAMETER IPSec_Policy
    IPSec Policy.

.PARAMETER Description
    Brief description.

.PARAMETER Comments
    Detailed comments (Markdown is supported).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    Set-NBVPNIPSecProfile

    Updates an existing VPN IPSecProfile object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBVPNIPSecProfile {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[string]$Name,[string]$Mode,[uint64]$IKE_Policy,[uint64]$IPSec_Policy,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[object[]]$Tags,[switch]$Raw)
    process {
        Write-Verbose "Updating VPN IPSec Profile"
        $s = [System.Collections.ArrayList]::new(@('vpn','ipsec-profiles',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update IPSec profile')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}
