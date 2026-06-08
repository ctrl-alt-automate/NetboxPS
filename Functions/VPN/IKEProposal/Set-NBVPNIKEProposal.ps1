<#
.SYNOPSIS
    Updates an existing VPN IKEProposal in Netbox VPN module.

.DESCRIPTION
    Updates an existing VPN IKEProposal in Netbox VPN module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to update.

.PARAMETER Name
    Name of the object.

.PARAMETER Authentication_Method
    Authentication Method.

.PARAMETER Encryption_Algorithm
    Encryption Algorithm.

.PARAMETER Authentication_Algorithm
    Authentication Algorithm.

.PARAMETER Group
    Group assigned to this object (database ID).

.PARAMETER SA_Lifetime
    Security association lifetime (in seconds)

.PARAMETER Description
    Brief description.

.PARAMETER Comments
    Detailed comments (Markdown is supported).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    Set-NBVPNIKEProposal

    Updates an existing VPN IKEProposal object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBVPNIKEProposal {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,[string]$Name,
        [string]$Authentication_Method,[string]$Encryption_Algorithm,[string]$Authentication_Algorithm,[uint16]$Group,[uint32]$SA_Lifetime,[string]$Description,[string]$Comments,[hashtable]$Custom_Fields,[object[]]$Tags,[switch]$Raw)
    process {
        Write-Verbose "Updating VPN IKE Proposal"
        $s = [System.Collections.ArrayList]::new(@('vpn','ike-proposals',$Id)); $u = BuildURIComponents -URISegments $s.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update IKE proposal')) { InvokeNetboxRequest -URI (BuildNewURI -Segments $u.Segments) -Method PATCH -Body $u.Parameters -Raw:$Raw }
    }
}
