# <copyright file="Get-DataverseColumn" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

<#
.SYNOPSIS
Obtains a column from a Dataverse table using either the column name or ID.

.DESCRIPTION
This function retrieves a column from a specified Dataverse table using either the column name or ID.

.PARAMETER AccessToken
The access token used for authentication. If not provided, the script will use the set having called
the Connect-DataverseEnvironment function.

.PARAMETER Name
The name of the Dataverse column to retrieve.

.PARAMETER Id
The ID of the Dataverse column to retrieve.

.PARAMETER Table
An object representing the Dataverse table from which to retrieve the column. This can be obtained using Get-DataverseTable.

.EXAMPLE
Get-DataverseColumn -Name "AccountName" -Table $table

This example retrieves the "AccountName" column from the specified Dataverse table using the provided access token.

.EXAMPLE
Get-DataverseColumn -Id $guid -Table $table

This example retrieves the column with the provided ID from the specified Dataverse table using the provided access token.
#>

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