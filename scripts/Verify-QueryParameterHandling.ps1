#Requires -Version 7
<#
    .SYNOPSIS
        Check that the configuration map for the special handling of query parameters is up to date with the current API version.

    .DESCRIPTION
        Validate that every Get-NB* function declaring -Brief, -Fields, and -O

    .PARAMETER Url
        The URL to the API schema endpoint. Default is 'http://localhost:8000/api/schema/?format=json'.

    .PARAMETER NetboxVersion
        The expected NetBox version to validate against. If not provided, the version from the API schema will be used for validation
        If provided, it will be checked against the API schema version. If they are not equal, a warning will be issued, because this may lead to inaccurate validation results.

    .PARAMETER PathProjectRoot
        The path to the project root, used to load the module and the definition file.

    .PARAMETER OutputFormat
        The format for the output of the findings. Default is 'ConsoleList'. Possible values are 'ConsoleList', 'ConsoleTable', 'Json', and 'Object'.

    .PARAMETER QueryParameterHash
        Verify against this definition hashtable. Default is taken from 'Functions/Helpers/_IgnoreCaseParameters.ps1' depending on the API version.
        It must reflect the API version and the corresponding check to be done.
        We use this parameter for testing the script itself to test against different scenarios.

    .PARAMETER Check
        The type of check to perform. Default is 'IgnoreCase'. Possible values are 'IgnoreCase', 'Regex', 'IgnoreCaseRegex', and 'FunctionNames'.

    .PARAMETER ApiSchema
        Provide the API schema as a PSObject. If not provided, the script will fetch it from the API schema endpoint.
        We use this in the tests to provide a mock API schema for testing different scenarios.
        For validation against the current running module and API, leave it $null.

    .NOTES
        The parameter/exception list is based on the API v4.4.9 list of fully supported case-insensitive parameters, which is the minimum version
        supported by this module. The list is based on the API schema of NetBox.


#>
[CmdletBinding()]
param (
    [ValidateNotNullOrEmpty()]
    [string]$Hostname = $env:NETBOX_HOST,

    [ValidateSet('https', 'http')]
    [string]$Scheme = ($env:NETBOX_SCHEME ?? 'https' ),

    [ValidateNotNullOrEmpty()]
    [string] $NetboxVersion = $env:NETBOX_VERSION,

    [ValidateNotNullOrEmpty()]
    [string] $PathProjectRoot = (Join-Path -Path $PSScriptRoot -ChildPath '..'),

    [ValidateSet('ConsoleTable', 'ConsoleList', 'Json', 'Object')]
    [string] $OutputFormat = 'ConsoleTable',

    [hashtable] $QueryParameterHash = $null,

    [ValidateSet('IgnoreCase', 'Regex', 'IgnoreCaseRegex', 'FunctionNames')]
    [string] $Check = 'IgnoreCase',

    [PSObject] $ApiSchema = $null
)
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Stop'

function Get-QueryParameterHashToCheck {
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [string] $PathDefinitionFile,

        [ValidateNotNullOrEmpty()]
        [string] $ApiVersion,

    [ValidateSet('All','IgnoreCase', 'Regex', 'IgnoreCaseRegex', 'FunctionNames')]
        [string] $Check
    )
}

function Get-DerivedFunctionNameFromEndpoint {
    param (
        [string] $endpoint
    )
    # PS functions are usually singular, while API endpoints are plural and end with an 's/' or s/{id}/.
    $match = $endpoint -match '^(\/api\/)(?<functgroup>[a-z\-]+)\/*(?<function>[a-z\-]+)(\/)((?<isIdRequest>{id})(\/)){0,1}$'
    if ($match) {
        $functionGroup = $Matches['functgroup']
        $functionName = $Matches['function']
        $isIdRequest = $Matches['isIdRequest']

        # now handle the exeptions
        switch -Regex ($endpoint) {
            '\/api/authentication-check\/' {
                   $functionName = "AuthenticationChecks"      # s -> ''
                   break
            }
             'circuits\/(providers|provider-(accounts|networks))\/' {
                 $functionName = "Circuit" + $functionName
                 break
             }
             'virtualization\/(interfaces|Type)\/' {
                 $functionName = "VirtualMachine" + $functionName
                 break
             }
             'virtualization\/(clusters|cluster-groups|cluster-types)\/' {
                 $functionName = "Virtualization" + $functionName
                 break
             }
             'extras\/dashboard\/' {
                 $functionName = "dashboards"  # s -> ''
                 break
             }
             'dcim\/connected-device\/' {
                 $functionName = "DcimConnectedDevices"  # s -> ''
                 break
             }
             'dcim\/mac-addresses\/' {
                 $functionName = "DcimMacAddresss"  # sss -> ss
                 break
             }
             'dcim\/virtual-chassis\/' {
                 $functionName = "DcimVirtualChassiss"  # ss -> s
                 break
             }
             'ipam\/ip-addresses\/' {
                 $functionName = "IpamAddresss"  # sss -> ss
                 break
             }
             'ipam\/ip-ranges\/' {
                 $functionName = "IpamAddressRanges"     # ss -> s
                 break
             }
             'ipam\/prefixes\/' {
                 $functionName = "IpamPrefixs"  # s -> ''
                 break
             }
             '\/(dcim|vpn|ipam)\/.+\/' {
                 $functionName = $functionGroup + $functionName
                 break
                }
                'users\/config\/' {
                    $functionName = "configs"  # s -> ''
                    break
                }
         }


        $derivedFunctionName = 'Get-NB' + $functionName.Trim().Replace('-', '')
        if ($derivedFunctionName.EndsWith('ies')) {
            # special case for functions like Get-NBDeviceTypes which should be Get-NBDeviceType
            $derivedFunctionName = $derivedFunctionName.Substring(0, $derivedFunctionName.Length - 3) + 'y'
        } elseif ($derivedFunctionName.EndsWith('s')) {
            $derivedFunctionName = $derivedFunctionName.Substring(0, $derivedFunctionName.Length - 1)
        } else {
            Write-Warning "Derived function name $derivedFunctionName ($endpoint)does not end with 's|ies'. This is unexpected for a GET function. Skipping."
        }
        [PSCustomObject] @{
            Name = $derivedFunctionName
            Group = $functionGroup
            IsIdRequest = $null -ne $isIdRequest
            EndPoint = $endpoint
        }
    }
}

function ConvertTo-ParameterDefiniton {
    param (
        $param
    )
    # split the parametername from the operator, for example 'name__ic' should be split into 'name' and 'ic'
    if ($param.name -match '^(?<paramName>[a-zA-Z0-9_]+?)(__(?<operator>[a-z]+))?$') {
        $paramName = $Matches['paramName']
        $operator = $Matches['operator']
        # $operator = $Matches['operator']
        # if ($null -eq $operator -and $paramName -in $paramWithNoOperator) {
        #     Write-Warning "Parameter $($param.name) for endpoint $endpoint is in the list of parameters with no operator. Skipping."
        #     continue
        # } elseif ($null -ne $operator -and $operator -notin $paramOperator) {
        #     Write-Warning "Parameter $($param.name) for endpoint $endpoint has an unrecognized operator: $operator. Skipping."
        #     continue
        # }
    } else {
        Write-Warning "Parameter name $($param.name) for endpoint $endpoint does not match expected pattern. Skipping."
        continue
    }
    $thisParam = [ordered] @{
        Name = $paramName
        IsFunctionParameter = $false
        IsArray = $param.schema.type -eq 'array'
        # ItemsType is valid only if IsArray is true. Set to the same as Type if as default to make validation easier later on.
        Type = $param.schema.type
        ItemsType = if ($param.schema.type -eq 'array') { $param.schema.items.type } else { $param.schema.type }
        MustCheck = $false
        IsPossibleArray = $false         # not a function param array, but the API allows multiple values
        Required = $param.required
        Operators = [System.Collections.Generic.List[string]]::new()
        ApiFilters = @{}
    }
    # if ($null -ne $operator) {
        $null = $thisParam.Operators.Add($operator)
    # }
    $thisParam
}

function Expand-FunctionAndParameterFromApiSchema {
    <#
        provides a full list each consisting of endpoint, estimated functionname, parameter, operator, and type for all combinations of endpoints, parameters, and operators.
        This is useful for a full validation of the functions and their parameters against the API schema.
    #>
    param (
        [Object] $schema,
        [string] $FunctionNameFilter,
        [string] $EndpointFilter,
        [switch] $ExpandOperators
    )
    foreach ($path in $schema.paths.PSObject.Properties) {
        $endpoint = $path.Name
        if ($endpoint -eq '/api/schema/') {
            Write-Debug "Skipping schema endpoint $endpoint"
            continue
        }
        if ('' -ne $EndpointFilter -and $endpoint -notlike $EndpointFilter) {
            Write-Debug "Endpoint $endpoint does not match filter $EndpointFilter. Skipping."
            continue
        }
        $derivedFunctionName = Get-DerivedFunctionNameFromEndpoint -endpoint $endpoint
        if ($null -eq $derivedFunctionName) {
            Write-Debug "Endpoint $endpoint does not match expected pattern for a Get function. Skipping."
            continue
        }
        if ('' -ne $FunctionNameFilter -and $derivedFunctionName.Name -notlike $FunctionNameFilter) {
            Write-Debug "Derived function name $($derivedFunctionName.Name) does not match filter $FunctionNameFilter. Skipping."
            continue
        }

        $method = $path.Value.get
        if ($null -eq $method) {
            Write-Debug "Endpoint $endpoint does not have a GET method defined. Skipping."
            continue
        }

        $parameterList = @{}            # this will contain the each parameter (without operator) as key
        foreach ($param in $method.parameters) {
            $convertedParam = ConvertTo-ParameterDefiniton -param $param
            if ($null -eq $convertedParam) {
                Write-Warning "Parameter $($param.name) for endpoint $endpoint could not be converted to a parameter definition. Skipping."
                Wait-Debugger
                continue
            }
            if ($parameterList.ContainsKey($convertedParam.Name)) {
                $thisParam = $parameterList[$convertedParam.Name]
            } else {
                $thisParam = [PSCustomObject] @{
                    FunctionName = $derivedFunctionName.Name
                    Parameter = $convertedParam.Name
                    Type = $convertedParam.Type
                    IsArray = $convertedParam.IsArray
                    ItemsType = $convertedParam.ItemsType
                    Operator = $null
                    Operators = [System.Collections.ArrayList]@()
                    Endpoint = $endpoint
                }
            }
            $null = $thisParam.Operators.AddRange($convertedParam.Operators)
            $parameterList[$convertedParam.Name] = $thisParam
        }
        $parameterList.Values
    }
}

function Expand-FunctionAndParameterFromModule {
    <#
        provides a full list each consisting of functionname, parameter, and type for all Get-NB* functions in the module.
        This is useful for a full validation of the functions and their parameters against the API schema.
    #>
    [CmdletBinding()]
    param (
        [string] $FunctionNameFilter
    )
    # these functions are not relevant for the validation, as they do not have query parameters
    $excludeFunctions = @('Get-NBApiSchema', 'Get-NBApiVersion')
    $excludeNonApiParameters = @(     # ignoring common parameters and params used for all functions not related to API filters
                'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ProgressAction',
                'WhatIf',  'Confirm', 'Force'
                'PipelineVariable', 'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable',
                'Limit', 'Offset', 'Fields', 'ExcludeFields', 'Expand', 'Search', 'Filter',
                'Query',            # Query currently is here, must be mapped to API parameter 'q'
                'PageSize', 'Brief', 'Omit', 'Raw', 'OutBuffer', 'All'
            )
    $splatGetCommand = @{
        Module = 'PowerNetbox'
    }
    if ('' -ne $FunctionNameFilter) {
        $splatGetCommand['Name'] = $FunctionNameFilter
    }
    $functions = Get-Command @splatGetCommand
    Write-Verbose "Found $($functions.Count) functions in module PowerNetbox matching filter $FunctionNameFilter."
    foreach ($fn in $functions) {
        if ($fn.Name -in $excludeFunctions) {
            Write-Debug "Function $($fn.Name) is in the list of excluded functions. Skipping."
            continue
        }
         Write-Debug "Processing function $($fn.Name)."
        $parameters = $fn.Parameters.Values
        foreach ($param in $parameters) {
            if ($param.Name -in $excludeNonApiParameters) {
                Write-Debug "Parameter $($param.Name) in function $($fn.Name) is in the list of non-API parameters. Skipping."
                continue
            }
            $thisParam = [PSCustomObject] @{
                FunctionName = $fn.Name
                Parameter = $param.Name
                Type = $param.ParameterType
                IsArray = ($param.ParameterType.ToString() -match '\[\]$'? $true : $false)
                ItemsType = $param.ParameterType.ToString() -replace('\[\]$', '')
                Operator = $null
                Operators = [System.Collections.ArrayList]@()
                Endpoint = ''
            }
            $thisParam
        }
    }
}

# We will use the currently loaded module for function definitions. If it is not loaded, we will load it from the project root.
if (-not (Get-Module -Name PowerNetbox)) {
    $psdPath = Join-Path -Path $PathProjectRoot -ChildPath 'PowerNetbox' -AdditionalChildPath 'PowerNetbox.psd1'
    if (-not (Test-Path -Path $psdPath)) {
        Write-Error "Module manifest not found: $psdPath"
        exit 1
    }
    Import-Module $psdPath -Force -ErrorAction Stop
}

    #region Read API schema and extract functions and query parameters
    if ($null -eq $ApiSchema) {
        $url = "$($Scheme)://$Hostname/api/schema/?format=json"
        $ApiSchema = Invoke-RestMethod -Uri $url -ContentType 'application/json'
        Write-Host "API schema version: $($ApiSchema.info.version)"
    }

    #region verify that the API schema version matches the expected version, if provided (e.g. should look like 4.5.10-Docker-4.0.2 (4.5))
    # only major and minor version are used for the validation, as patch versions should not introduce breaking changes.
    if (-Not ($apiSchema.info.version -match '^(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)')) {
        Write-Error "Failed to parse API schema version: $($apiSchema.info.version). Expected format like '^<major>.<minor>.<patch>.*'."
        exit 1
    }
    Try {
        $objApiVersion = [version]"$($Matches['major']).$($Matches['minor'])"
        if ([string]::IsNullOrEmpty($NetboxVersion)) {
            Write-Warning "Expected NetBox version not provided. Version from API will be used for validation: $($objApiVersion.ToString())."
            $objExpectedNetboxVersion = $objApiVersion
            $NetboxVersion = $objExpectedNetboxVersion.ToString()
        } else {
            $objExpectedNetboxVersion = [version]($NetboxVersion.StartsWith('v') ? $NetboxVersion.Substring(1) : $NetboxVersion)
        }
    }
    Catch {
        Write-Error "Failed to create version object from API schema version: $($apiSchema.info.version). Error: $_"
        exit 1
    }
    if ($objApiVersion -ne $objExpectedNetboxVersion) {
        Write-Warning "API schema version $($apiSchema.info.version) does not match expected NetBox version $NetboxVersion. This may lead to inaccurate validation results, as the list of supported parameters may differ between versions."
        $objApiVersion = $objExpectedNetboxVersion
    }
    #endregion

    $flatApiParameters = Expand-FunctionAndParameterFromApiSchema -schema $apiSchema
    $flatFunctionParameters = Expand-FunctionAndParameterFromModule
    #endregion

    #region Load the dictionary of query parameter handling for this scenario.
    if ($null -eq $QueryParameterHash) {
        # TODO: Currently untested for other scenerios
        . (Join-Path -Path $PathProjectRoot -ChildPath 'Functions' -AdditionalChildPath  'Helpers','_IgnoreCaseParameters.ps1')
        $thisVersionDict = $Script:IgnoreCaseParameterDictonary[$objApiVersion.tostring()]
        if ($null -eq $thisVersionDict) {
            $latestVersion = $Script:IgnoreCaseParameterDictonary.Keys | Sort-Object -Descending | Select-Object -First 1
            Write-Warning "No dictionary entry found for API version $($objApiVersion.tostring()). Testing against the latest known version $($latestVersion)."
            $findings.Add([pscustomobject]@{
                Finding = 'No dictionary entry for this API version'
                Data = "API version $($objApiVersion.tostring())."
            })
            $thisVersionDict = $Script:IgnoreCaseParameterDictonary[$latestVersion]
        }
        $QueryParameterHash = $thisVersionDict
    } else {
        $thisVersionDict = $QueryParameterHash
    }
    #endregion

    $findings = [System.Collections.Generic.List[object]]::new()

#region check for parameters that support __ie and build an exception list of endpoints, where a parameter is not supporting __ie
    # Parameters to check
    # Those supporting __ie at least once
    $objParamsSupporting__ie = $flatApiParameters | Where-Object { ($_.Operators -contains 'ie' -and $_.ItemsType -eq 'string') }
    $nameParamsSupporting__ie = $objParamsSupporting__ie | Select-Object -ExpandProperty Parameter | Sort-Object -Unique

    # Those supporting __ie, but would not support it in all endpoints (will need an exception list of those endpoints))
    # Possible reasons: somewhere used as [int] od as selection from a list of choices, which do not support __ie (and are case sensitive!)
    $objParamsSupporting__ie_Exceptions = $flatApiParameters | Where-Object { $_.Parameter -in $nameParamsSupporting__ie -and $_.Operators -notcontains 'ie' }
    $nameParamsSupporting__ie_Exceptions = $objParamsSupporting__ie_Exceptions | Select-Object -ExpandProperty Parameter | Sort-Object -Unique
    # Group by parameter to get the list of endpoints for each parameter that needs an exception list entry
    $grpParamsSupporting__ie_Exceptions = $objParamsSupporting__ie_Exceptions | Group-Object -Property Parameter

    #region Find those supporting __ie but would not support __regex or __iregex
    $objMissingRegexSupport = [System.Collections.Generic.List[object]]::new()
    foreach ($param in $objParamsSupporting__ie) {
        if ($param.Operators -notcontains 'regex' -or $param.Operators -notcontains 'iregex') {
            $objMissingRegexSupport.Add($param)
        }
        if ($param.Operators.Count -lt 4) {
            Write-Warning "Parameter $($param.Parameter) for endpoint $($param.Endpoint) supports regex operators but has less than 4 operators. This would be surprising."
            $objMissingRegexSupport.Add($param)
        }
    }
    if ($objMissingRegexSupport.Count -gt 0) {
        $toReport = [pscustomobject] @{
            Finding = 'Supports __ie, but not __regex or __iregex'
            Data = $objMissingRegexSupport
        }
        $findings.Add($toReport)
    }
    #endregion

    #region check against the dictionary for this API version

    # every parametername must have a corresponding entry
    $allParamNamesNotInDictionary = $nameParamsSupporting__ie | Where-Object { $_ -notin $thisVersionDict.Keys }
    if ($allParamNamesNotInDictionary.Count -gt 0) {
        # Report only the first occurence for each parameter
        foreach ($pName in $allParamNamesNotInDictionary) {
            $firstOccurence = $objParamsSupporting__ie | Where-Object { $_.Parameter -eq $pName } | Select-Object -First 1
            $toReport = [pscustomobject] @{
                Finding = 'not in dictionary'
                Data = $firstOccurence
            }
            $findings.Add($toReport)
        }
    }

    # every dictionary entry must have a corresponding parametername
    $allParamNamesNotInApi = $thisVersionDict.Keys | Where-Object {
        $_ -notin $nameParamsSupporting__ie
    }
    if ($allParamNamesNotInApi.Count -gt 0) {
        $toReport = [pscustomobject] @{
            Finding = 'Dictionary entry without corresponding parametername'
            Data = $allParamNamesNotInApi
        }
        $findings.Add($toReport)
    }

    # every parametername which has an exception list must have a non-empty array of endpoints in the dictionary containing each endpoint,
    # where the parameter does not support __ie
    $missingExceptionList = foreach ($param in $nameParamsSupporting__ie_Exceptions) {
        if (-not $thisVersionDict.ContainsKey($param)) {
            $exceptionListInDict = @()
        } else {
            $exceptionListInDict = $thisVersionDict[$param]
        }
        $exceptionListInApi = $grpParamsSupporting__ie_Exceptions | Where-Object { $_.Name -eq $param } | Select-Object -ExpandProperty Group
        foreach ($param in $exceptionListInApi) {
            foreach ($endpoint in $param.Endpoint) {
                # endpoints in the dictionary are stored without the leading slash, because that's how they are checked inside 'BuildNewURI'
                $endpoint = $endpoint.TrimStart('/')
                if ($endpoint -notin $exceptionListInDict) {
                    $thisEndpointData = $param
                    $thisEndpointData.Endpoint = $endpoint              # report each endpoint separately
                    $thisEndpointData
                }
            }
        }
    }
    if ($missingExceptionList.Count -gt 0) {
        foreach ($item in ($missingExceptionList | Sort-Object Parameter, endpoint)) {
            $toReport = [pscustomobject] @{
                Finding = 'missing in exception list'
                Data = $item
            }
            $findings.Add($toReport)
        }
    }

    # every parametername which is fully supporting __ie must have an empty array of endpoints in the dictionary, as there are no exceptions
    $allParamNamesFullySupporting__ie = $nameParamsSupporting__ie | Where-Object { $_ -notin $nameParamsSupporting__ie_Exceptions }
    $nonEmptyExceptionList = foreach ($param in $allParamNamesFullySupporting__ie) {
        if (-not $thisVersionDict.ContainsKey($param)) {
            continue            # will be reported in another check
        }
        $exceptionListInDict = $thisVersionDict[$param]
        if ($exceptionListInDict.Count -gt 0) {
            $param
        }
    }
    if ($nonEmptyExceptionList.Count -gt 0) {
        $toReport = [pscustomobject] @{
            Finding = 'exception list not empty'
            Data = $nonEmptyExceptionList
        }
        $findings.Add($toReport)
    }
    #endregion

    #region function checks
    # every derived function name should exist in the module
    $derivedFunctionNames = $flatApiParameters | Select-Object -ExpandProperty FunctionName | Sort-Object -Unique
    $functionNamesInModule = $flatFunctionParameters | Select-Object -ExpandProperty FunctionName | Sort-Object -Unique
    $derivedFunctionNamesNotInModule = $derivedFunctionNames | Where-Object { $_ -notin $functionNamesInModule } | Sort-Object -Unique
    if ($derivedFunctionNamesNotInModule.Count -gt 0) {
        foreach ($fn in $derivedFunctionNamesNotInModule) {
            $toReport = [pscustomobject] @{
                Finding = 'function name not found in module'
                Data = [PSCustomObject] @{
                    FunctionName = $fn
                }
            }
            $findings.Add($toReport)
        }
    }
    #endregion
#endregion

switch -regex ($OutputFormat) {
    'ConsoleList|ConsoleTable' {
        $outputObject = $findings.GetEnumerator() | Foreach-Object {
            $f = $_
            foreach ($item in $f.Data) {
                if ($item -is [string]) {
                    [PSCustomObject] @{
                        Finding = $f.Finding
                        FunctionName = '_IgnoreCaseParameters.ps1'
                        Parameter = $item
                        Type = ''
                        IsArray = $null
                        ItemsType = ''
                        Operators = ''
                        Endpoint = ''
                    }
                } else {
                    [PSCustomObject] @{
                        Finding = $f.Finding
                        FunctionName = $item.FunctionName
                        Parameter = $item.Parameter
                        Type = $item.Type
                        IsArray = $item.IsArray
                        ItemsType = $item.ItemsType
                        Operators = ($item.Operators -join ',')
                        Endpoint = $item.Endpoint
                    }
                }
            }
        }
        if ($OutputFormat -eq 'ConsoleList') {
            $outputObject | Format-List
        } else {
            $outputObject | Format-Table -AutoSize
        }
        break
    }
    'Json' {
        $findings | ConvertTo-Json -Depth 5
    }
    'Object' {
        $findings
    }
}

$ErrorActionPreference = $previousErrorActionPreference