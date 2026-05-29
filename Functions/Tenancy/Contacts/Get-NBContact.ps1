
function Get-NBContact {
<#
    .SYNOPSIS
        Get a contact from Netbox

    .DESCRIPTION
        Obtain a contact or contacts from Netbox by ID or query

    .PARAMETER Name
        The specific name of the Contact. Must match exactly as is defined in Netbox

    .PARAMETER Id
        The database ID of the Contact

    .PARAMETER Query
        A standard search query that will match one or more Contacts.

    .PARAMETER Email
        Email address of the contact

    .PARAMETER Title
        Title of the contact

    .PARAMETER Phone
        Telephone number of the contact

    .PARAMETER Address
        Physical address of the contact

    .PARAMETER Group
        The specific group as defined in Netbox.

    .PARAMETER Group_ID
        A database ID of the group in Netbox which contacts should be filtered by. Alias: -GroupId for backwards compatibility.

    .PARAMETER Limit
        Limit the number of results to this number

    .PARAMETER Offset
        Start the search at this index in results

    .PARAMETER Raw
        Return the unparsed data from the HTTP request

    .PARAMETER All
        Automatically fetch all pages of results. Uses the API's pagination
        to retrieve all items across multiple requests.

    .PARAMETER PageSize
        Number of items per page when using -All. Default: 100.
        Range: 1-1000.

    .PARAMETER Brief
        Return a minimal representation of objects (id, url, display, name only).
        Reduces response size by ~90%. Ideal for dropdowns and reference lists.

    .PARAMETER Fields
        Specify which fields to include in the response.
        Supports nested field selection (e.g., 'site.name', 'device_type.model').

    .PARAMETER Omit
        Specify which fields to exclude from the response.
        Requires Netbox 4.5.0 or later.

    .EXAMPLE
        PS C:\> Get-NBContact

.NOTES
    AddedInVersion: v1.0.4
    The -Brief, -Fields, and -Omit parameters are mutually exclusive.
#>

    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    param
    (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [switch]$Brief,

        [string[]]$Fields,

        [string[]]$Omit,

        [Parameter(ParameterSetName = 'Query',
                   Position = 0)]
        [string]$Name,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Query,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Email,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Title,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Phone,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Address,

        [Parameter(ParameterSetName = 'Query')]
        [Alias('Groups','GroupNames')]
        [string]$Group,

        [Parameter(ParameterSetName = 'Query')]
        [Alias('GroupId')]
        [uint64]$Group_Id,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [switch]$Raw
    )

    process {
        AssertNBMutualExclusiveParam `
            -BoundParameters $PSBoundParameters `
            -Parameters 'Brief', 'Fields', 'Omit'

        Write-Verbose "Retrieving Contact"
        switch ($PSCmdlet.ParameterSetName) {
            'ById' {
                foreach ($Contact_ID in $Id) {
                    $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contacts', $Contact_ID))

                    $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'All', 'PageSize'

                    $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                    InvokeNetboxRequest -URI $uri -Raw:$Raw -All:$All -PageSize $PageSize
                }
                return
            }

            default {
                $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contacts'))

                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'All', 'PageSize'

                $uri = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $uri -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}