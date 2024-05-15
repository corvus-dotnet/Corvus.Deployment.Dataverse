$taskDefinitions = Get-ChildItem (Join-Path $PSScriptRoot "tasks") -Filter "*tasks.ps1"

$taskDefinitions | ForEach-Object {
    Write-Information "Import '$($_.FullName)'"
    . $_
}

# Import the deployment process that orchestrates the above tasks
. (Join-Path $PSScriptRoot "tasks" "process.ps1")