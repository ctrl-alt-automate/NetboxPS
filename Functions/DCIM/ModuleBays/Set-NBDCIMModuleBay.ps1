<#
.SYNOPSIS
    Updates an existing DCIM ModuleBay in Netbox DCIM module.

.DESCRIPTION
    Updates an existing DCIM ModuleBay in Netbox DCIM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Enabled
    Whether the module bay is enabled (NetBox 4.6+).

.PARAMETER Raw
    Return the raw API response instead of the results array.

.EXAMPLE
    Set-NBDCIMModuleBay

    Updates an existing DCIM ModuleBay object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBDCIMModuleBay {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][uint64]$Id,
        [uint64]$Device,
        [string]$Name,
        [string]$Label,
        [string]$Position,
        [bool]$Enabled,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Updating DCIM Module Bay"
        $Segments = [System.Collections.ArrayList]::new(@('dcim','module-bays',$Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id','Raw'
        if ($PSCmdlet.ShouldProcess($Id, 'Update module bay')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
