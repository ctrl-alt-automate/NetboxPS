<#
.SYNOPSIS
    Updates an existing journal entry in Netbox.

.DESCRIPTION
    Updates an existing journal entry in Netbox Extras module.

.PARAMETER Id
    The ID of the journal entry to update.

.PARAMETER Assigned_Object_Type
    Object type.

.PARAMETER Assigned_Object_Id
    Object ID.

.PARAMETER Comments
    Journal entry comments.

.PARAMETER Kind
    Entry kind (info, success, warning, danger).

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    Set-NBJournalEntry -Id 1 -Comments "Updated comments"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBJournalEntry {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Assigned_Object_Type,

        [uint64]$Assigned_Object_Id,

        [string]$Comments,

        [ValidateSet('info', 'success', 'warning', 'danger')]
        [string]$Kind,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating Journal Entry"
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'journal-entries', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Journal Entry')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
