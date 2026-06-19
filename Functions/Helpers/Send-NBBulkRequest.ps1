<#
.SYNOPSIS
    Sends bulk requests to the Netbox API.

.DESCRIPTION
    Helper function for bulk API operations. Handles batching, progress reporting,
    and partial failure handling for POST, PATCH, and DELETE operations.

    If a batch fails with a 500 Internal Server Error (which can occur due to Redis
    cache inconsistency when referencing newly created objects), the function
    automatically falls back to sequential single-item requests for that batch.

.PARAMETER URI
    The base URI for the API endpoint.

.PARAMETER Items
    Array of items to process in bulk.

.PARAMETER Method
    HTTP method (POST, PATCH, DELETE).

.PARAMETER BatchSize
    Maximum number of items per API request. Default: 100, Max: 1000.

.PARAMETER ShowProgress
    Show progress bar during bulk operations.

.PARAMETER ActivityName
    Name to display in the progress bar.

.PARAMETER MaxItems
    MaxItems.

.OUTPUTS
    [BulkOperationResult] Object containing succeeded and failed items.

.EXAMPLE
    $result = Send-NBBulkRequest -URI $uri -Items $devices -Method POST -BatchSize 50
.NOTES
    AddedInVersion: v4.4.10.0

#>

function Send-NBBulkRequest {
    [CmdletBinding()]
    [OutputType([BulkOperationResult])]
    param(
        [Parameter(Mandatory = $true)]
        [System.UriBuilder]$URI,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [array]$Items,

        [Parameter(Mandatory = $true)]
        [ValidateSet('POST', 'PATCH', 'DELETE')]
        [string]$Method,

        [ValidateRange(1, 1000)]
        [int]$BatchSize = 100,

        [ValidateRange(1, 100000)]
        [int]$MaxItems = 10000,

        [switch]$ShowProgress,

        [string]$ActivityName = 'Bulk operation'
    )

    $result = [BulkOperationResult]::new()

    if ($Items.Count -eq 0) {
        $result.Complete()
        return $result
    }

    if ($Items.Count -gt $MaxItems) {
        throw "Item count $($Items.Count) exceeds maximum allowed $MaxItems. Use -MaxItems to override."
    }

    # Split items into batches
    $batches = [System.Collections.ArrayList]::new()
    for ($i = 0; $i -lt $Items.Count; $i += $BatchSize) {
        $batch = $Items[$i..([Math]::Min($i + $BatchSize - 1, $Items.Count - 1))]
        [void]$batches.Add($batch)
    }

    $totalBatches = $batches.Count
    $currentBatch = 0

    Write-Verbose "Processing $($Items.Count) items in $totalBatches batch(es) of max $BatchSize"

    foreach ($batch in $batches) {
        $currentBatch++

        if ($ShowProgress) {
            $percentComplete = [int](($currentBatch / $totalBatches) * 100)
            $progressParams = @{
                Activity         = $ActivityName
                Status           = "Batch $currentBatch of $totalBatches ($($batch.Count) items)"
                PercentComplete  = $percentComplete
                CurrentOperation = "$Method request"
            }
            Write-Progress @progressParams
        }

        try {
            Write-Verbose "[$currentBatch/$totalBatches] Sending batch of $($batch.Count) items"

            # For bulk operations, we send an array directly
            $response = InvokeNetboxRequest -URI $URI -Method $Method -Body $batch -Raw

            # Process response - Netbox returns an array of results for bulk operations
            if ($response -is [array]) {
                foreach ($item in $response) {
                    if ($item.id) {
                        $result.AddSuccess($item)
                    }
                    else {
                        # Item failed validation but request succeeded
                        $errorMsg = if ($item.error) { $item.error } else { "Unknown error" }
                        $result.AddFailure($item, $errorMsg)
                    }
                }
            }
            elseif ($response.id) {
                # Single item response (shouldn't happen in bulk, but handle it)
                $result.AddSuccess($response)
            }
            elseif ($null -eq $response -and $Method -eq 'DELETE') {
                # DELETE operations return null on success
                foreach ($item in $batch) {
                    $result.AddSuccess($item)
                }
            }
            else {
                # Unexpected response format
                Write-Warning "Unexpected response format from bulk $Method request"
                foreach ($item in $batch) {
                    $result.AddSuccess($item)
                }
            }
        }
        catch {
            $errorMessage = $_.Exception.Message

            # Check if this is a 500 Internal Server Error
            # This can occur due to Redis cache inconsistency when referencing newly created objects
            if ($errorMessage -like "*500 Internal Server Error*") {
                Write-Warning "Batch $currentBatch failed with 500 Server Error. Retrying $($batch.Count) items sequentially with exponential backoff..."

                # Wait before retrying to allow Redis cache to sync (longer initial delay)
                Start-Sleep -Seconds 3

                # Retry each item individually with exponential backoff
                $itemIndex = 0
                foreach ($item in $batch) {
                    $itemIndex++
                    $maxRetries = 3
                    $retryCount = 0
                    $success = $false

                    while (-not $success -and $retryCount -lt $maxRetries) {
                        try {
                            # Delay between items (exponential backoff on retry)
                            if ($itemIndex -gt 1 -or $retryCount -gt 0) {
                                $delay = [Math]::Pow(2, $retryCount) * 500  # 500ms, 1s, 2s
                                Start-Sleep -Milliseconds $delay
                            }

                            # Send single item (not as array) for sequential processing
                            $singleResponse = InvokeNetboxRequest -URI $URI -Method $Method -Body $item -Raw

                            if ($singleResponse.id) {
                                $result.AddSuccess($singleResponse)
                                $success = $true
                            }
                            elseif ($null -eq $singleResponse -and $Method -eq 'DELETE') {
                                $result.AddSuccess($item)
                                $success = $true
                            }
                            else {
                                $result.AddFailure($item, "Unexpected response in sequential fallback")
                                $success = $true  # Don't retry on unexpected format
                            }
                        }
                        catch {
                            $retryCount++
                            if ($retryCount -ge $maxRetries) {
                                $result.AddFailure($item, $_.Exception.Message)
                            }
                            else {
                                Write-Verbose "Sequential item $itemIndex failed (attempt $retryCount/$maxRetries), retrying..."
                            }
                        }
                    }
                }
            }
            else {
                # Other errors (400, 403, etc.) - fail the batch as usual
                Write-Warning "Batch $currentBatch failed: $errorMessage"

                foreach ($item in $batch) {
                    $result.AddFailure($item, $errorMessage)
                }
            }
        }
    }

    if ($ShowProgress) {
        Write-Progress -Activity $ActivityName -Completed
    }

    $result.Complete()
    Write-Verbose $result.GetSummary()

    return $result
}
