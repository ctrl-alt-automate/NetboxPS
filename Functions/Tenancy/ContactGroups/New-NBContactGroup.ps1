
function New-NBContactGroup {
<#
    .SYNOPSIS
        Create a new contact group in Netbox

    .DESCRIPTION
        Creates a new contact group object in Netbox which can be linked to other objects

    .PARAMETER Name
        The contact group's full name, e.g "Organisation IT Support"

    .PARAMETER Slug
        The contact group's slug, a URL-friendly unique identifier. Auto-generated from Name if not provided.

    .PARAMETER Description
        Short description of the contact group

    .PARAMETER Comments
        Detailed comments. Markdown supported.

    .PARAMETER Parent
        The parent contact group, specified by name or database ID. Establishes a hierarchy of contact groups.

    .PARAMETER Custom_Fields
        Hashtable of custom field values.

    .PARAMETER Tags
        Array of tag names or IDs to assign to the contact group.

    .PARAMETER Raw
        Return the raw API response instead of the created object.

    .EXAMPLE
        PS C:\> New-NBContactGroup -Name 'Admins'

    .EXAMPLE
        PS C:\> New-NBContactGroup -Name 'Network Admin' -Description 'Supporters of the network' -Parent 'Admins'
        Creates a contact group named 'Network Admin' which is a child of the 'Admins' contact group.

    .NOTES
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

        [ValidateLength(0, 100)]
        [string]$Slug,

        [ValidateLength(0, 200)]
        [string]$Description,

        [string]$Comments,

        [ValidateLength(1, 100)]
        [string]$Parent,

        [hashtable]$Custom_Fields,

        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Contact Group"
        $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contact-groups'))

        # Auto-generate slug from name if not provided. NetBox's REST API requires
        # 'slug' on POST (it does not auto-slug server-side; only the web UI does),
        # so derive it client-side to match New-NBTenantGroup and the documented examples.
        if (-not $PSBoundParameters.ContainsKey('Slug')) {
            $PSBoundParameters['Slug'] = ($Name -replace '\s+', '-').ToLower()
        }

        $paramDict = $PSBoundParameters
        if ($PSBoundParameters.ContainsKey('Parent') -and $false -eq [System.UInt64]::TryParse($Parent, [ref]$null)) {
            # if it isn't a int, we assume it's a name which needs to be presented differently in the body
            $paramDict = @{}
            foreach ($key in $PSBoundParameters.Keys) {
                $paramDict[$key] = $PSBoundParameters[$key]
            }
            $paramDict['parent'] = @{ 'name' = $Parent }
        }

        $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $paramDict -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create new contactgroup')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}




