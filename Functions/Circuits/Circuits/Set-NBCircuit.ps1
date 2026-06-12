<#
.SYNOPSIS
    Updates an existing circuit in Netbox.

.DESCRIPTION
    Updates an existing circuit in Netbox using PATCH method.

.PARAMETER Id
    The ID of the circuit to update.

.PARAMETER CID
    Circuit ID string.

.PARAMETER Provider
    Provider ID.

.PARAMETER Type
    Circuit type ID.

.PARAMETER Status
    Circuit status.

.PARAMETER Description
    Description of the circuit.

.PARAMETER Tenant
    Tenant ID.

.PARAMETER Install_Date
    Installation date.

.PARAMETER Termination_Date
    Termination date.

.PARAMETER Commit_Rate
    Committed rate in Kbps.

.PARAMETER Comments
    Comments.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    Set-NBCircuit -Id 1 -Description "Updated description"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBCircuit {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$CID,

        [uint64]$Provider,

        [uint64]$Type,

        [string]$Status,

        [string]$Description,

        [uint64]$Tenant,

        [datetime]$Install_Date,

        [datetime]$Termination_Date,

        [ValidateRange(0, 2147483647)]
        [uint64]$Commit_Rate,

        [string]$Comments,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating Circuit"
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuits', $Id))

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update Circuit')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
