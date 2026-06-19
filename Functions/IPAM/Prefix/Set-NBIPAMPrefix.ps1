<#
.SYNOPSIS
    Updates an existing IPAM Prefix in Netbox IPAM module.

.DESCRIPTION
    Updates an existing IPAM Prefix in Netbox IPAM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to update.

.PARAMETER Prefix
    Prefix assigned to this object (database ID).

.PARAMETER Status
    Operational status.

.PARAMETER Tenant
    Tenant assigned to this object (database ID).

.PARAMETER Scope_Type
    Scope Type.

.PARAMETER Scope_Id
    Database ID of the scope.

.PARAMETER VRF
    VRF assigned to this object (database ID).

.PARAMETER VLAN
    VLAN assigned to this object (database ID).

.PARAMETER Role
    Role assigned to this object (database ID).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.PARAMETER Description
    Brief description.

.PARAMETER Is_Pool
    All IP addresses within this prefix are considered usable

.PARAMETER Owner
    Owner assigned to this object (database ID).

.PARAMETER Force
    Skip the confirmation prompt.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    Set-NBIPAMPrefix

    Updates an existing IPAM Prefix object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v1.0.4

#>

function Set-NBIPAMPrefix {
    [CmdletBinding(ConfirmImpact = 'Medium',
                   SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Prefix,

        [ValidateSet('active', 'reserved', 'deprecated', 'container', IgnoreCase = $true)]
        [string]$Status,

        [uint64]$Tenant,

        [ValidateSet('dcim.region', 'dcim.sitegroup', 'dcim.site', 'dcim.location', IgnoreCase = $true)]
        [string]$Scope_Type,

        [uint64]$Scope_Id,

        [uint64]$VRF,

        [uint64]$VLAN,

        [uint64]$Role,

        [hashtable]$Custom_Fields,

        [string]$Description,

        [bool]$Is_Pool,

        [uint64]$Owner,

        [switch]$Force,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        if ($PSBoundParameters.ContainsKey('Scope_Type') -xor $PSBoundParameters.ContainsKey('Scope_Id')) {
            throw 'Parameters -Scope_Type and -Scope_Id must be used together.'
        }

        foreach ($PrefixId in $Id) {
            $Segments = [System.Collections.ArrayList]::new(@('ipam', 'prefixes', $PrefixId))

            Write-Verbose "Obtaining Prefix from ID $PrefixId"

            if ($Force -or $PSCmdlet.ShouldProcess("ID: $PrefixId", 'Set')) {
                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'Force'

                $URI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method PATCH -Raw:$Raw
            }
        }
    }
}






