<#
.SYNOPSIS
    Creates a new DCIM InterfaceTemplate in Netbox DCIM module.

.DESCRIPTION
    Creates a new DCIM InterfaceTemplate in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Device_Type
    Device type assigned to this object (database ID).

.PARAMETER Module_Type
    Module type assigned to this object (database ID).

.PARAMETER Name
    Name of the object.

.PARAMETER Label
    Physical label.

.PARAMETER Type
    Type of the object.

.PARAMETER Enabled
    Whether the object is enabled.

.PARAMETER Mgmt_Only
    This interface is used only for out-of-band management

.PARAMETER Description
    Brief description.

.PARAMETER Poe_Mode
    Poe Mode.

.PARAMETER Poe_Type
    Poe Type.

.PARAMETER Rf_Role
    Rf Role.

.PARAMETER Channels
    Number of channels this (breakout) interface template is channelized into
    (1-1024). Requires NetBox 4.7.0 or later; ignored with a warning on
    older servers.

.PARAMETER Channel_Id
    For a template of type 'channel': the channel number (1-1024) on the
    parent interface template that this template is bound to. Requires
    NetBox 4.7.0 or later; ignored with a warning on older servers.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBDCIMInterfaceTemplate

    Creates a new DCIM InterfaceTemplate object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBDCIMInterfaceTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [uint64]$Device_Type,
        [uint64]$Module_Type,
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Label,
        [Parameter(Mandatory = $true)][string]$Type,
        [bool]$Enabled,
        [bool]$Mgmt_Only,
        [string]$Description,
        [string]$Poe_Mode,
        [string]$Poe_Type,
        [string]$Rf_Role,

        [ValidateRange(1, 1024)]
        [uint16]$Channels,

        [ValidateRange(1, 1024)]
        [uint16]$Channel_Id,

        [object[]]$Tags,

        [switch]$Raw
    )
    process {
        Write-Verbose "Creating DCIM Interface Template"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','interface-templates'))

        # NetBox 4.7+ only fields: drop them with a warning on older servers.
        $skipParams = @('Raw')
        foreach ($p in @('Channels', 'Channel_Id')) {
            if (Test-NBMinimumVersion -ParameterName $p -MinimumVersion '4.7.0' -BoundParameters $PSBoundParameters -FeatureName "The -$p parameter") {
                $skipParams += $p
            }
        }

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName $skipParams
        if ($PSCmdlet.ShouldProcess($Name, 'Create interface template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
