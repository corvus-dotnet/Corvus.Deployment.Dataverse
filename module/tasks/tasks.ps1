$SkipPacCli = [bool](property 'SkipPacCli' $false)
$VerboseLogging = [bool](property 'VerboseLogging' ($VerbosePreference -eq "Continue"))

$EnvironmentUrl = property PowerAppsEnvironmentUrl ''
$ProfileName = property PowerAppsAuthProfileName ''
$SchemaPrefix = property DataverseSchemaPrefix ''
$SolutionName = property PowerAppsSolutionName ''
$SolutionPath = property SolutionPath ''
$TableDefinitionsPath = property TableDefinitionsPath (Join-Path $here "tables")
$TenantId = property TenantId ''

task SetSkipPacCli {
    $script:SkipPacCli = $true
}

task CheckParameters {
    $requiredVars = @('EnvironmentUrl', 'SchemaPrefix', 'TenantId')
    if (!$SkipPacCli) { $requiredVars += 'ProfileName' }
    if (!$SolutionPath) { $requiredVars += 'SolutionName' }

    $isValid = $true
    $requiredVars | ForEach-Object {
        if (-not (Get-Variable -Name $_ -ValueOnly)) {
            Write-Build Red "Variable '`$$_' is required, but currently undefined"
            $isValid = $false
        }
    }

    if (!$isValid) {
        throw "Required variables are missing - check previous messages."
    }
}

# Synopsis: Ensures the cross-platform Power Apps CLI .NET global tool is available
task EnsurePowerPlatformCli -If {!$SkipPacCli} {
    $toolName = "Microsoft.PowerApps.CLI.Tool"
    Install-DotNetTool $toolName
}

task EnsureDataverseEnvironment -If {!$SkipPacCli} EnsurePowerPlatformCli,{

    $splat = @{
        ProfileName = $ProfileName
        EnvironmentUrl = $EnvironmentUrl
        TenantId = $TenantId
    }
    Connect-PowerPlatformCli @splat
}

task EnsureDataverseSolution EnsureDataverseEnvironment,{

    if (!$SolutionName) {
        Write-Build White "Reading Solution Name from Solution.xml"
        $solutionXml = [xml](Get-Content "$SolutionPath/Other/Solution.xml")
        $SolutionName = $solutionXml.ImportExportXml.SolutionManifest.UniqueName
    }

    $solution = Select-PowerAppsSolution -SolutionName $SolutionName

    if (!$solution) {
        throw "Solution '$SolutionName' not found in environment $powerAppEnvironmentUrl - currently this must be created manually."
    }
}

task ConnectDataverse {

    Connect-DataverseEnvironment `
        -TenantId $TenantId `
        -EnvironmentUrl $EnvironmentUrl `
        -SolutionName $SolutionName `
        -SchemaPrefix $SchemaPrefix
}

task DeployDataverseTables {
    $tablesToProcess = Get-ChildItem -Path $TableDefinitionsPath -Filter *.yml

    foreach ($tableDefintionFile in $tablesToProcess) {

        $tableDefinition = Get-Content $tableDefintionFile | ConvertFrom-Yaml -Ordered

        $tableId = Set-DataverseTable @tableDefinition -Verbose:$VerboseLogging

        foreach ($column in $tableDefinition.columns) {
            $columnId = $tableId | Set-DataverseColumn @column -Verbose:$VerboseLogging
        }
    }
}
