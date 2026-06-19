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
        }
    }
    else {
        Write-Verbose "NetboxConfig hashtable already exists"
    }
}
