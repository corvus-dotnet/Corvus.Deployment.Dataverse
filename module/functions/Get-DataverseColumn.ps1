# <copyright file="Get-DataverseColumn" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

function Get-DataverseColumn
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [securestring] $AccessToken = $script:dataverseAccessToken,

        [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
        [string] $Name,

        [Parameter(Mandatory = $true, ParameterSetName = "ById")]
        [guid] $Id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $Table,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $SchemaPrefix = $script:schemaPrefix
    )

    $qualifiedName = "$($SchemaPrefix)_$Name".ToLower()

    $headers = _getHeaders

    $tableCriteria = _getEntityCriterion $Table $SchemaPrefix

    if ($PSCmdlet.ParameterSetName -eq "ByName") {
        $uri = $script:dataverseEnvironmentUrl + "/EntityDefinitions($tableCriteria)/Attributes(LogicalName='$qualifiedName')"
    }
    else {
        $uri = $script:dataverseEnvironmentUrl + "/EntityDefinitions($tableCriteria)/Attributes($Id)"
    }

    try {
        $entity = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
        return $entity
    }
    catch {
        return $null
    }

}