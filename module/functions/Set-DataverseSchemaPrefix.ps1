# <copyright file="Set-DataverseSchemaPrefix" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

<#
.SYNOPSIS
Sets the Dataverse database schema prefix that will be used by future operations.

.DESCRIPTION
Sets the Dataverse database schema that will be used in future operations.

.PARAMETER Prefix
The schema prefix to set.

.EXAMPLE
Set-DataverseSchemaPrefix -Prefix "myschema"

This example sets the "AccountName" column in the specified Dataverse table using the provided access token.
#>

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