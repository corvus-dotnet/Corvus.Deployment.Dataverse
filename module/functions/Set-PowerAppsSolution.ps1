# <copyright file="Set-PowerAppsSolution.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

<#
.SYNOPSIS
Sets the target Power Apps Solution for the current session.

.DESCRIPTION
Sets the target Power Apps Solution for the current session.

.PARAMETER SolutionName
The Power Apps solution name.

#>

function Set-PowerAppsSolution {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SolutionName
    )
     
    $script:solutionName = $SolutionName
}