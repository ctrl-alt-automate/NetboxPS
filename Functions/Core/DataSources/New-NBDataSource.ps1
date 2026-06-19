<#
.SYNOPSIS
    Creates a new data source in Netbox.

.DESCRIPTION
    Creates a new data source in Netbox Core module.

.PARAMETER Name
    Name of the data source.

.PARAMETER Type
    Type of data source (local, git, amazon-s3).

.PARAMETER Source_Url
    Source URL for remote data sources.

.PARAMETER Description
    Description of the data source.

.PARAMETER Enabled
    Whether the data source is enabled.

.PARAMETER Ignore_Rules
    Patterns to ignore (one per line).

.PARAMETER Parameters
    Additional parameters (hashtable).

.PARAMETER Comments
    Comments.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBDataSource -Name "Config Repo" -Type "git" -Source_Url "https://github.com/example/configs.git"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBDataSource {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateSet('local', 'git', 'amazon-s3')]
        [string]$Type,

        [string]$Source_Url,

        [string]$Description,

        [bool]$Enabled,

        [string]$Ignore_Rules,

        [hashtable]$Parameters,

        [string]$Comments,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Data Source"
        $Segments = [System.Collections.ArrayList]::new(@('core', 'data-sources'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Data Source')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
