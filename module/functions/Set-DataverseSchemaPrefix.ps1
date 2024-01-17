# <copyright file="Set-DataverseSchemaPrefix" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

function Set-DataverseSchemaPrefix
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Prefix
    )

    $script:schemaPrefix = $Prefix
}