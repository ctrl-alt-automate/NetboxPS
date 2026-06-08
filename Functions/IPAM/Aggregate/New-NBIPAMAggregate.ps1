<#
.SYNOPSIS
    Creates a new IPAM Aggregate in Netbox IPAM module.

.DESCRIPTION
    Creates a new IPAM Aggregate in Netbox IPAM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Prefix
    Prefix assigned to this object (database ID).

.PARAMETER RIR
    RIR.

.PARAMETER Tenant
    Tenant assigned to this object (database ID).

.PARAMETER Date_Added
    Date Added.

.PARAMETER Description
    Brief description.

.PARAMETER Comments
    Detailed comments (Markdown is supported).

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.EXAMPLE
    New-NBIPAMAggregate

    Creates a new IPAM Aggregate object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBIPAMAggregate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][string]$Prefix,
        [Parameter(Mandatory = $true)][uint64]$RIR,
        [uint64]$Tenant,
        [datetime]$Date_Added,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating IPAM Aggregate"
        $Segments = [System.Collections.ArrayList]::new(@('ipam', 'aggregates'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments
        if ($PSCmdlet.ShouldProcess($Prefix, 'Create aggregate')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
