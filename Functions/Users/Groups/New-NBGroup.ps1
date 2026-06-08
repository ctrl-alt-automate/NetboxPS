<#
.SYNOPSIS
    Creates a new group in Netbox.

.DESCRIPTION
    Creates a new group in Netbox Users module.

.PARAMETER Name
    Name of the group.

.PARAMETER Permissions
    Array of permission IDs.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBGroup -Name "Network Admins"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [uint64[]]$Permissions,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Group"
        $Segments = [System.Collections.ArrayList]::new(@('users', 'groups'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Group')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
