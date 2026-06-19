<#
.SYNOPSIS
    Creates a new IPAM VLANTranslationRule in Netbox IPAM module.

.DESCRIPTION
    Creates a new IPAM VLANTranslationRule in Netbox IPAM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Policy
    Policy.

.PARAMETER Local_Vid
    Numeric VLAN ID (1-4094)

.PARAMETER Remote_Vid
    Numeric VLAN ID (1-4094)

.PARAMETER Description
    Brief description.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.EXAMPLE
    New-NBIPAMVLANTranslationRule

    Creates a new IPAM VLAN Translation Rule object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBIPAMVLANTranslationRule {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][uint64]$Policy,
        [Parameter(Mandatory = $true)][ValidateRange(1, 4094)][uint16]$Local_Vid,
        [Parameter(Mandatory = $true)][ValidateRange(1, 4094)][uint16]$Remote_Vid,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating IPAM VLAN Translation Rule"
        $Segments = [System.Collections.ArrayList]::new(@('ipam','vlan-translation-rules'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess("$Local_Vid -> $Remote_Vid", 'Create VLAN translation rule')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
