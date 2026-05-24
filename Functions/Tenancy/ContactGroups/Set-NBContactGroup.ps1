
function Set-NBContactGroup {
<#
    .SYNOPSIS
        Update a contact group in Netbox

    .DESCRIPTION
        Updates a contact group object in Netbox which can be linked to other objects

    .PARAMETER Id
        Database ID of the contact group to update.

    .PARAMETER Name
        The contact group's full name, e.g "Organisation IT Support"

    .PARAMETER Description
        Short description of the contact group

    .PARAMETER Comments
        Detailed comments. Markdown supported.

    .PARAMETER Custom_Fields
        Hashtable of custom field values.

    .PARAMETER Tags
        Array of tag names or IDs to assign to the contact group.

    .PARAMETER Force
        Skip confirmation prompts.

    .PARAMETER Raw
        Return the raw API response instead of the updated object.

    .EXAMPLE
        PS C:\> Set-NBContactGroup -Id 5 -Name 'New Name' -Description 'Updated description' -Force
.NOTES

#>

    [CmdletBinding(ConfirmImpact = 'Medium',
                   SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true,
                   ValueFromPipeline = $true)]
        [uint64[]]$Id,

        [ValidateLength(1, 100)]
        [string]$Name,

        [ValidateLength(0, 200)]
        [string]$Description,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [object[]]$Tags,

        [switch]$Force,

        [switch]$Raw
    )

    begin {
        $Method = 'PATCH'
    }

    process {
        Write-Verbose "Updating Contact Group"
        foreach ($ContactGroupId in $Id) {
            $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contact-groups', $ContactGroupId))

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'Force'

            $URI = BuildNewURI -Segments $URIComponents.Segments

            if ($Force -or $PSCmdlet.ShouldProcess("ID $ContactGroupId", 'Update contact group')) {
                InvokeNetboxRequest -URI $URI -Method $Method -Body $URIComponents.Parameters -Raw:$Raw
            }
        }
    }
}




