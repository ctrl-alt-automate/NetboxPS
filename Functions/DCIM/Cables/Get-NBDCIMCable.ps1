<#
.SYNOPSIS
    Retrieves cable objects from Netbox DCIM module.

.DESCRIPTION
    Retrieves cable objects from Netbox DCIM module.
    Supports filtering by various parameters including profile (Netbox 4.5+).

.PARAMETER All
    Retrieve all cables (pagination handled automatically).

.PARAMETER PageSize
    Number of results per page (1-1000, default 100).

.PARAMETER Limit
    Maximum number of results to return.

.PARAMETER Offset
    Number of results to skip.

.PARAMETER Id
    Filter by cable ID(s).

.PARAMETER Label
    Filter by cable label.

.PARAMETER Type
    Filter by cable type.

.PARAMETER Status
    Filter by cable status.

.PARAMETER Color
    Filter by cable color.

.PARAMETER Cable_Profile
    Filter by cable profile (Netbox 4.5+ only).

.PARAMETER Device_ID
    Filter by device ID.

.PARAMETER Device
    Filter by device name.

.PARAMETER Rack_Id
    Filter by rack ID.

.PARAMETER Rack
    Filter by rack name.

.PARAMETER Location_ID
    Filter by location ID.

.PARAMETER Location
    Filter by location name.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Brief
    Return a minimal representation of objects (id, url, display, name only).
    Reduces response size by ~90%. Ideal for dropdowns and reference lists.

.PARAMETER Fields
    Specify which fields to include in the response.
    Supports nested field selection (e.g., 'site.name', 'device_type.model').

.PARAMETER Omit
    Specify which fields to exclude from the response.
    Requires Netbox 4.5.0 or later.

.PARAMETER Termination_A_Type
    Filter by termination a type.

.PARAMETER Termination_A_ID
    Filter by termination a database ID.

.PARAMETER Termination_B_Type
    Filter by termination b type.

.PARAMETER Termination_B_ID
    Filter by termination b database ID.

.EXAMPLE
    Get-NBDCIMCable

.EXAMPLE
    Get-NBDCIMCable -Cable_Profile '1c4p-4c1p'

.EXAMPLE
    Get-NBDCIMCable -Status 'connected' -Device_ID 5

.NOTES
    AddedInVersion: v4.4.7
    The -Brief, -Fields, and -Omit parameters are mutually exclusive.
.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
#>
function Get-NBDCIMCable {
    [CmdletBinding(DefaultParameterSetName = 'Query')]
    [OutputType([PSCustomObject])]
    #region Parameters
    param
    (
        [switch]$All,

        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [switch]$Brief,

        [string[]]$Fields,

        [string[]]$Omit,

        [ValidateRange(1, 1000)]
        [uint16]$Limit,

        [ValidateRange(0, [int]::MaxValue)]
        [uint16]$Offset,

        [Parameter(ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
        [uint64[]]$Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Label,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Termination_A_Type,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Termination_A_ID,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Termination_B_Type,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Termination_B_ID,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Type,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Status,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Color,

        # Valid values from netbox/dcim/choices.py CableProfileChoices (v4.5.7).
        # Every value must carry its 'single-' / 'trunk-' / 'breakout-' prefix
        # or the NetBox API will reject the request. See #389.
        [Parameter(ParameterSetName = 'Query')]
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
            'breakout-2c4p-8c1p-shuffle'
        )]
        [Alias('Profile')]
        [string]$Cable_Profile,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Device_ID,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Device,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Rack_Id,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Rack,

        [Parameter(ParameterSetName = 'Query')]
        [uint64]$Location_ID,

        [Parameter(ParameterSetName = 'Query')]
        [string]$Location,

        [switch]$Raw
    )

    #endregion Parameters

    process {
        AssertNBMutualExclusiveParam `
            -BoundParameters $PSBoundParameters `
            -Parameters 'Brief', 'Fields', 'Omit'
        Write-Verbose "Retrieving DCIM Cable"
        switch ($PSCmdlet.ParameterSetName) {
            'ByID' { foreach ($i in $Id) { InvokeNetboxRequest -URI (BuildNewURI -Segments @('dcim', 'cables', $i)) -Raw:$Raw } }
            default {
                $Segments = [System.Collections.ArrayList]::new(@('dcim', 'cables'))

                # Check for version-specific parameters
                $excludeProfile = Test-NBMinimumVersion -ParameterName 'Cable_Profile' -MinimumVersion '4.5.0' -BoundParameters $PSBoundParameters -FeatureName 'Cable Profiles'

                # Build skip parameters list (always skip Cable_Profile, we'll add it manually as 'profile')
                $skipParams = @('Raw', 'All', 'PageSize', 'Cable_Profile')

                $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName $skipParams

                # Add Cable_Profile as 'profile' in query params (API uses 'profile')
                if ($PSBoundParameters.ContainsKey('Cable_Profile') -and -not $excludeProfile) {
                    $URIComponents.Parameters['profile'] = $Cable_Profile
                }

                $URI = BuildNewURI -Segments $URIComponents.Segments -Parameters $URIComponents.Parameters

                InvokeNetboxRequest -URI $URI -Raw:$Raw -All:$All -PageSize $PageSize
            }
        }
    }
}