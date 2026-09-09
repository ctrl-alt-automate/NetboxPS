<#
.SYNOPSIS
    Normalises a -Tags / -Add / -Remove value into what the Netbox API accepts for tag references.
.DESCRIPTION
    Netbox resolves related objects in a request body only from a numeric ID or from a dictionary of
    attributes; a bare tag name string is rejected with
    "Related objects must be referenced by numeric ID or by dictionary of attributes".
    This helper turns numeric strings into IDs and other strings into @{ name = '<tag>' }, and passes
    hashtables / objects (already attribute dictionaries) through unchanged, so every cmdlet that
    documents "tag names or IDs" really accepts both.
.PARAMETER Tags
    The raw values as bound to the cmdlet parameter.
.OUTPUTS
    [object[]] Tag references safe to serialise into the request body.
.EXAMPLE
    ConvertToNBTagReference -Tags 'web', 12, @{ slug = 'prod' }
    # -> @{ name = 'web' }, 12, @{ slug = 'prod' }
.NOTES
    AddedInVersion: v4.7.1.0
    Internal helper (not exported in production builds).
#>
function ConvertToNBTagReference {
    [CmdletBinding()]
    [OutputType([object[]])]
    param (
        [AllowNull()]
        [AllowEmptyCollection()]
        [object[]]$Tags
    )

    if ($null -eq $Tags) { return , @() }

    # NOTE: '-is [PSCustomObject]' is true for ANY PSObject-wrapped value (including strings),
    # so test strings and numbers explicitly and let everything else pass through unchanged.
    $refs = foreach ($tag in $Tags) {
        if ($null -eq $tag) { continue }
        if ($tag -is [string]) {
            if ($tag -match '^\d+$') { [uint64]$tag } else { @{ name = $tag } }
        }
        elseif ($tag -is [ValueType]) {
            [uint64]$tag
        }
        else {
            $tag
        }
    }
    return , @($refs)
}
