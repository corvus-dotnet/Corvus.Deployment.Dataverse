# <copyright file="_getHeaders.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

function _getHeaders
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [securestring] $AccessToken = $script:dataverseAccessToken
    )

    $headers = @{
        "Authorization" = "Bearer " + (ConvertFrom-SecureString $AccessToken -AsPlainText)
        "OData-MaxVersion" = "4.0"
        "OData-Version" = "4.0"
        "Content-Type" = "application/json; charset=utf-8"
    }

    if ($script:solutionName) {
        $headers.Add("MSCRM.SolutionUniqueName", $script:solutionName)
    }

    return $headers
}
