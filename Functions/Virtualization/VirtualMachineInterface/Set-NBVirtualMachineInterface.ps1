<#
.SYNOPSIS
    Updates an existing irtualMachineInterface in Netbox V module.

.DESCRIPTION
    Updates an existing irtualMachineInterface in Netbox V module.
    Supports pipeline input for Id parameter where applicable.

.PARAMETER Raw
    Return the raw API response instead of the results array.

.PARAMETER Id
    Database ID of the object to update.

.PARAMETER Name
    Name of the object.

.PARAMETER MAC_Address
    MAC address.

.PARAMETER MTU
    MTU.

.PARAMETER Description
    Brief description.

.PARAMETER Enabled
    Whether the object is enabled.

.PARAMETER Virtual_Machine
    Virtual machine assigned to this object (database ID).

.PARAMETER Force
    Skip the confirmation prompt.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    Set-NBVirtualMachineInterface

    Updates an existing Virtual Machine Interface object.

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v1.0.4

#>

function Set-NBVirtualMachineInterface {
    [CmdletBinding(ConfirmImpact = 'Medium',
                   SupportsShouldProcess = $true)]
    [OutputType([pscustomobject])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$MAC_Address,

        [uint16]$MTU,

        [string]$Description,

        [boolean]$Enabled,

        [uint64]$Virtual_Machine,

        [switch]$Force,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        foreach ($VMI_ID in $Id) {
            Write-Verbose "Updating VM Interface ID $VMI_ID"

            $Segments = [System.Collections.ArrayList]::new(@('virtualization', 'interfaces', $VMI_ID))

            if ($Force -or $PSCmdlet.ShouldProcess("VM Interface ID $VMI_ID", "Set")) {
                $URIComponents = BuildURIComponents -URISegments $Segments -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'Force'

                $URI = BuildNewURI -Segments $URIComponents.Segments

                InvokeNetboxRequest -URI $URI -Body $URIComponents.Parameters -Method PATCH -Raw:$Raw
            }
        }
    }
}
