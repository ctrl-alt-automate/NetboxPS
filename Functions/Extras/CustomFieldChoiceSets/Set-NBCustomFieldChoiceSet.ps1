<#
.SYNOPSIS
    Updates an existing custom field choice set in Netbox.

.DESCRIPTION
    Updates an existing custom field choice set in Netbox Extras module.

.PARAMETER Id
    The ID of the choice set to update.

.PARAMETER Name
    Name of the choice set.

.PARAMETER Description
    Description of the choice set.

.PARAMETER Base_Choices
    Base choices to inherit from.

.PARAMETER Extra_Choices
    Array of extra choices.

.PARAMETER Order_Alphabetically
    Whether to order choices alphabetically.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    Set-NBCustomFieldChoiceSet -Id 1 -Name "Updated Name"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBCustomFieldChoiceSet {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Description,

        [string]$Base_Choices,

        [array]$Extra_Choices,

        [bool]$Order_Alphabetically,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating Custom Field Choice Set"
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'custom-field-choice-sets', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Custom Field Choice Set')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
