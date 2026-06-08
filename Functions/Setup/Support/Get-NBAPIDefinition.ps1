<#
.SYNOPSIS
    Retrieves Support objects from Netbox Setup module.

.DESCRIPTION
    Retrieves Support objects from Netbox Setup module.

.PARAMETER Format
    Filter by format.

.EXAMPLE
    Get-NBAPIDefinition

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v1.3.3

#>
function Get-NBAPIDefinition {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param
    (
        [ValidateSet('json', 'yaml', IgnoreCase = $true)]
        [string]$Format = 'json'
    )

    $Segments = [System.Collections.ArrayList]::new(@('schema'))

    $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary @{
        'format' = $Format.ToLower()
    }

    $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters -SkipConnectedCheck

    InvokeNetboxRequest -URI $URI
}
