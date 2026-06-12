<#
.SYNOPSIS
    Updates an owner group in Netbox (Netbox 4.5+).

.DESCRIPTION
    Updates an existing owner group in Netbox Users module.
    Owner groups are used to organize owners for object ownership tracking.
    This endpoint is only available in Netbox 4.5 and later.

.PARAMETER Id
    The database ID of the owner group to update (required).

.PARAMETER Name
    The new name for the owner group.

.PARAMETER Description
    The new description for the owner group.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    Set-NBOwnerGroup -Id 5 -Name "Updated Team Name"

.EXAMPLE
    Set-NBOwnerGroup -Id 5 -Description "Updated description"

.EXAMPLE
    Get-NBOwnerGroup -Name "Old Name" | Set-NBOwnerGroup -Name "New Name"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBOwnerGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Description,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating Owner Group"
        $Segments = [System.Collections.ArrayList]::new(@('users', 'owner-groups', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Owner Group')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
