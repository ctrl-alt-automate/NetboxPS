<#
.SYNOPSIS
    Creates a new journal entry in Netbox.

.DESCRIPTION
    Creates a new journal entry in Netbox Extras module.

.PARAMETER Assigned_Object_Type
    Object type (e.g., "dcim.device").

.PARAMETER Assigned_Object_Id
    Object ID.

.PARAMETER Comments
    Journal entry comments (required).

.PARAMETER Kind
    Entry kind (info, success, warning, danger).

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBJournalEntry -Assigned_Object_Type "dcim.device" -Assigned_Object_Id 1 -Comments "Device maintenance completed"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBJournalEntry {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Assigned_Object_Type,

        [Parameter(Mandatory = $true)]
        [uint64]$Assigned_Object_Id,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Comments,

        [ValidateSet('info', 'success', 'warning', 'danger')]
        [string]$Kind,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Journal Entry"
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'journal-entries'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess("$Assigned_Object_Type $Assigned_Object_Id", 'Create Journal Entry')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
