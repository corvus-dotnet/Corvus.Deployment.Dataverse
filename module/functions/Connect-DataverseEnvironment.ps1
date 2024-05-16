# <copyright file="Connect-Dataverse" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

<#
.SYNOPSIS
Obtains an access token for the Dataverse environment.

.DESCRIPTION
Obtains an access token for the Dataverse environment that is used for other operations.

.PARAMETER TenantId
The Power Apps Tenant ID.

.PARAMETER EnvironmentUrl
The Power Apps environment URL.

.PARAMETER SolutionName
The Power Apps solution name.

.PARAMETER SchemaPrefix
The schema prefix to be used when deploying Dataverse table definitions.

.PARAMETER Scope
The authentication scope.

.PARAMETER ApiVersion
The Dataverse REST API version.

.PARAMETER ClientId
The Azure AD application client ID used to authenticate.

#>
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

    # Acquire the token for CI/CD scenarios
    if ($env:AZURE_CLIENT_ID -and $env:AZURE_CLIENT_SECRET -and $env:AZURE_TENANT_ID)
    {
        Write-Host "Attemping authentication via environment variables [ClientId=$env:AZURE_CLIENT_ID]"
        $authResult = Get-MsalToken -ClientId $env:AZURE_CLIENT_ID `
                                    -Scopes "$safeEnvironmentUrl/.default" `
                                    -TenantId $env:AZURE_TENANT_ID `
                                    -ClientSecret ($env:AZURE_CLIENT_SECRET | ConvertTo-SecureString -AsPlainText)
    }
    else {
        # Acquire the token via Azure CLI authentication
        $azCliAvailable = Get-Command az -ErrorAction Ignore
        if ($azCliAvailable) {
            $azCliTokenExpiry = & az account get-access-token --query expiresOn -o tsv
            if ($azCliTokenExpiry -and [DateTime]::Parse($azCliTokenExpiry) -gt [DateTime]::UtcNow) {
                Write-Host "Attemping authentication via Azure CLI"
                $authResult = & az account get-access-token `
                                    --resource $safeEnvironmentUrl | ConvertFrom-Json
            }
        }

        if (!$authResult) {
            # Acquire token interactively
            Write-Host "Triggering interactive authentication"
            $authResult = Get-MsalToken -ClientId $ClientId `
                                        -TenantId $TenantId `
                                        -Interactive `
                                        -Scopes "user_impersonation" |
                                Select-Object -ExpandProperty AccessToken
        }
    }

    $script:dataverseEnvironmentUrl = "$safeEnvironmentUrl/api/data/$ApiVersion"
    $script:dataverseAccessToken = $authResult.AccessToken | ConvertTo-SecureString -AsPlainText

    Set-DataverseSchemaPrefix -Prefix $SchemaPrefix
}