<#
.SYNOPSIS
    Updates an existing DCIM VirtualDeviceContext in Netbox DCIM module.

.DESCRIPTION
    Updates an existing DCIM VirtualDeviceContext in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to update.

.PARAMETER Name
    Name of the object.

.PARAMETER Device
    Device assigned to this object (database ID).

.PARAMETER Status
    Operational status.

.PARAMETER Identifier
    Identifier.

.PARAMETER Tenant
    Tenant assigned to this object (database ID).

.PARAMETER Primary_Ip4
    Primary IPv4 address assigned to this object (database ID).

.PARAMETER Primary_Ip6
    Primary IPv6 address assigned to this object (database ID).

.PARAMETER Description
    Brief description.

.PARAMETER Comments
    Detailed comments (Markdown is supported).

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.EXAMPLE
    Set-NBDCIMVirtualDeviceContext

    Updates an existing DCIM VirtualDeviceContext object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBDCIMVirtualDeviceContext {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [string]$Name,
        [uint64]$Device,
        [ValidateSet('active','planned','offline')][string]$Status,
        [string]$Identifier,
        [uint64]$Tenant,
        [uint64]$Primary_Ip4,
        [uint64]$Primary_Ip6,
        [string]$Description,
        [string]$Comments,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Updating DCIM Virtual Device Context"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','virtual-device-contexts',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update virtual device context')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
