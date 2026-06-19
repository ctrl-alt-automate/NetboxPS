<#
.SYNOPSIS
    Creates a new custom field choice set in Netbox.

.DESCRIPTION
    Creates a new custom field choice set in Netbox Extras module.

.PARAMETER Name
    Name of the choice set.

.PARAMETER Description
    Description of the choice set.

.PARAMETER Base_Choices
    Base choices to inherit from.

.PARAMETER Extra_Choices
    Array of extra choices in format @(@("value1", "label1"), @("value2", "label2")).

.PARAMETER Order_Alphabetically
    Whether to order choices alphabetically.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBCustomFieldChoiceSet -Name "Status Options" -Extra_Choices @(@("active", "Active"), @("inactive", "Inactive"))

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBCustomFieldChoiceSet {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [string]$Description,

        [string]$Base_Choices,

        [array]$Extra_Choices,

        [bool]$Order_Alphabetically,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Custom Field Choice Set"
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'custom-field-choice-sets'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Custom Field Choice Set')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
