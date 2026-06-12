<#
.SYNOPSIS
    Updates an existing group in Netbox.

.DESCRIPTION
    Updates an existing group in Netbox Users module.

.PARAMETER Id
    The ID of the group to update.

.PARAMETER Name
    Name of the group.

.PARAMETER Description
    Description of the group.

.PARAMETER Permissions
    Array of permission IDs.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    Set-NBGroup -Id 1 -Name "Updated Group Name"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Description,

        [uint64[]]$Permissions,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating Group"
        $Segments = [System.Collections.ArrayList]::new(@('users', 'groups', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Group')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
