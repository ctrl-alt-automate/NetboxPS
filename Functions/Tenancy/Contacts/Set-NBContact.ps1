
function Set-NBContact {
<#
    .SYNOPSIS
        Update a contact in Netbox

    .DESCRIPTION
        Updates a contact object in Netbox which can be linked to other objects

    .PARAMETER Id
        Database ID of the contact to update.

    .PARAMETER Name
        The contacts full name, e.g "Leroy Jenkins"

    .PARAMETER Email
        Email address of the contact

    .PARAMETER Group_Id
        Database ID(s) of assigned contact group(s). Alias: -Group (the previous parameter name) for backwards compatibility.

    .PARAMETER Title
        Job title or other title related to the contact

    .PARAMETER Phone
        Telephone number

    .PARAMETER Address
        Physical address, usually mailing address

    .PARAMETER Description
        Short description of the contact

    .PARAMETER Comments
        Detailed comments. Markdown supported.

    .PARAMETER Link
        URI related to the contact

    .PARAMETER Custom_Fields
        Hashtable of custom field values.

    .PARAMETER Force
        Skip confirmation prompts.

    .PARAMETER Raw
        Return the raw API response instead of the updated object.

    .PARAMETER Tags
        One or more tags to assign to this object (tag names or IDs).

    .EXAMPLE
        PS C:\> Set-NBContact -Id 10 -Name 'Leroy Jenkins' -Email 'leroy.jenkins@example.com'
.NOTES
    AddedInVersion: v1.7.1


#>

    [CmdletBinding(ConfirmImpact = 'Medium',
                   SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [ValidateLength(1, 100)]
        [string]$Name,

        [ValidateLength(0, 254)]
        [string]$Email,

        [ValidateLength(0, 100)]
        [string]$Title,

        [ValidateLength(0, 50)]
        [string]$Phone,

        [ValidateLength(0, 200)]
        [string]$Address,

        [ValidateLength(0, 200)]
        [string]$Description,

        [string]$Comments,

        [ValidateLength(0, 200)]
        [string]$Link,

        [hashtable]$Custom_Fields,

        [object[]]$Tags,

        [Alias('Group')]
        [uint64[]]$Group_Id,

        [switch]$Force,

        [switch]$Raw
    )

    begin {
        $Method = 'PATCH'
    }

    process {
        if ($PSBoundParameters.ContainsKey('Group_Id')) {
            $PSBoundParameters['Groups'] = [System.Collections.ArrayList]::new(@($PSBoundParameters['Group_Id']))
            $PSBoundParameters.Remove('Group_Id') | Out-Null
        }
        Write-Verbose "Updating Contact"
        foreach ($ContactId in $Id) {
            $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contacts', $ContactId))

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'Force'

            $URI = BuildNewURI -Segments $URIComponents.Segments

            if ($Force -or $PSCmdlet.ShouldProcess("ID $ContactId", 'Update contact')) {
                InvokeNetboxRequest -URI $URI -Method $Method -Body $URIComponents.Parameters -Raw:$Raw
            }
        }
    }
}




