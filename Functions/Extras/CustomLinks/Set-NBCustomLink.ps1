<#
.SYNOPSIS
    Updates an existing custom link in Netbox.

.DESCRIPTION
    Updates an existing custom link in Netbox Extras module.

.PARAMETER Id
    The ID of the custom link to update.

.PARAMETER Name
    Name of the custom link.

.PARAMETER Object_Types
    Object types this link applies to.

.PARAMETER Enabled
    Whether the link is enabled.

.PARAMETER Link_Text
    Link text (Jinja2 template).

.PARAMETER Link_Url
    Link URL (Jinja2 template).

.PARAMETER Weight
    Display weight.

.PARAMETER Group_Name
    Group name for organizing links.

.PARAMETER Button_Class
    Button CSS class.

.PARAMETER New_Window
    Whether to open in new window.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    Set-NBCustomLink -Id 1 -Enabled $false

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBCustomLink {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string[]]$Object_Types,

        [bool]$Enabled,

        [string]$Link_Text,

        [string]$Link_Url,

        [uint16]$Weight,

        [string]$Group_Name,

        [ValidateSet('outline-dark', 'blue', 'indigo', 'purple', 'pink', 'red', 'orange', 'yellow', 'green', 'teal', 'cyan', 'gray', 'black', 'white', 'ghost-dark')]
        [string]$Button_Class,

        [bool]$New_Window,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating Custom Link"
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'custom-links', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Custom Link')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
