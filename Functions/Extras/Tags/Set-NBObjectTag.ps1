<#
.SYNOPSIS
    Adds and/or removes tags on any Netbox object without replacing its whole tag list.
.DESCRIPTION
    Netbox 4.6+ accepts 'add_tags' and 'remove_tags' in a PATCH request (partial tag assignment), so a
    tag can be added or removed without first reading and resending the complete 'tags' array - which
    is both faster and safe against a concurrent edit of the other tags.

    Pass the object itself (any Get-NB* result; its 'url' property identifies it) or the object's API
    path. The request is always sent to the configured Netbox host - only the path of the object URL is
    used - so a proxied or renamed host in the object URL cannot redirect the request.

    Tags may be given as IDs or names. Older Netbox versions silently ignore add_tags/remove_tags, so
    on a server below 4.6 this cmdlet throws instead of pretending to succeed.
.PARAMETER InputObject
    The Netbox object (from any Get-NB* cmdlet, pipeline supported). Must carry a 'url' property.
.PARAMETER Url
    The object's API URL or path instead of an object, e.g. '/api/dcim/devices/42/'.
.PARAMETER Add
    Tags to add (IDs or names). Tags the object already carries are left untouched.
.PARAMETER Remove
    Tags to remove (IDs or names). Tags the object does not carry are ignored.
.PARAMETER Raw
    Return the raw API response.
.EXAMPLE
    Get-NBDCIMDevice -Name 'core-01' | Set-NBObjectTag -Add 'maintenance'

    Adds the 'maintenance' tag to the device, keeping its other tags.
.EXAMPLE
    Get-NBDCIMDevice -Tag 'maintenance' | Set-NBObjectTag -Remove 'maintenance' -Add 12

    Swaps the 'maintenance' tag for tag ID 12 on every matching device.
.EXAMPLE
    Set-NBObjectTag -Url '/api/ipam/prefixes/7/' -Add 'audited'
.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.7.1.0
    Requires Netbox 4.6+ (netbox-community/netbox#21771).
#>
function Set-NBObjectTag {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium', DefaultParameterSetName = 'ByObject')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ByObject')]
        [PSObject]$InputObject,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByUrl')]
        [ValidateNotNullOrEmpty()]
        [string]$Url,

        [object[]]$Add,

        [object[]]$Remove,

        [switch]$Raw
    )

    begin {
        if (-not $Add -and -not $Remove) {
            throw "Specify -Add and/or -Remove."
        }
        CheckNetboxIsConnected
        if ($script:NetboxConfig.ParsedVersion -and $script:NetboxConfig.ParsedVersion -lt [version]'4.6.0') {
            throw "Partial tag assignment (add_tags/remove_tags) requires Netbox 4.6.0 or higher (connected to $($script:NetboxConfig.ParsedVersion)). Older servers silently ignore these fields, so this cmdlet refuses rather than pretending to succeed."
        }

        $body = @{}
        if ($Add) { $body['add_tags'] = ConvertToNBTagReference -Tags $Add }
        if ($Remove) { $body['remove_tags'] = ConvertToNBTagReference -Tags $Remove }
    }

    process {
        $target = if ($PSCmdlet.ParameterSetName -eq 'ByUrl') { $Url } else { $InputObject.url }
        if (-not $target) {
            throw "The input object has no 'url' property; pass a Get-NB* result or use -Url."
        }

        # Only the path is taken from the object URL; host/scheme/port come from the active connection.
        $path = if ($target -match '^https?://') { ([System.Uri]$target).AbsolutePath } else { $target }
        $segments = [System.Collections.ArrayList]::new(@($path -split '/' | Where-Object { $_ -and $_ -ne 'api' }))
        if ($segments.Count -lt 3) {
            throw "'$target' does not look like a Netbox object URL (expected /api/<app>/<endpoint>/<id>/)."
        }

        $uri = BuildNewURI -Segments $segments
        $display = if ($InputObject -and $InputObject.display) { $InputObject.display } else { $path }
        Write-Verbose "Partial tag update on $path (add: $($Add -join ', '); remove: $($Remove -join ', '))"
        if ($PSCmdlet.ShouldProcess($display, 'Update tags')) {
            InvokeNetboxRequest -URI $uri -Method PATCH -Body $body -Raw:$Raw
        }
    }
}
