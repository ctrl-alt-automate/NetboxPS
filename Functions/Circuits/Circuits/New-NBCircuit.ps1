<#
.SYNOPSIS
    Creates a new Circuit in Netbox C module.

.DESCRIPTION
    Creates a new Circuit in Netbox C module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER CID
    Unique circuit ID

.PARAMETER Provider
    Provider assigned to this object (database ID).

.PARAMETER Type
    Type of the object.

.PARAMETER Status
    Operational status.

.PARAMETER Description
    Brief description.

.PARAMETER Tenant
    Tenant assigned to this object (database ID).

.PARAMETER Termination_A
    Termination A.

.PARAMETER Install_Date
    Install Date.

.PARAMETER Termination_Z
    Termination Z.

.PARAMETER Commit_Rate
    Committed rate

.PARAMETER Comments
    Detailed comments (Markdown is supported).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.PARAMETER Force
    Skip the confirmation prompt.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBCircuit

    Creates a new Circuit object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v1.3.3

#>

function New-NBCircuit {
    [CmdletBinding(ConfirmImpact = 'Low',
        SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CID,

        [Parameter(Mandatory = $true)]
        [uint64]$Provider,

        [Parameter(Mandatory = $true)]
        [uint64]$Type,

        [ValidateSet('active', 'planned', 'provisioning', 'offline', 'deprovisioning', 'decommissioned')]
        [string]$Status = 'active',

        [string]$Description,

        [uint64]$Tenant,

        [string]$Termination_A,

        [datetime]$Install_Date,

        [string]$Termination_Z,

        [ValidateRange(0, 2147483647)]
        [uint64]$Commit_Rate,

        [string]$Comments,

        [hashtable]$Custom_Fields,

        [switch]$Force,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Circuit"
        $Segments = [System.Collections.ArrayList]::new(@('circuits', 'circuits'))

        $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw', 'Force'

        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($Force -or $PSCmdlet.ShouldProcess($CID, 'Create new circuit')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
