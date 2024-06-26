# <copyright file="Corvus.Deployment.Dataverse.psm1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>
$ErrorActionPreference = 'Stop'

Set-Alias Corvus.Deployment.Dataverse.tasks $PSScriptRoot/import-tasks.ps1

# Dynamically populate the module
#
# NOTE:
#  1) Ignore any Pester test fixtures
#

# find all the functions that make-up this module
$functions = Get-ChildItem -Recurse $PSScriptRoot/functions -Include *.ps1 | `
                                Where-Object { $_ -notmatch ".Tests.ps1" }
                    
# dot source the individual scripts that make-up this module
foreach ($function in ($functions)) { . $function.FullName }

# export the non-private functions (by convention, private function scripts must begin with an '_' character)
Export-ModuleMember -Function ( $functions | 
                                    ForEach-Object { (Get-Item $_).BaseName } | 
                                    Where-Object { -not $_.StartsWith("_") }
                            ) `
                    -Alias Corvus.Deployment.Dataverse.tasks

# Set the required variables that are global to this module
$script:isPowerPlatformCliConnected = $false
$script:schemaPrefix = ""
$script:dataverseEnvironmentUrl = ""
$script:solutionName = ""
[securestring] $script:dataverseAccessToken = $null             # TODO: Option to read from environment variable?
