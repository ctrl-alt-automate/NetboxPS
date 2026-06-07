<#
.SYNOPSIS
    Creates a new custom field in Netbox.

.DESCRIPTION
    Creates a new custom field in Netbox Extras module.

.PARAMETER Name
    Internal name of the custom field.

.PARAMETER Label
    Display label for the custom field.

.PARAMETER Type
    Field type (text, longtext, integer, decimal, boolean, date, datetime, url, json, select, multiselect, object, multiobject).

.PARAMETER Object_Types
    Content types this field applies to.

.PARAMETER Group_Name
    Group name for organizing fields.

.PARAMETER Description
    Description of the field.

.PARAMETER Required
    Whether this field is required.

.PARAMETER Search_Weight
    Search weight (0-32767).

.PARAMETER Filter_Logic
    Filter logic (disabled, loose, exact).

.PARAMETER Ui_Visible
    UI visibility (always, if-set, hidden).

.PARAMETER Ui_Editable
    UI editability (yes, no, hidden).

.PARAMETER Is_Cloneable
    Whether the field is cloneable.

.PARAMETER Default
    Default value.

.PARAMETER Weight
    Display weight.

.PARAMETER Validation_Minimum
    Minimum value for numeric fields.

.PARAMETER Validation_Maximum
    Maximum value for numeric fields.

.PARAMETER Validation_Regex
    Validation regex pattern.

.PARAMETER Choice_Set
    Choice set ID for select fields.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBCustomField -Name "asset_id" -Label "Asset ID" -Type "text" -Object_Types @("dcim.device")

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBCustomField {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [string]$Label,

        [Parameter(Mandatory = $true)]
        [ValidateSet('text', 'longtext', 'integer', 'decimal', 'boolean', 'date', 'datetime', 'url', 'json', 'select', 'multiselect', 'object', 'multiobject')]
        [string]$Type,

        [Parameter(Mandatory = $true)]
        [string[]]$Object_Types,

        [string]$Group_Name,

        [string]$Description,

        [bool]$Required,

        [ValidateRange(0, 32767)]
        [uint16]$Search_Weight,

        [ValidateSet('disabled', 'loose', 'exact')]
        [string]$Filter_Logic,

        [ValidateSet('always', 'if-set', 'hidden')]
        [string]$Ui_Visible,

        [ValidateSet('yes', 'no', 'hidden')]
        [string]$Ui_Editable,

        [bool]$Is_Cloneable,

        $Default,

        [uint16]$Weight,

        [int64]$Validation_Minimum,

        [int64]$Validation_Maximum,

        [string]$Validation_Regex,

        [uint64]$Choice_Set,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Custom Field"
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'custom-fields'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Custom Field')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
