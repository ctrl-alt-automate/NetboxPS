<#
.SYNOPSIS
    Creates a new bookmark in Netbox.

.DESCRIPTION
    Creates a new bookmark in Netbox Extras module.

.PARAMETER Object_Type
    Object type (e.g., "dcim.device").

.PARAMETER Object_Id
    Object ID.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBBookmark -Object_Type "dcim.device" -Object_Id 1

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBBookmark {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Object_Type,

        [Parameter(Mandatory = $true)]
        [uint64]$Object_Id,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Bookmark"
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'bookmarks'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess("$Object_Type $Object_Id", 'Create Bookmark')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
