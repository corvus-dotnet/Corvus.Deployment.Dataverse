# <copyright file="Connect-PowerPlatformCli" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

function Connect-PowerPlatformCli
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $ProfileName,

        [Parameter(Mandatory = $true)]
        [string] $EnvironmentUrl,

        [Parameter(Mandatory = $true)]
        [string] $TenantId,

        [switch] $UseDeviceCodeFlow
    )

    $PSNativeCommandUseErrorActionPreference = $true

    if ($EnvironmentUrl.EndsWith('/')) {
        $safeEnvironmentUrl = $EnvironmentUrl
    }
    else {
        $safeEnvironmentUrl = "$EnvironmentUrl/"
    }

    # Check whether the required environment variables are available to enable an auto-login with SP secret
    $requiredEnvVarsForServicePrincipalLogin = (
        ![string]::IsNullOrEmpty($env:AZURE_CLIENT_ID) -and `
        ![string]::IsNullOrEmpty($env:AZURE_CLIENT_SECRET)
    )

    # Check whether the required environment variables are available to enable an auto-login with a managed identity
    $requiredEnvVarsForManagedIdLogin = ![string]::IsNullOrEmpty($env:AZURE_CLIENT_ID)

    $pacAuthListOutput = & pac auth list

    if ($pacAuthListOutput -imatch "No profiles were found on this computer") {
        Write-Host "No profiles found"
        $pacAuthProfileIndex = $null
    }
    else {
        $outputColumns = @(
            "Index"
            "Active"
            "Kind"
            "Name"
            "Friendly Name"
            "Url"
            "User"
            "Cloud"
            "Type"
        )
        $pacAuthList = $pacAuthListOutput | ConvertFrom-Fwsv -Headers $outputColumns

        $requiredProfile = $pacAuthList |
                                Where-Object { $_.Name -eq $ProfileName -and $_.Url -eq $safeEnvironmentUrl }
        $existingProfile = $pacAuthList |
                                Where-Object { $_.Name -eq $ProfileName }
        $existingEnvironmentProfile = $pacAuthList |
                                Where-Object { $_.Url -eq $safeEnvironmentUrl }

        if ($requiredProfile) {
            Write-Host "Found matching profile"
            $pacAuthProfileIndex = $requiredProfile.Index
        }
        elseif (!$existingProfile -and $existingEnvironmentProfile) {
            throw "A PowerApp CLI profile already exists for the target environment. [Profile=$ProfileName] [Environment=$EnvironmentUrl]"
        }
        elseif ($existingProfile -and !$existingEnvironmentProfile) {
            throw "The PowerApp CLI profile '$ProfileName' already exists, but is configured for a different PowerApp Environment URL. [TargetEnvironment=$EnvironmentUrl] [ActualEnvironment=$($existingProfile.Url)]"
        }
        else {
            Write-Host "No matching profiles found"
            $pacAuthProfileIndex = $null
        }
    }

    if ($null -eq $pacAuthProfileIndex) {

        $createAuthArgs = @(
            "--name", $ProfileName
            "--url", $safeEnvironmentUrl
            "--tenant", $TenantId
        )
        # Create SPN-based auth profile
        if ($requiredEnvVarsForServicePrincipalLogin) {
            $createAuthArgs += @(
                "--applicationId", $env:AZURE_CLIENT_ID
                "--clientSecret", $env:AZURE_CLIENT_SECRET
            )
        }
        # Create Managed Identity-based auth profile
        elseif ($requiredEnvVarsForManagedIdLogin) {
            $createAuthArgs += @(
                "--managedIdentity"
                "--applicationId", $env:AZURE_CLIENT_ID
            )
        }
        # Create interactive auth profile using device code flow
        elseif ($UseDeviceCodeFlow) {
            $createAuthArgs += @(
                "--deviceCode"
            )
        }

        # Create the authentication profile
        Write-Host "Creating profile '$ProfileName' for environment '$safeEnvironmentUrl'"
        & pac auth create @createAuthArgs | Write-Host -f Magenta
    }
    else {
        $profileIndex = $pacAuthProfileIndex.Replace("[","").Replace("]","")
        Write-Host "Selecting required profile '$ProfileName' [Index=$profileIndex]"
        & pac auth select -i $profileIndex | Write-Host -f Magenta
    }

    $script:isPowerAppCliConnected = $true
    $script:powerAppEnvironmentUrl = $safeEnvironmentUrl
}

# $splat = @{
#     ProfileName = "readsource"
#     EnvironmentUrl = "https://orgfacba7f2.crm4.dynamics.com"
#     TenantId = "2e3c595a-e3f7-4c70-ad42-1bbda49a73d0"
#     UseDeviceCodeFlow = $true
# }
# Connect-PowerPlatformCli @splat