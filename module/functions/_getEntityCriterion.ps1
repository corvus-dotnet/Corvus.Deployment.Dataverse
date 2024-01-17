# <copyright file="_getEntityCriterion.ps1" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

function _getEntityCriterion
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $EntityReference,

        [Parameter()]
        [string] $SchemaPrefix = $script:schemaPrefix
    )

    if ($EntityReference -is [guid]) {
        $entityCriterion = $EntityReference
    }
    elseif ($EntityReference -is [PSCustomObject]) {
        $entityCriterion = $EntityReference.MetadataId
    }
    else {
        if (!$SchemaPrefix) {
            throw "The '-SchemaPrefix' parameter is required when an Entity is referenced by its name"
        }
        $qualifiedName = "$($SchemaPrefix)_$Name".ToLower()
        $entityCriterion = "LogicalName='$qualifiedName'"
    }

    return $entityCriterion
}