

function Set-NBContactAssignment {
<#
    .SYNOPSIS
        Update a contact role assignment in Netbox

    .DESCRIPTION
        Updates a contact role assignment in Netbox

    .PARAMETER Id
        The database ID of the contact assignment to update.

    .PARAMETER Object_Type
        The object type for this assignment.

    .PARAMETER Object_Id
        ID of the object to assign.

    .PARAMETER Contact
        ID of the contact to assign.

    .PARAMETER Role
        ID of the contact role to assign.

    .PARAMETER Priority
        Priority of the contact assignment.

    .PARAMETER Raw
        Return the unparsed data from the HTTP request

    .EXAMPLE
        PS C:\> Set-NBContactAssignment -Id 11 -Object_Type 'dcim.location' -Object_id 10 -Contact 15 -Role 10 -Priority 'Primary'

    .NOTES
    AddedInVersion: v4.4.7
        Valid object types: https://docs.netbox.dev/en/stable/features/contacts/#contacts_1
#>

    [CmdletBinding(ConfirmImpact = 'Medium',
                   SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias('Content_Type')]
        [ValidateSet('circuits.circuit', 'circuits.provider', 'circuits.provideraccount', 'dcim.device', 'dcim.location', 'dcim.manufacturer', 'dcim.powerpanel', 'dcim.rack', 'dcim.region', 'dcim.site', 'dcim.sitegroup', 'tenancy.tenant', 'virtualization.cluster', 'virtualization.clustergroup', 'virtualization.virtualmachine', IgnoreCase = $true)]
        [string]$Object_Type,

        [uint64]$Object_Id,

        [uint64]$Contact,

        [uint64]$Role,

        [ValidateSet('primary', 'secondary', 'tertiary', 'inactive', IgnoreCase = $true)]
        [string]$Priority,


        [object[]]$Tags,

        [switch]$Raw
    )

    begin {
        $Method = 'PATCH'
    }

    process {
        Write-Verbose "Updating Contact Assignment"
        foreach ($ContactAssignmentId in $Id) {
            $Segments = [System.Collections.ArrayList]::new(@('tenancy', 'contact-assignments', $ContactAssignmentId))

            $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

            $URI = BuildNewURI -Segments $URIComponents.Segments

            if ($PSCmdlet.ShouldProcess($ContactAssignmentId, 'Update contact assignment')) {
                InvokeNetboxRequest -URI $URI -Method $Method -Body $URIComponents.Parameters -Raw:$Raw
            }
        }
    }
}




