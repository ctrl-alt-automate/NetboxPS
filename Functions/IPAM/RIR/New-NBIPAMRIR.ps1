<#
.SYNOPSIS
    Creates a new IPAM RIR in Netbox IPAM module.

.DESCRIPTION
    Creates a new IPAM RIR in Netbox IPAM module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Name
    Name of the object.

.PARAMETER Slug
    URL-friendly unique identifier (slug).

.PARAMETER Is_Private
    IP space managed by this RIR is considered private

.PARAMETER Description
    Brief description.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.PARAMETER Custom_Fields
    Hashtable of custom field values to set (cf_<name>).

.EXAMPLE
    New-NBIPAMRIR

    Creates a new IPAM RIR object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function New-NBIPAMRIR {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Slug,
        [bool]$Is_Private,
        [string]$Description,
        [string[]]$Tags,
        [hashtable]$Custom_Fields,
        [switch]$Raw
    )
    process {
        Write-Verbose "Creating IPAM RIR"
        $Segments = [System.Collections.ArrayList]::new(@('ipam','rirs'))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Raw'
        if ($PSCmdlet.ShouldProcess($Name, 'Create RIR')) {
            InvokeNetboxRequest -URI (BuildNewURI -Segments $URIComponents.Segments) -Method POST -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
