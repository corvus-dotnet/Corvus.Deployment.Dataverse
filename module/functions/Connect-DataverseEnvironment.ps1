# <copyright file="Connect-Dataverse" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

function Connect-DataverseEnvironment
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $TenantId,

        [Parameter(Mandatory = $true)]
        [string] $EnvironmentUrl,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $SolutionName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $SchemaPrefix,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $Scope = "user_impersonation",

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $ApiVersion = "v9.2",

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $ClientId = "51f81489-12ee-4a9e-aaae-a2591f45987d"
    )


    if ($script:dataverseAccessToken -ne $null)
    {
        Write-Host "Using existing Dataverse connection" -f Green
        return
    }

    # A reasonably convenient way to get access to the Azure.Identity libaries
    # so we can handle the Entra ID authentication
    Import-Module MSAL.PS

    $safeEnvironmentUrl = $EnvironmentUrl.TrimEnd('/')

    $options = [Microsoft.Identity.Client.PublicClientApplicationOptions]@{
        ClientId = $ClientId
        TenantId = $TenantId
        # AadAuthorityAudience = [Microsoft.Identity.Client.AadAuthorityAudience]::AzureAdMultipleOrgs
        RedirectUri = "http://localhost"
    }
    $publicClientApp = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::CreateWithApplicationOptions($options).Build()

    $authScope = "$safeEnvironmentUrl/$Scope"
    $baseType = [System.Collections.Generic.List`1]
    $genericType = $baseType.MakeGenericType(@([System.String]))
    $scopes = New-Object $genericType
    $scopes.Add($authScope)

    # Acquire the token
    # TODO: Support other auth methods
    $authResult = $publicClientApp.AcquireTokenInteractive($scopes).ExecuteAsync().Result

    $script:solutionName = $SolutionName
    $script:dataverseEnvironmentUrl = "$safeEnvironmentUrl/api/data/$ApiVersion"
    $script:dataverseAccessToken = $authResult.AccessToken | ConvertTo-SecureString -AsPlainText

    Set-DataverseSchemaPrefix -Prefix $SchemaPrefix
}