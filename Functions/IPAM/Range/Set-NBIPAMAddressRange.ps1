<#
.SYNOPSIS
    Updates an existing IPAM AddressRange in Netbox IPAM module.

.DESCRIPTION
    Updates an existing IPAM AddressRange in Netbox IPAM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to update.

.PARAMETER Start_Address
    Start Address.

.PARAMETER End_Address
    End Address.

.PARAMETER Status
    Operational status.

.PARAMETER Tenant
    Tenant assigned to this object (database ID).

.PARAMETER VRF
    VRF assigned to this object (database ID).

.PARAMETER Role
    Role assigned to this object (database ID).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.PARAMETER Description
    Brief description.

.PARAMETER Comments
    Detailed comments (Markdown is supported).

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.PARAMETER Mark_Utilized
    Mark Utilized.

.PARAMETER Mark_Populated
    Prevent the creation of IP addresses within this range

.PARAMETER Force
    Skip the confirmation prompt.

.EXAMPLE
    Set-NBIPAMAddressRange

    Updates an existing IPAM Address Range object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.7

#>

function Set-NBIPAMAddressRange {
    [CmdletBinding(ConfirmImpact = 'Medium',
                   SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Start_Address,

        [string]$End_Address,

        [ValidateSet('active', 'reserved', 'deprecated', IgnoreCase = $true)]
        [string]$Status,

        [uint64]$Tenant,

        [uint64]$VRF,

        [uint64]$Role,

        [hashtable]$Custom_Fields,

        [string]$Description,

        [string]$Comments,

        [object[]]$Tags,

        [bool]$Mark_Utilized,

        [bool]$Mark_Populated,

        [switch]$Force,

        [switch]$Raw
    )

    begin {
        $Method = 'PATCH'
    }

    process {
        foreach ($RangeID in $Id) {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'ip-ranges', $RangeID))

            Write-Verbose "Updating IP range ID $RangeID"

            if ($Force -or $PSCmdlet.ShouldProcess("ID $RangeID", 'Set IP Range')) {
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'Force'

                $URI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method $Method -Raw:$Raw
            }
        }
    }
}
