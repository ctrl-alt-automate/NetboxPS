
function New-NBContactRole {
<#
    .SYNOPSIS
        Create a new contact role in Netbox

    .DESCRIPTION
        Creates a new contact role object in Netbox

    .PARAMETER Name
        The contact role name, e.g "Network Support"

    .PARAMETER Slug
        The unique URL for the role. Can only contain hypens, A-Z, a-z, 0-9, and underscores

    .PARAMETER Description
        Short description of the contact role

    .PARAMETER Custom_Fields
        Hashtable of custom field values.

    .PARAMETER Raw
        Return the raw API response instead of the created object.

    .PARAMETER Tags
        One or more tags to assign to this object (tag names or IDs).

    .EXAMPLE
        PS C:\> New-NBContactRole -Name 'Network Support' -Slug 'network-support'
.NOTES
    AddedInVersion: v1.7.1

#>

    [CmdletBinding(ConfirmImpact = 'Low',
                   SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateLength(1, 100)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateLength(1, 100)]
        [ValidatePattern('^[-a-zA-Z0-9_]+$')]
        [string]$Slug,

        [ValidateLength(0, 200)]
        [string]$Description,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Contact Role"
        $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contact-roles'))

        $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create new contact role')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}




