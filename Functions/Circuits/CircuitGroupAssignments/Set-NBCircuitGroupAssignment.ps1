<#
.SYNOPSIS
    Updates an existing circuit group assignment in Netbox.

.DESCRIPTION
    Updates an existing circuit group assignment in Netbox.

.PARAMETER Id
    The ID of the assignment to update.

.PARAMETER Group
    Circuit group ID.

.PARAMETER Circuit
    Circuit ID.

.PARAMETER Priority
    Priority (primary, secondary, tertiary, inactive).

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    Set-NBCircuitGroupAssignment -Id 1 -Priority "secondary"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBCircuitGroupAssignment {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [uint64]$Group,

        [uint64]$Circuit,

        [ValidateSet('primary', 'secondary', 'tertiary', 'inactive')]
        [string]$Priority,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating Circuit Group Assignment"
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuit-group-assignments', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Circuit Group Assignment')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
