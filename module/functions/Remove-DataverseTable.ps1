# <copyright file="Remove-DataverseTable" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

<#
.SYNOPSIS
Removes a table from the Dataverse environment using either the table name or ID.

.DESCRIPTION
This function removes a table from the Dataverse environment using either the table name or ID. 

.PARAMETER AccessToken
The access token used for authentication. If not provided, the script will use the set having called
the Connect-DataverseEnvironment function.

.PARAMETER Name
The name of the Dataverse table to remove.

.PARAMETER Id
The ID of the Dataverse table to remove.

.EXAMPLE
Remove-DataverseTable -Name "Account"

This example removes the "Account" table from the Dataverse environment using the provided access token.

.EXAMPLE
Remove-DataverseTable -Id $guid

This example removes the table with the provided ID from the Dataverse environment using the provided access token.
#>

function Remove-DataverseTable
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [securestring] $AccessToken = $script:dataverseAccessToken,

        [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
        [string] $Name,

        [Parameter(Mandatory = $true, ParameterSetName = "ById")]
        [guid] $Id
    )

    # Define the headers for the HTTP request
    $headers = _getHeaders

    $existingEntity = Get-DataverseTable @PSBoundParameters

    if ($existingEntity) {
        Write-Host "Deleting table $Name with ID $($existingEntity.MetadataId)"
        # Send the HTTP request
        $uri = $script:dataverseEnvironmentUrl + "/EntityDefinitions($($existingEntity.MetadataId))"
        
        $statusCode = $null
        $responseHeaders = $null
        $response = Invoke-RestMethod `
                        -Uri $uri `
                        -Method Delete `
                        -Headers $headers `
                        -StatusCodeVariable statusCode `
                        -ResponseHeadersVariable responseHeaders

        Write-Host "Table deleted successfully"
    }
    else {
        Write-Host "Table $Name does not exist"
    }
}