
function BuildURIComponents {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$URISegments,

        [Parameter(Mandatory = $true)]
        [object]$ParametersDictionary,

        [string[]]$SkipParameterByName
    )

    Write-Verbose "Building URI components"

    $URIParameters = @{
    }

    foreach ($CmdletParameterName in $ParametersDictionary.Keys) {
        if ($CmdletParameterName -in $script:CommonParameterNames) {
            # These are common parameters and should not be appended to the URI
            Write-Debug "Skipping common parameter $CmdletParameterName"
            continue
        }

        if ($CmdletParameterName -in $SkipParameterByName) {
            Write-Debug "Skipping parameter $CmdletParameterName by SkipParameterByName"
            continue
        }

        switch ($CmdletParameterName) {
            "id" {
                # Check if there is one or more values for Id and build a URI or query as appropriate
                if (@($ParametersDictionary[$CmdletParameterName]).Count -gt 1) {
                    Write-Verbose " Joining IDs for parameter"
                    $URIParameters['id__in'] = $ParametersDictionary[$CmdletParameterName] -join ','
                } else {
                    Write-Verbose " Adding ID to segments"
                    [void]$uriSegments.Add($ParametersDictionary[$CmdletParameterName])
                }

                break
            }

            'Query' {
                Write-Warning "The -Query parameter can be slow on large datasets. Consider using specific filters like -Name for better performance."
                Write-Verbose " Adding query parameter"
                $URIParameters['q'] = $ParametersDictionary[$CmdletParameterName]
                break
            }

            'Brief' {
                if ($ParametersDictionary[$CmdletParameterName]) {
                    Write-Verbose " Adding brief=True parameter for minimal response"
                    $URIParameters['brief'] = 'True'
                }
                break
            }

            'Fields' {
                $fieldList = $ParametersDictionary[$CmdletParameterName] -join ','
                Write-Verbose " Adding fields parameter: $fieldList"
                $URIParameters['fields'] = $fieldList
                break
            }

            'Omit' {
                $omitList = $ParametersDictionary[$CmdletParameterName] -join ','
                Write-Verbose " Adding omit parameter: $omitList"
                $URIParameters['omit'] = $omitList
                break
            }

            'CustomFields' {
                Write-Verbose " Adding custom field query parameters"
                $cfSensitivePatterns = @('secret', 'password', 'key', 'token', 'psk')
                foreach ($field in $ParametersDictionary[$CmdletParameterName].GetEnumerator()) {
                    $cfIsSensitive = $cfSensitivePatterns | Where-Object { $field.Key -match $_ }
                    $cfDisplayValue = if ($cfIsSensitive) { '***REDACTED***' } else { $field.Value }
                    Write-Verbose "  Adding parameter 'cf_$($field.Key) = $cfDisplayValue"
                    $URIParameters["cf_$($field.Key.ToLower())"] = $field.Value
                }

                break
            }

            { $_ -in @('Tags', 'Add_Tags', 'Remove_Tags') } {
                # Netbox only accepts numeric IDs or attribute dictionaries for tag references;
                # bare names become @{ name = ... } so "-Tags 'web', 12" works as documented.
                Write-Verbose " Adding $($CmdletParameterName.ToLower()) parameter (tag references)"
                $URIParameters[$CmdletParameterName.ToLower()] = ConvertToNBTagReference -Tags $ParametersDictionary[$CmdletParameterName]
                break
            }

            default {
                Write-Verbose " Adding $($CmdletParameterName.ToLower()) parameter"
                $URIParameters[$CmdletParameterName.ToLower()] = $ParametersDictionary[$CmdletParameterName]
                break
            }
        }
    }

    return @{
        'Segments' = [System.Collections.ArrayList]$URISegments
        'Parameters' = $URIParameters
    }
}