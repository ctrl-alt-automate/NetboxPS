<#
.SYNOPSIS
    Updates an existing DCIM InterfaceTemplate in Netbox DCIM module.

.DESCRIPTION
    Updates an existing DCIM InterfaceTemplate in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to update.

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
    (1-1024). Pass $null to clear. Requires NetBox 4.7.0 or later; ignored
    with a warning on older servers.

.PARAMETER Channel_Id
    For a template of type 'channel': the channel number (1-1024) on the
    parent interface template that this template is bound to. Pass $null to
    clear. Requires NetBox 4.7.0 or later; ignored with a warning on older
    servers.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    Set-NBDCIMInterfaceTemplate

    Updates an existing DCIM InterfaceTemplate object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBDCIMInterfaceTemplate {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device_Type,
        [uint64]$Module_Type,
        [string]$Name,
        [string]$Label,
        [string]$Type,
        [bool]$Enabled,
        [bool]$Mgmt_Only,
        [string]$Description,
        [string]$Poe_Mode,
        [string]$Poe_Type,
        [string]$Rf_Role,

        # No [ValidateRange]: it fires before [Nullable[T]] binding (#398).
        [Nullable[uint16]]$Channels,

        [Nullable[uint16]]$Channel_Id,

        [object[]]$Tags,

        [switch]$Raw
    )
    process {
        Write-Verbose "Updating DCIM Interface Template"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','interface-templates',$Id))

        # NetBox 4.7+ only fields: drop them with a warning on older servers.
        $skipParams = @('Id', 'Raw')
        foreach ($p in @('Channels', 'Channel_Id')) {
            if (Test-NBMinimumVersion -ParameterName $p -MinimumVersion '4.7.0' -BoundParameters $PSBoundParameters -FeatureName "The -$p parameter") {
                $skipParams += $p
            }
        }

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName $skipParams
        if ($PSCmdlet.ShouldProcess($Id, 'Update interface template')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
