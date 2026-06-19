<#
.SYNOPSIS
    Updates an existing provider account in Netbox.

.DESCRIPTION
    Updates an existing provider account in Netbox.

.PARAMETER Id
    The ID of the provider account to update.

.PARAMETER Provider
    Provider ID.

.PARAMETER Name
    Name of the account.

.PARAMETER Account
    Account number/identifier.

.PARAMETER Description
    Description.

.PARAMETER Comments
    Comments.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    Set-NBCircuitProviderAccount -Id 1 -Description "Updated"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBCircuitProviderAccount {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [uint64]$Provider,

        [string]$Name,

        [string]$Account,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating Circuit Provider Account"
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'provider-accounts', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Provider Account')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
