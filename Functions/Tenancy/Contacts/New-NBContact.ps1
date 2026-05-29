
function New-NBContact {
<#
    .SYNOPSIS
        Create a new contact in Netbox

    .DESCRIPTION
        Creates a new contact object in Netbox which can be linked to other objects

    .PARAMETER Name
        The contacts full name, e.g "Leroy Jenkins"

    .PARAMETER Email
        Email address of the contact

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

    .PARAMETER Tags
        Array of tag names or IDs to assign to the contact.

    .PARAMETER Group_Id
        Array of contact group IDs to associate with the contact.

    .PARAMETER Raw
        Return the raw API response instead of the created object.

    .EXAMPLE
        PS C:\> New-NBContact -Name 'Leroy Jenkins' -Email 'leroy.jenkins@example.com'
.NOTES
    AddedInVersion: v1.7.1

#>

    [CmdletBinding(ConfirmImpact = 'Low',
                   SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
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

        [switch]$Raw
    )

    process {
        # For parametername consistency group_id -> groups: PUT api expects "groups": [1,2,3]
        if ($PSBoundParameters.ContainsKey('Group_Id')) {
            $PSBoundParameters.Groups = $PSBoundParameters.Group_Id
            $PSBoundParameters.Remove('Group_Id') | Out-Null
        }
        Write-Verbose "Creating Contact"
        $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contacts'))

        $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create new contact')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}




