function Select-PowerAppsSolution {
    param (
        [string]$SolutionName,
        [switch]$ThrowIfNotFound
    )

    if (!$isPowerAppCliConnected) {
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