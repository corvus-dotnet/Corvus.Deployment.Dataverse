# <copyright file="Get-DataverseTable" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

<#
.SYNOPSIS
Obtains a table from the Dataverse environment using either the table name or ID.

.DESCRIPTION
This function retrieves a table from the Dataverse environment using either the table name or ID. 

.PARAMETER AccessToken
The access token used for authentication. If not provided, the script will use the set having called
the Connect-DataverseEnvironment function.

.PARAMETER Name
The name of the Dataverse table to retrieve.

.PARAMETER Id
The ID of the Dataverse table to retrieve.

.EXAMPLE
Get-DataverseTable -Name "Account"

This example retrieves the "Account" table from the Dataverse environment using the provided access token.

.EXAMPLE
Get-DataverseTable -Id $guid

This example retrieves the table with the provided ID from the Dataverse environment using the provided access token.
#>

function Get-DataverseTable
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

        [Parameter(ParameterSetName = "ByName")]
        [ValidateNotNullOrEmpty()]
        [string] $SchemaPrefix = $script:schemaPrefix
    )

    $qualifiedName = "$($SchemaPrefix)_$Name".ToLower()
    
    # Define the headers for the HTTP request
    $headers = _getHeaders

    if ($PSCmdlet.ParameterSetName -eq "ByName") {
        $uri = $script:dataverseEnvironmentUrl + "/EntityDefinitions(LogicalName='$qualifiedName')"
    }
    else {
        $uri = $script:dataverseEnvironmentUrl + "/EntityDefinitions($Id)"
    }

    try {
        $entity = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
        return $entity
    }
    catch {
        return $null
    }

}