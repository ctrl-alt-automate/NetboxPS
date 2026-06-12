<#
.SYNOPSIS
    Creates a new IPAM FHRPGroupAssignment in Netbox IPAM module.

.DESCRIPTION
    Creates a new IPAM FHRPGroupAssignment in Netbox IPAM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Group
    Group assigned to this object (database ID).

.PARAMETER Interface_Type
    Interface Type.

.PARAMETER Interface_Id
    Database ID of the interface.

.PARAMETER Priority
    Priority.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBIPAMFHRPGroupAssignment

    Creates a new IPAM FHRP Group Assignment object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBIPAMFHRPGroupAssignment {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Group,
        [Parameter(Mandatory = $true)][string]$Interface_Type,
        [Parameter(Mandatory = $true)][uint64]$Interface_Id,
        [uint16]$Priority,

        [object[]]$Tags,

        [switch]$Raw
    )
    process {
        Write-Verbose "Creating IPAM FHRP Group Assignment"
        $Segments = [System.Collections.ArrayList]::new(@('ipam','fhrp-group-assignments'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess("Group $Group Interface $Interface_Id", 'Create FHRP group assignment')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
