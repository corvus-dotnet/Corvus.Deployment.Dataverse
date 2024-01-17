# <copyright file="Get-DataverseTable" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

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