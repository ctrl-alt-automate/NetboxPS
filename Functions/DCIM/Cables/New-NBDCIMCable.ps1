<#
.SYNOPSIS
    Creates a new cable in Netbox DCIM module.

.DESCRIPTION
    Creates a new cable connecting two termination points in Netbox.
    Supports connecting interfaces, console ports, power ports, etc.

.PARAMETER A_Terminations
    Array of termination objects for the A side. Each object should have:
    - object_type: The type (e.g., 'dcim.interface', 'dcim.consoleport')
    - object_id: The ID of the object

.PARAMETER B_Terminations
    Array of termination objects for the B side. Same format as A_Terminations.

.PARAMETER Type
    Cable type (e.g., 'cat5', 'cat5e', 'cat6', 'cat6a', 'cat7', 'cat7a', 'cat8',
    'dac-active', 'dac-passive', 'mrj21-trunk', 'coaxial', 'mmf', 'mmf-om1',
    'mmf-om2', 'mmf-om3', 'mmf-om4', 'mmf-om5', 'smf', 'smf-os1', 'smf-os2',
    'aoc', 'power')

.PARAMETER Status
    Cable status: 'connected', 'planned', 'decommissioning'

.PARAMETER Tenant
    Tenant ID

.PARAMETER Label
    Cable label

.PARAMETER Color
    Cable color (hex code without #)

.PARAMETER Length
    Cable length

.PARAMETER Length_Unit
    Length unit: 'm', 'cm', 'ft', 'in'

.PARAMETER Description
    Cable description

.PARAMETER Comments
    Additional comments

.PARAMETER Tags
    Array of tag names or IDs

.PARAMETER Cable_Profile
    Cable profile for path tracing (Netbox 4.5+ only).
    Defines how connectors/lanes on one side map to those on the other side.
    Available profiles:
    - Single: 1c1p, 1c2p, 1c4p, 1c6p, 1c8p, 1c12p, 1c16p
    - Trunk: 2c1p, 2c2p, 2c4p, 2c4p-shuffle, 2c6p, 2c8p, 2c12p,
             4c1p, 4c2p, 4c4p, 4c4p-shuffle, 4c6p, 4c8p, 8c4p
    - Breakout: 1c4p-4c1p, 1c6p-6c1p, 2c4p-8c1p-shuffle

.PARAMETER Custom_Fields
    Hashtable of custom field values

.PARAMETER Raw
    Return the raw API response

.EXAMPLE
    $termA = @{ object_type = 'dcim.interface'; object_id = 1 }
    $termB = @{ object_type = 'dcim.interface'; object_id = 2 }
    New-NBDCIMCable -A_Terminations @($termA) -B_Terminations @($termB)

.EXAMPLE
    # Connect two interfaces by ID using helper
    New-NBDCIMCable -A_Terminations @(@{object_type='dcim.interface';object_id=10}) `
                    -B_Terminations @(@{object_type='dcim.interface';object_id=20}) `
                    -Type 'cat6' -Status 'connected' -Label 'Patch-001'

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBDCIMCable {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$A_Terminations,

        [Parameter(Mandatory = $true)]
        [object[]]$B_Terminations,

        [ValidateSet('cat3', 'cat5', 'cat5e', 'cat6', 'cat6a', 'cat7', 'cat7a', 'cat8',
                     'dac-active', 'dac-passive', 'mrj21-trunk',
                     'coaxial', 'lmr-100', 'lmr-200', 'lmr-400',
                     'rg-6', 'rg-8', 'rg-11', 'rg-59', 'rg-62', 'rg-213',
                     'mmf', 'mmf-om1', 'mmf-om2', 'mmf-om3', 'mmf-om4', 'mmf-om5',
                     'smf', 'smf-os1', 'smf-os2', 'aoc', 'power', 'usb')]
        [string]$Type,

        [ValidateSet('connected', 'planned', 'decommissioning')]
        [string]$Status = 'connected',

        [uint64]$Tenant,

        [string]$Label,

        [ValidatePattern('^[0-9a-fA-F]{6}$')]
        [string]$Color,

        [decimal]$Length,

        [ValidateSet('m', 'cm', 'ft', 'in', 'km', 'mi')]
        [string]$Length_Unit,

        [string]$Description,

        [string]$Comments,

        [object[]]$Tags,

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
        Write-Verbose "Creating DCIM Cable"
        $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cables'))

        # Check for version-specific parameters
        $excludeProfile = Test-NBMinimumVersion -ParameterName 'Cable_Profile' -MinimumVersion '4.5.0' -BoundParameters $PSBoundParameters -FeatureName 'Cable Profiles'

        # Build the body manually since terminations need special handling
        $body = @{
            a_terminations = $A_Terminations
            b_terminations = $B_Terminations
        }

        if ($PSBoundParameters.ContainsKey('Type')) { $body.type = $Type }
        if ($PSBoundParameters.ContainsKey('Status')) { $body.status = $Status }
        if ($PSBoundParameters.ContainsKey('Tenant')) { $body.tenant = $Tenant }
        if ($PSBoundParameters.ContainsKey('Label')) { $body.label = $Label }
        if ($PSBoundParameters.ContainsKey('Color')) { $body.color = $Color }
        if ($PSBoundParameters.ContainsKey('Length')) { $body.length = $Length }
        if ($PSBoundParameters.ContainsKey('Length_Unit')) { $body.length_unit = $Length_Unit }
        if ($PSBoundParameters.ContainsKey('Description')) { $body.description = $Description }
        if ($PSBoundParameters.ContainsKey('Comments')) { $body.comments = $Comments }
        if ($PSBoundParameters.ContainsKey('Tags')) { $body.tags = $Tags }
        if ($PSBoundParameters.ContainsKey('Custom_Fields')) { $body.custom_fields = $Custom_Fields }
        if ($PSBoundParameters.ContainsKey('Cable_Profile') -and -not $excludeProfile) { $body.profile = $Cable_Profile }

        $URI = BuildNewURI -Segments $Segments

        $displayName = if ($Label) { $Label } else { "Cable" }

        if ($PSCmdlet.ShouldProcess($displayName, 'Create cable')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $body -Raw:$Raw
        }
    }
}
