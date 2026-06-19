<#
.SYNOPSIS
    Updates an existing IPAM FHRPGroupAssignment in Netbox IPAM module.

.DESCRIPTION
    Updates an existing IPAM FHRPGroupAssignment in Netbox IPAM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to update.

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
    Set-NBIPAMFHRPGroupAssignment

    Updates an existing IPAM FHRP Group Assignment object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBIPAMFHRPGroupAssignment {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Group,
        [string]$Interface_Type,
        [uint64]$Interface_Id,
        [uint16]$Priority,

        [object[]]$Tags,

        [switch]$Raw
    )
    process {
        Write-Verbose "Updating IPAM FHRP Group Assignment"
        $Segments = [System.Collections.ArrayList]::new(@('ipam','fhrp-group-assignments',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update FHRP group assignment')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
