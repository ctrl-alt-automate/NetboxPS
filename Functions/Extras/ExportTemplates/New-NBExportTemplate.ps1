<#
.SYNOPSIS
    Creates a new export template in Netbox.

.DESCRIPTION
    Creates a new export template in Netbox Extras module.

.PARAMETER Name
    Name of the export template.

.PARAMETER Object_Types
    Object types this template applies to.

.PARAMETER Description
    Description of the template.

.PARAMETER Template_Code
    Jinja2 template code.

.PARAMETER Mime_Type
    MIME type for the export.

.PARAMETER File_Extension
    File extension for the export.

.PARAMETER As_Attachment
    Whether to serve as attachment.

.PARAMETER Data_Source
    Data source ID.

.PARAMETER Data_File
    Data file ID.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBExportTemplate -Name "CSV Export" -Object_Types @("dcim.device") -Template_Code "{% for d in queryset %}{{ d.name }}{% endfor %}"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBExportTemplate {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string[]]$Object_Types,

        [string]$Description,

        [string]$Template_Code,

        [string]$Mime_Type,

        [string]$File_Extension,

        [bool]$As_Attachment,

        [uint64]$Data_Source,

        [uint64]$Data_File,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Export Template"
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'export-templates'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Export Template')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
