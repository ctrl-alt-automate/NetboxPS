<#
.SYNOPSIS
    Updates an existing cable in Netbox DCIM module.

.DESCRIPTION
    Updates an existing cable in Netbox DCIM module.
    Supports pipeline input for Id parameter.

.PARAMETER Id
    The ID of the cable to update.

.PARAMETER Type
    Cable type.

.PARAMETER Status
    Cable status: connected, planned, decommissioning.

.PARAMETER Tenant
    Tenant ID.

.PARAMETER Label
    Cable label.

.PARAMETER Color
    Cable color (hex code without #).

.PARAMETER Length
    Cable length.

.PARAMETER Length_Unit
    Length unit: m, cm, ft, in.

.PARAMETER Description
    Cable description.

.PARAMETER Comments
    Additional comments.

.PARAMETER Tags
    Array of tag names.

.PARAMETER Custom_Fields
    Hashtable of custom field values.

.PARAMETER Cable_Profile
    Cable profile for path tracing (Netbox 4.5+ only).
    Defines how connectors/lanes on one side map to those on the other side.

.PARAMETER Raw
    Return the raw API response.

.EXAMPLE
    Set-NBDCIMCable -Id 1 -Label 'Patch-001'

.EXAMPLE
    Set-NBDCIMCable -Id 1 -Cable_Profile '1c4p-4c1p' -Status 'connected'

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBDCIMCable {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Type,

        [string]$Status,

        [uint64]$Tenant,

        [string]$Label,

        [string]$Color,

        [decimal]$Length,

        [string]$Length_Unit,

        [string]$Description,

        [string]$Comments,

        [string[]]$Tags,

        [hashtable]$Custom_Fields,

        # Valid values from netbox/dcim/choices.py CableProfileChoices (v4.5.7).
        # Every value must carry its 'single-' / 'trunk-' / 'breakout-' prefix
        # or the NetBox API will reject the request. See #389.
        [ValidateSet(
            # Single (1 connector)
            'single-1c1p', 'single-1c2p', 'single-1c4p', 'single-1c6p',
            'single-1c8p', 'single-1c12p', 'single-1c16p',
            # Trunks (multi-connector)
            'trunk-2c1p', 'trunk-2c2p', 'trunk-2c4p', 'trunk-2c4p-shuffle',
            'trunk-2c6p', 'trunk-2c8p', 'trunk-2c12p',
            'trunk-4c1p', 'trunk-4c2p', 'trunk-4c4p', 'trunk-4c4p-shuffle',
            'trunk-4c6p', 'trunk-4c8p', 'trunk-8c4p',
            # Breakouts
            'breakout-1c2p-2c1p',       # added in Netbox 4.5.7 (#21760)
            'breakout-1c4p-4c1p',
            'breakout-1c6p-6c1p',
            'breakout-1c8p-8c1p',
            'breakout-2c4p-8c1p-shuffle'
        )]
        [Alias('Profile')]
        [string]$Cable_Profile,

        [switch]$Raw
    )
    process {
        Write-Verbose "Updating DCIM Cable"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cables', $Id))

        # Check for version-specific parameters
        $excludeProfile = Test-NBMinimumVersion -ParameterName 'Cable_Profile' -MinimumVersion '4.5.0' -BoundParameters $PSBoundParameters -FeatureName 'Cable Profiles'

        # Build parameters, excluding version-specific ones if needed
        $skipParams = @('Id', 'Raw', 'Cable_Profile')

        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName $skipParams

        # Add Cable_Profile as 'profile' in body (API uses 'profile')
        if ($PSBoundParameters.ContainsKey('Cable_Profile') -and -not $excludeProfile) {
            $URIComponents.Parameters['profile'] = $Cable_Profile
        }

        if ($PSCmdlet.ShouldProcess($Id, 'Update cable')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
