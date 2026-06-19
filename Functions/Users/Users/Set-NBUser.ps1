<#
.SYNOPSIS
    Updates an existing user in Netbox.

.DESCRIPTION
    Updates an existing user in Netbox Users module.

.PARAMETER Id
    The ID of the user to update.

.PARAMETER Username
    Username.

.PARAMETER Password
    Password. Use SecureString for security.

.PARAMETER First_Name
    First name.

.PARAMETER Last_Name
    Last name.

.PARAMETER Email
    Email address.

.PARAMETER Is_Staff
    Whether user has staff access.
    DEPRECATED: This parameter is removed in Netbox 4.5 and will be ignored.

.PARAMETER Is_Active
    Whether user is active.

.PARAMETER Is_Superuser
    Whether user is a superuser.

.PARAMETER Groups
    Array of group IDs.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    Set-NBUser -Id 1 -Is_Active $false

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBUser {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Username,

        [securestring]$Password,

        [string]$First_Name,

        [string]$Last_Name,

        [string]$Email,

        [bool]$Is_Staff,

        [bool]$Is_Active,

        [bool]$Is_Superuser,

        [uint64[]]$Groups,

        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating User"
        $Segments = [System.Collections.ArrayList]::new(@('users', 'users', $Id))

        # Check for deprecated parameters
        $excludeIsStaff = Test-NBDeprecatedParameter -ParameterName 'Is_Staff' -DeprecatedInVersion '4.5.0' -BoundParameters $PSBoundParameters

        # Build params manually to handle SecureString conversion
        $params = @{}
        foreach ($key in $PSBoundParameters.Keys) {
            if ($key -eq 'Password') {
                $params['password'] = [System.Net.NetworkCredential]::new('', $Password).Password
            }
            elseif ($key -eq 'Is_Staff' -and $excludeIsStaff) {
                # Skip deprecated parameter on Netbox 4.5+
                continue
            }
            elseif ($key -notin 'Id', 'Raw', 'WhatIf', 'Confirm', 'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable') {
                $params[$key] = $PSBoundParameters[$key]
            }
        }

        $URI = BuildNewURI -Segments $Segments

        if ($PSCmdlet.ShouldProcess($Id, 'Update User')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $params -Raw:$Raw
        }
    }
}
