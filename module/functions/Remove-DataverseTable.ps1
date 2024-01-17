# <copyright file="Remove-DataverseTable" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

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