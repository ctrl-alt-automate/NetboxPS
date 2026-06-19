<#
.SYNOPSIS
    Creates a new owner group in Netbox (Netbox 4.5+).

.DESCRIPTION
    Creates a new owner group in Netbox Users module.
    Owner groups are used to organize owners for object ownership tracking.
    This endpoint is only available in Netbox 4.5 and later.

.PARAMETER Name
    The name of the owner group (required, must be unique).

.PARAMETER Description
    A description of the owner group.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    New-NBOwnerGroup -Name "Network Team"

.EXAMPLE
    New-NBOwnerGroup -Name "Data Center Ops" -Description "Responsible for physical infrastructure"

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBOwnerGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [string]$Description,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Creating Owner Group"
        $Segments = [System.Collections.ArrayList]::new(@('users', 'owner-groups'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        if ($PSCmdlet.ShouldProcess($Name, 'Create Owner Group')) {
            InvokeNetboxRequest -URI $URI -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
