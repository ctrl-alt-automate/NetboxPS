<#
    .NOTES
    AddedInVersion: v1.7.1
    ===========================================================================
     Created with:  SAPIEN Technologies, Inc., PowerShell Studio 2020 v5.7.181
     Created on:    2020-10-02 15:52
     Created by:    Claussen
     Organization:  NEOnet
     Filename:      New-NBDCIMSite.ps1
    ===========================================================================
    .DESCRIPTION
        A description of the file.
#>



function New-NBDCIMSite {
    <#
    .SYNOPSIS
        Create a new Site to Netbox

    .DESCRIPTION
        Create a new Site to Netbox

    .PARAMETER Name
        Name of the object.

    .PARAMETER Slug
        URL-friendly unique identifier (slug).

    .PARAMETER Facility
        Local facility ID or description

    .PARAMETER ASN
        16- or 32-bit autonomous system number

    .PARAMETER Latitude
        GPS coordinate in decimal format (xx.yyyyyy)

    .PARAMETER Longitude
        GPS coordinate in decimal format (xx.yyyyyy)

    .PARAMETER Contact_Name
        Contact Name.

    .PARAMETER Contact_Phone
        Contact Phone.

    .PARAMETER Contact_Email
        Contact Email.

    .PARAMETER Tenant_Group
        Tenant group assigned to this object (database ID).

    .PARAMETER Tenant
        Tenant assigned to this object (database ID).

    .PARAMETER Status
        Operational status.

    .PARAMETER Region
        Region assigned to this object (database ID).

    .PARAMETER Description
        Brief description.

    .PARAMETER Comments
        Detailed comments (Markdown is supported).

    .PARAMETER Owner
        Owner assigned to this object (database ID).

    .PARAMETER Tags
        One or more tags to assign to this object (tag names or IDs).

    .PARAMETER Raw
        Return the raw API response object instead of the .results collection.

    .EXAMPLE
        New-NBDCIMSite -name MySite

        Add new Site MySite on Netbox

    #>

    [CmdletBinding(ConfirmImpact = 'Low',
        SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [string]$Slug,

        [string]$Facility,

        [uint64]$ASN,

        [decimal]$Latitude,

        [decimal]$Longitude,

        [string]$Contact_Name,

        [string]$Contact_Phone,

        [string]$Contact_Email,

        [uint64]$Tenant_Group,

        [uint64]$Tenant,

        [string]$Status,

        [uint64]$Region,

        [string]$Description,

        [string]$Comments,

        [uint64]$Owner,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating DCIM Site"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'sites'))

        if (-not $PSBoundParameters.ContainsKey('slug')) {
            $PSBoundParameters.Add('slug', $name)
        }

        $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($name, 'Create new Site')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
