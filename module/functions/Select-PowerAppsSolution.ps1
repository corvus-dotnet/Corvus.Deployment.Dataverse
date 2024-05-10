# <copyright file="Select-PowerAppsSolution.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

<#
.SYNOPSIS
Obtains an access token for the Dataverse environment.

.DESCRIPTION
Obtains an access token for the Dataverse environment that is used for other operations.

.PARAMETER SolutionName
The Power Apps solution name.

.PARAMETER ThrowIfNotFound
When specified, an exception is thrown if the solution is not found.

#>

function Select-PowerAppsSolution {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SolutionName,
        
        [switch]$ThrowIfNotFound
    )

    if (!$isPowerPlatformCliConnected) {
        throw "PowerApps CLI is not connected - please run 'Connect-PowerPlatformCli' first"
    }

    Write-Host "Checking for existing Power Apps Solution: $SolutionName"
    $pacSolutionListOutput = & pac solution list --environment $powerAppEnvironmentUrl

    $existingSolution = $pacSolutionListOutput |
                            Select-Object -Skip 4 |
                            ConvertFrom-Fwsv -Headers @("Unique Name","Friendly Name","Version","Managed") |
                            Where-Object { $_."Unique Name" -eq $SolutionName }

    if ($null -eq $existingSolution -and $ThrowIfNotFound) {
        throw "Solution $SolutionName not found in environment $powerAppEnvironmentUrl"
    }
    else {
        Write-Host "Solution found & selected."
        $script:solutionName = $existingSolution."Unique Name"
        $existingSolution
    }
}