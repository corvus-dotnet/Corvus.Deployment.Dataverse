# <copyright file="_getEntityCriterion.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

function _getEntityName
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $EntityReference,

        [Parameter()]
        [string] $SchemaPrefix = $script:schemaPrefix
    )

    if ($EntityReference -is [guid]) {
        $entityName = $EntityReference
    }
    elseif ($EntityReference -is [PSCustomObject]) {
        $entityName = $EntityReference.MetadataId
    }
    else {
        if (!$SchemaPrefix) {
            throw "The '-SchemaPrefix' parameter is required when an Entity is referenced by its name"
        }
        $entityName = "$($SchemaPrefix)_$Name".ToLower()
    }

    return $entityName
}