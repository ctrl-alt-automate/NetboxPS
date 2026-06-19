
function Set-NBContactRole {
<#
    .SYNOPSIS
        Update a contact role in Netbox

    .DESCRIPTION
        Updates a contact role in Netbox

    .PARAMETER Name
        The contact role name, e.g "Network Support"

    .PARAMETER Slug
        The unique URL for the role. Can only contain hypens, A-Z, a-z, 0-9, and underscores

    .PARAMETER Description
        Short description of the contact role

    .PARAMETER Custom_Fields
        Hashtable of custom field values.

    .PARAMETER Raw
        Return the raw API response instead of the updated object.

    .PARAMETER Id
        Database ID of the object to update.

    .PARAMETER Tags
        One or more tags to assign to this object (tag names or IDs).

    .EXAMPLE
        PS C:\> Set-NBContactRole -Id 1 -Name 'Updated Role Name'
.NOTES
    AddedInVersion: v1.7.1

#>

    [CmdletBinding(ConfirmImpact = 'Medium',
                   SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateLength(1, 100)]
        [string]$Name,

        [ValidateLength(1, 100)]
        [ValidatePattern('^[-a-zA-Z0-9_]+$')]
        [string]$Slug,

        [ValidateLength(0, 200)]
        [string]$Description,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    begin {
        $Method = 'PATCH'
    }

    process {
        Write-Verbose "Updating Contact Role"
        foreach ($ContactRoleId in $Id) {
            $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contact-roles', $ContactRoleId))

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

            $URI = BuildNewURI -Segments $URIComponents.Segments

            if ($PSCmdlet.ShouldProcess("ID $ContactRoleId", 'Update contact role')) {
                InvokeNetboxRequest -URI $URI -Method $Method -Body $URIComponents.Parameters -Raw:$Raw
            }
        }
    }
}




