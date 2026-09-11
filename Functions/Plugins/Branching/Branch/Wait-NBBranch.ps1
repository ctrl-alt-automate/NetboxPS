<#
.SYNOPSIS
    Waits for a Netbox branch to reach a target status.

.DESCRIPTION
    Polls a branch via the Netbox Branching plugin until it reaches a specified
    target status (default: 'ready'), fails, reaches a different terminal
    status, or the timeout is exceeded. Accepts pipeline input from New-NBBranch
    so you can provision a branch and block until it is safe to use, avoiding
    the race condition where a branched schema is queried before the plugin has
    finished provisioning it.

    Status lifecycle handled by this function:

    - Transitional (keep polling): new, provisioning, syncing, migrating,
      merging, reverting
    - Terminal "ok" (valid targets): ready, merged, archived
    - Terminal "working": pending-migrations (will fail fast if hit while
      waiting for another target)
    - Terminal failure: failed (always throws)

.PARAMETER Id
    The ID of the branch to wait on. Accepts pipeline input by property name,
    so a branch object from New-NBBranch binds automatically.

.PARAMETER Name
    The name of the branch to wait on. Resolved to an ID on the first poll.

.PARAMETER TargetStatus
    The status to wait for. Default: 'ready'. Valid values: 'ready', 'merged',
    'archived'.

.PARAMETER TimeoutSeconds
    Maximum number of seconds to wait before throwing a timeout error.
    Default: 120.

.PARAMETER PollIntervalMs
    Poll interval in milliseconds between status checks. Default: 1000.

.OUTPUTS
    [PSCustomObject] The fully-resolved branch object once it reaches the
    target status.

.EXAMPLE
    New-NBBranch -Name "feature/new-datacenter" | Wait-NBBranch | Enter-NBBranch

    Create a branch, wait until provisioning completes, then enter its context.

.EXAMPLE
    Sync-NBBranch -Id 42 -Confirm:$false
    Wait-NBBranch -Id 42 -TimeoutSeconds 300

    Sync a branch with main and wait up to 5 minutes for the sync to finish.

.EXAMPLE
    Merge-NBBranch -Id 42 -Confirm:$false
    Wait-NBBranch -Id 42 -TargetStatus merged

    Merge a branch and wait for the merge to complete.

.EXAMPLE
    New-NBBranch -Name 'probe' | Wait-NBBranch -Timeout 60 |
        Invoke-NBInBranch { Get-NBDCIMDevice }

    Provision a branch, wait for it, and immediately run a query inside it.

.LINK
    New-NBBranch
    Get-NBBranch
    Enter-NBBranch
    Sync-NBBranch
    Merge-NBBranch
.NOTES
    AddedInVersion: v4.5.7.0

#>
function Wait-NBBranch {
    [CmdletBinding(DefaultParameterSetName = 'ById')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'ById', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [Parameter(ParameterSetName = 'ByName', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [ValidateSet('ready', 'merged', 'archived')]
        [string]$TargetStatus = 'ready',

        [ValidateRange(1, 3600)]
        [int]$TimeoutSeconds = 120,

        [ValidateRange(100, 10000)]
        [int]$PollIntervalMs = 1000
    )

    begin {
        # Statuses during which we keep polling. 'new' is technically a terminal
        # "working" state per the plugin's taxonomy, but in practice a freshly
        # created branch lingers on 'new' for a few hundred ms before the worker
        # moves it to 'provisioning', so we treat it as transient.
        $transitionalStatuses = @(
            'new', 'provisioning', 'syncing', 'migrating', 'merging', 'reverting'
        )
    }

    process {
        CheckNetboxIsConnected

        Write-Verbose "Waiting for branch to reach status '$TargetStatus' (timeout: ${TimeoutSeconds}s, poll: ${PollIntervalMs}ms)"

        # Start with whichever identifier we were given; once we have the branch
        # object the first time, prefer Id-based polling because it's faster and
        # avoids a potential name collision.
        $currentId = if ($PSCmdlet.ParameterSetName -eq 'ById') { $Id } else { $null }
        $currentName = if ($PSCmdlet.ParameterSetName -eq 'ByName') { $Name } else { $null }

        $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
        $hasSeenBranch = $false
        $lastStatus = $null

        while ($true) {
            # Fetch current state
            $branch = $null
            $fetchError = $null
            try {
                if ($currentId) {
                    $branch = Get-NBBranch -Id $currentId -ErrorAction Stop
                }
                else {
                    $branch = Get-NBBranch -Name $currentName -ErrorAction Stop | Select-Object -First 1
                }
            }
            catch {
                $fetchError = $_
            }

            $identifier = if ($currentName) { $currentName } else { $currentId }

            if ($fetchError -or -not $branch) {
                if (-not $hasSeenBranch) {
                    $detail = if ($fetchError) { ": $($fetchError.Exception.Message)" } else { "" }
                    throw "Branch '$identifier' not found$detail"
                }
                throw "Branch '$identifier' was removed while waiting for status '$TargetStatus' (last observed: '$lastStatus')."
            }

            if (-not $hasSeenBranch) {
                $hasSeenBranch = $true
                # Lock in id + name for subsequent polls
                $currentId = [uint64]$branch.id
                $currentName = [string]$branch.name
            }

            $currentStatus = $branch.status.value
            $lastStatus = $currentStatus
            Write-Verbose "Branch '$currentName' (id=$currentId) status: $currentStatus"

            # Target reached - return the fully-resolved branch object.
            if ($currentStatus -eq $TargetStatus) {
                Write-Verbose "Branch '$currentName' reached target status '$TargetStatus'"
                return $branch
            }

            # Terminal failure - surface plugin-reported errors if present.
            if ($currentStatus -eq 'failed') {
                $errorDetail = if ($branch.errors) {
                    " Details: $(@($branch.errors) -join '; ')"
                }
                else {
                    ""
                }
                throw "Branch '$currentName' entered 'failed' state while waiting for '$TargetStatus'.$errorDetail"
            }

            # Still transitional - sleep and poll again.
            if ($currentStatus -in $transitionalStatuses) {
                if ((Get-Date) -ge $deadline) {
                    throw "Timed out after $TimeoutSeconds seconds waiting for branch '$currentName' to reach status '$TargetStatus' (last observed: '$lastStatus')."
                }
                Start-Sleep -Milliseconds $PollIntervalMs
                continue
            }

            # Any other terminal status (ready/merged/archived/pending-migrations)
            # that isn't our target means we'll never reach it - fail fast rather
            # than burn the whole timeout.
            throw "Branch '$currentName' is in terminal status '$currentStatus', cannot reach target '$TargetStatus'."
        }
    }
}
