<#
.SYNOPSIS
    Creates a new saved filter in Netbox.

.DESCRIPTION
    Creates a new saved filter in Netbox Extras module.

.PARAMETER Name
    Name of the saved filter.

.PARAMETER Slug
    URL-friendly slug.

.PARAMETER Object_Types
    Object types this filter applies to.

.PARAMETER Description
    Description of the filter.

.PARAMETER Weight
    Display weight.

.PARAMETER Enabled
    Whether the filter is enabled.

.PARAMETER Shared
    Whether the filter is shared.

.PARAMETER Parameters
    Filter parameters (hashtable).

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBSavedFilter -Name "Active Devices" -Slug "active-devices" -Object_Types @("dcim.device") -Parameters @{status = "active"}

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBSavedFilter {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Slug,

        [Parameter(Mandatory = $true)]
        [string[]]$Object_Types,

        [string]$Description,

        [uint16]$Weight,

        [bool]$Enabled,

        [bool]$Shared,

        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Saved Filter"
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'saved-filters'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Saved Filter')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
