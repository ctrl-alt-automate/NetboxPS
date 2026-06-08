<#
.SYNOPSIS
    Updates an existing event rule in Netbox.

.DESCRIPTION
    Updates an existing event rule in Netbox Extras module.

.PARAMETER Id
    The ID of the event rule to update.

.PARAMETER Name
    Name of the event rule.

.PARAMETER Description
    Description of the event rule.

.PARAMETER Enabled
    Whether the event rule is enabled.

.PARAMETER Object_Types
    Object types this rule applies to.

.PARAMETER Type_Create
    Trigger on create events.

.PARAMETER Type_Update
    Trigger on update events.

.PARAMETER Type_Delete
    Trigger on delete events.

.PARAMETER Type_Job_Start
    Trigger on job start events.

.PARAMETER Type_Job_End
    Trigger on job end events.

.PARAMETER Action_Type
    Action type (webhook, script).

.PARAMETER Action_Object_Type
    Action object type.

.PARAMETER Action_Object_Id
    Action object ID.

.PARAMETER Conditions
    Conditions (JSON logic).

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    Set-NBEventRule -Id 1 -Enabled $false

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBEventRule {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Description,

        [bool]$Enabled,

        [string[]]$Object_Types,

        [bool]$Type_Create,

        [bool]$Type_Update,

        [bool]$Type_Delete,

        [bool]$Type_Job_Start,

        [bool]$Type_Job_End,

        [ValidateSet('webhook', 'script', 'notification')]
        [string]$Action_Type,

        [string]$Action_Object_Type,

        [uint64]$Action_Object_Id,

        $Conditions,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating Event Rule"
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'event-rules', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Event Rule')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
