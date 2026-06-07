
function New-NBContactAssignment {
<#
    .SYNOPSIS
        Create a new contact role assignment in Netbox

    .DESCRIPTION
        Creates a new contact role assignment in Netbox

    .PARAMETER Object_Type
        The type of the object for this assignment.

    .PARAMETER Object_Id
        ID of the object to assign.

    .PARAMETER Contact
        ID of the contact to assign.

    .PARAMETER Role
        ID of the contact role to assign.

    .PARAMETER Priority
        Piority of the contact assignment.

    .PARAMETER Raw
        Return the unparsed data from the HTTP request

    .PARAMETER Tags
        One or more tags to assign to this object (tag names or IDs).

    .EXAMPLE
        PS C:\> New-NBContactAssignment -Object_Type 'dcim.location' -Object_Id 10 -Contact 15 -Role 10 -Priority 'Primary'

    .NOTES
    AddedInVersion: v1.7.1
        Valid object types: https://docs.netbox.dev/en/stable/features/contacts/#contacts_1
#>

    [CmdletBinding(ConfirmImpact = 'Low',
                   SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('circuits.circuit', 'circuits.provider', 'circuits.provideraccount', 'dcim.device', 'dcim.location', 'dcim.manufacturer', 'dcim.powerpanel', 'dcim.rack', 'dcim.region', 'dcim.site', 'dcim.sitegroup', 'tenancy.tenant', 'virtualization.cluster', 'virtualization.clustergroup', 'virtualization.virtualmachine', IgnoreCase = $true)]
        [Alias('Content_Type')]
        [string]$Object_Type,

        [Parameter(Mandatory = $true)]
        [uint64]$Object_Id,

        [Parameter(Mandatory = $true)]
        [uint64]$Contact,

        [Parameter(Mandatory = $true)]
        [uint64]$Role,

        [ValidateSet('primary', 'secondary', 'tertiary', 'inactive', IgnoreCase = $true)]
        [string]$Priority,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Contact Assignment"
        $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contact-assignments'))

        $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Object_Type, 'Create new contact assignment')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}




