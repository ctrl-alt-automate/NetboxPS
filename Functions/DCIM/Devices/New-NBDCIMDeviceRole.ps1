<#
.SYNOPSIS
    Creates a new DCIM DeviceRole in Netbox DCIM module.

.DESCRIPTION
    Creates a new DCIM DeviceRole in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Name
    Name of the object.

.PARAMETER Slug
    URL-friendly unique identifier (slug).

.PARAMETER Color
    Color as a 6-digit hex code (RRGGBB).

.PARAMETER VM_Role
    Virtual machines may be assigned to this role

.PARAMETER Config_Template
    Config template assigned to this object (database ID).

.PARAMETER Description
    Brief description.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.EXAMPLE
    New-NBDCIMDeviceRole

    Creates a new DCIM DeviceRole object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBDCIMDeviceRole {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Slug,
        [string]$Color,
        [bool]$VM_Role,
        [uint64]$Config_Template,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating DCIM Device Role"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','device-roles'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create device role')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
