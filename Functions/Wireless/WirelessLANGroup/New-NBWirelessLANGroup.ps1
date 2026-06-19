<#
.SYNOPSIS
    Creates a new Wireless LAN Group in Netbox Wireless module.

.DESCRIPTION
    Creates a new Wireless LAN Group in Netbox Wireless module.

.PARAMETER Name
    The name of the wireless LAN group (required).

.PARAMETER Slug
    URL-friendly slug for the group (required).

.PARAMETER Parent
    Parent wireless LAN group ID for nesting.

.PARAMETER Description
    Description of the wireless LAN group.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBWirelessLANGroup -Name "Office" -Slug "office"

    Creates a new Wireless LAN Group object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBWirelessLANGroup {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Slug,

        [uint64]$Parent,

        [string]$Description,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Wireless LAN Group"
        $Segments = [System.Collections.ArrayList]::new(@('wireless', 'wireless-lan-groups'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create wireless LAN group')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
