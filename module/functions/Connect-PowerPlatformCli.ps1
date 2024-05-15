# <copyright file="Connect-PowerPlatformCli" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

<#
.SYNOPSIS
Sets up or switches to a Power Platform CLI connection profile.

.DESCRIPTION
Sets up or switches to a Power Platform CLI connection profile.

.PARAMETER ProfileName
The path of the file containing the code.

.PARAMETER EnvironmentUrl
The Power Apps environment URL.

.PARAMETER TenantId
The Power Apps Tenant ID.

.PARAMETER UseDeviceCodeFlow
When specified, interactive authentication attempts will use the device code flow.

#>

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
            throw "A PowerApp CLI profile already exists for the target environment. Either use this existing profile name or delete the profile.  [Profile=$($existingEnvironmentProfile.Name)] [Environment=$safeEnvironmentUrl]"
        }
        elseif ($existingProfile -and !$existingEnvironmentProfile) {
            throw "The PowerApp CLI profile '$ProfileName' already exists, but is configured for a different PowerApp Environment URL. Either use a different profile name or delete the existing profile. [TargetEnvironment=$safeEnvironmentUrl] [ActualEnvironment=$($existingProfile.Url)]"
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
                "--accept-cleartext-caching"
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

    $script:isPowerPlatformCliConnected = $true
    $script:powerAppEnvironmentUrl = $safeEnvironmentUrl
}
