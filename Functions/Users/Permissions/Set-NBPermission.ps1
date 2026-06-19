<#
.SYNOPSIS
    Updates an existing permission in Netbox.

.DESCRIPTION
    Updates an existing permission in Netbox Users module.

.PARAMETER Id
    The ID of the permission to update.

.PARAMETER Name
    Name of the permission.

.PARAMETER Description
    Description of the permission.

.PARAMETER Enabled
    Whether the permission is enabled.

.PARAMETER Object_Types
    Object types this permission applies to.

.PARAMETER Actions
    Allowed actions (view, add, change, delete).

.PARAMETER Constraints
    JSON constraints for filtering objects.

.PARAMETER Groups
    Array of group IDs.

.PARAMETER Users
    Array of user IDs.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    Set-NBPermission -Id 1 -Enabled $false

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBPermission {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Description,

        [bool]$Enabled,

        [string[]]$Object_Types,

        [ValidateSet('view', 'add', 'change', 'delete')]
        [string[]]$Actions,

        $Constraints,

        [uint64[]]$Groups,

        [uint64[]]$Users,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating Permission"
        $Segments = [System.Collections.ArrayList]::new(@('users', 'permissions', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Permission')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
