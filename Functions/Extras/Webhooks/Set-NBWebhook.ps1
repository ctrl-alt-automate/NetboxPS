<#
.SYNOPSIS
    Updates an existing webhook in Netbox.

.DESCRIPTION
    Updates an existing webhook in Netbox Extras module.

.PARAMETER Id
    The ID of the webhook to update.

.PARAMETER Name
    Name of the webhook.

.PARAMETER Payload_Url
    URL to send webhook payload to.

.PARAMETER Description
    Description of the webhook.

.PARAMETER Http_Method
    HTTP method (GET, POST, PUT, PATCH, DELETE).

.PARAMETER Http_Content_Type
    HTTP content type.

.PARAMETER Additional_Headers
    Additional HTTP headers.

.PARAMETER Body_Template
    Body template (Jinja2).

.PARAMETER Secret
    Secret for HMAC signature. Use SecureString for security.
    Example: $secret = ConvertTo-SecureString "my-secret" -AsPlainText -Force

.PARAMETER Ssl_Verification
    Whether to verify SSL certificates.

.PARAMETER Ca_File_Path
    Path to CA certificate file.

.PARAMETER Custom_Fields
    Custom fields hashtable.

.PARAMETER Raw
    Return the raw API response.

.PARAMETER Tags
    One or more tags to assign to this object (tag names or IDs).

.EXAMPLE
    Set-NBWebhook -Id 1 -Ssl_Verification $true

.LINK
    https://netbox.readthedocs.io/en/stable/rest-api/overview/
.NOTES
    AddedInVersion: v4.4.10.0

#>
function Set-NBWebhook {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [uint64]$Id,

        [string]$Name,

        [string]$Payload_Url,

        [string]$Description,

        [ValidateSet('GET', 'POST', 'PUT', 'PATCH', 'DELETE')]
        [string]$Http_Method,

        [string]$Http_Content_Type,

        [string]$Additional_Headers,

        [string]$Body_Template,

        [securestring]$Secret,

        [bool]$Ssl_Verification,

        [string]$Ca_File_Path,

        [hashtable]$Custom_Fields,


        [object[]]$Tags,

        [switch]$Raw
    )

    process {
        Write-Verbose "Updating Webhook"
        $Segments = [System.Collections.ArrayList]::new(@('extras', 'webhooks', $Id))
        $URIComponents = BuildURIComponents -URISegments $Segments.Clone() -ParametersDictionary $PSBoundParameters -SkipParameterByName 'Id', 'Raw', 'Secret'
        $URI = BuildNewURI -Segments $URIComponents.Segments

        # Convert SecureString secret to plaintext for API
        if ($PSBoundParameters.ContainsKey('Secret')) {
            $URIComponents.Parameters['secret'] = [System.Net.NetworkCredential]::new('', $Secret).Password
        }

        if ($PSCmdlet.ShouldProcess($Id, 'Update Webhook')) {
            InvokeNetboxRequest -URI $URI -Method PATCH -Body $URIComponents.Parameters -Raw:$Raw
        }
    }
}
