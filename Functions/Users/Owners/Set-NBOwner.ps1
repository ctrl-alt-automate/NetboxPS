<#
.SYNOPSIS
    Updates an owner in Netbox (Netbox 4.5+).

.DESCRIPTION
    Updates an existing owner in Netbox Users module.
    Owners represent sets of users and/or groups for tracking native object ownership.
    This endpoint is only available in Netbox 4.5 and later.

.PARAMETER Id
    The database ID of the owner to update (required).

.PARAMETER Name
    The new name for the owner.

.PARAMETER Group
    The owner group ID to associate this owner with.

.PARAMETER Description
    The new description for the owner.

.PARAMETER User_Groups
    Array of group IDs to associate with this owner.

.PARAMETER Users
    Array of user IDs to associate with this owner.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    Set-NBOwner -Id 5 -Name "Updated Name"

.EXAMPLE
    Set-NBOwner -Id 5 -Users 1, 2, 3 -Description "Updated team"

.EXAMPLE
    Get-NBOwner -Name "Old Name" | Set-NBOwner -Name "New Name"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBOwner {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [uint64]$Group,

        [string]$Description,

        [uint64[]]$User_Groups,

        [uint64[]]$Users,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating Owner"
        $Segments = [System.Collections.ArrayList]::new(@('users', 'owners', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Owner')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
