<#
.SYNOPSIS
    Creates a new provider account in Netbox.

.DESCRIPTION
    Creates a new provider account in Netbox.

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
    New-NBCircuitProviderAccount -Provider 1 -Name "Main Account" -Account "ACC-001"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBCircuitProviderAccount {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [uint64]$Provider,

        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Account,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Circuit Provider Account"
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'provider-accounts'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Account, 'Create Provider Account')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
