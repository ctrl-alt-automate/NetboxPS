function SetupNetboxConfigVariable {
    [CmdletBinding()]
    param
    (
        [switch]$Overwrite
    )

    Write-Verbose "Checking for NetboxConfig hashtable"
    if ((-not ($script:NetboxConfig)) -or $Overwrite) {
        Write-Verbose "Creating Netbox Config hashtable"
        $script:NetboxConfig = @{
            'Connected'     = $false
            'Hostname'      = $null
            'Credential'    = $null
            'HostScheme'    = $null
            'HostPort'      = $null
            'InvokeParams'  = $null
            'Timeout'       = $null
            'NetboxVersion' = $null
            'ParsedVersion' = $null
            'BranchStack'   = [System.Collections.Generic.Stack[object]]::new()
            'IgnoreCaseInQueries' = $false
            'MatchMode'     = 'Exact'
            'Pagination'    = 'Offset'      # Set-NBQueryOption -Pagination Offset|Cursor (Netbox 4.6+ ?start=)
            'TagMatch'      = 'All'         # Set-NBQueryOption -TagMatch All|Any   (Netbox 4.6.6+ tag__any)
            'OptimisticConcurrency' = $false  # Set-NBQueryOption -OptimisticConcurrency (Netbox 4.6+ ETag/If-Match)
            'ETagCache'     = @{}           # object URL -> last seen ETag (only used with OptimisticConcurrency)
            'DeprecationWarned' = @{}       # warning text -> $true, so each deprecation is reported once per connection
        }
    }
    else {
        Write-Verbose "NetboxConfig hashtable already exists"
    }
}
