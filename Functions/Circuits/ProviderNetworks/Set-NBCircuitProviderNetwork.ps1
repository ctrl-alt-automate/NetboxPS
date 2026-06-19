<#
.SYNOPSIS
    Updates an existing provider network in Netbox.

.DESCRIPTION
    Updates an existing provider network in Netbox.

.PARAMETER Id
    The ID of the provider network to update.

.PARAMETER Provider
    Provider ID.

.PARAMETER Name
    Name of the network.

.PARAMETER Service_Id
    Service identifier.

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
    Set-NBCircuitProviderNetwork -Id 1 -Description "Updated"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBCircuitProviderNetwork {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [uint64]$Provider,

        [string]$Name,

        [string]$Service_Id,

        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating Circuit Provider Network"
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'provider-networks', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Provider Network')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
