# <copyright file="Set-DataverseTable" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

function Set-DataverseTable
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [securestring] $AccessToken = $script:dataverseAccessToken,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $SchemaPrefix = $script:schemaPrefix,

        [Parameter(Mandatory = $true)]
        [string] $Name,

        [Parameter(Mandatory = $true)]
        [Alias("displayName")]
        [string] $Label,

        [Parameter()]
        [Alias("collectionDisplayName")]
        [string] $LabelPlural = "$($Label)s",

        [Parameter(Mandatory = $true)]
        [string] $Description,

        [Parameter(Mandatory = $true)]
        [Alias("keyType")]
        [ValidateSet("String","Money","DateTime","Boolean","Decimal","Integer","Memo","Uniqueidentifier")]
        # TODO: "Lookup","Picklist","State","Status","Uniqueidentifier","Virtual","BigInt","ManagedProperty","EntityName","CalendarRules","VirtualCollection","EntityCollection","BigDateTime","ManagedPropertyCollection","EntityNameReference","EntityCollectionWithAttributes","EntityReference","EntityReferenceWithAttributes","StringType","MemoType","IntegerType","BigIntType","DoubleType","DecimalType","MoneyType","BooleanType","DateTimeType","LookupType","OwnerType","UniqueidentifierType","StateType","StatusType","VirtualType","ManagedPropertyType","EntityNameType","CalendarRulesType","VirtualCollectionType","EntityCollectionType","BigDateTimeType","ManagedPropertyCollectionType","EntityNameReferenceType","EntityCollectionWithAttributesType","EntityReferenceType","EntityReferenceWithAttributesType"
        [string] $PrimaryKeyType,

        [Parameter(Mandatory = $true)]
        [Alias("keyDisplayName")]
        [string] $PrimaryKeyDisplayName,

        [Parameter()]
        [Alias("keyDescription")]
        [string] $PrimaryKeyDescription = "The primary identifier for the entity.",

        [Parameter(ValueFromRemainingArguments=$true)]
        $Remaining
    )

    $qualifiedName = "$($SchemaPrefix)_$Name".ToLower()

    # Define the headers for the HTTP request
    $headers = _getHeaders

    # Define the data for the new table
    $data = [ordered]@{
        "@odata.type" = "Microsoft.Dynamics.CRM.EntityMetadata"
        Attributes = @(
            [ordered]@{
                AttributeType = "String"    # todo
                AttributeTypeName = [ordered]@{
                    Value = $PrimaryKeyType
                }
                Description = [ordered]@{
                    "@odata.type" = "Microsoft.Dynamics.CRM.Label"
                    LocalizedLabels = @(
                        [ordered]@{
                            "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                            Label = $PrimaryKeyDescription
                            LanguageCode = 1033
                        }
                    )
                }
                DisplayName = [ordered]@{
                    "@odata.type" = "Microsoft.Dynamics.CRM.Label"
                    LocalizedLabels = @(
                        [ordered]@{
                            "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                            Label = $PrimaryKeyDisplayName
                            LanguageCode = 1033
                        }
                    )
                }
                IsPrimaryName = $true
                RequiredLevel = [ordered]@{
                    Value = "None"
                    CanBeChanged = $true
                    ManagedPropertyLogicalName = "canmodifyrequirementlevelsettings"
                }
                SchemaName = $qualifiedName
                "@odata.type" = "Microsoft.Dynamics.CRM.StringAttributeMetadata"
                FormatName = [ordered]@{
                    Value = "Text"
                }
                MaxLength = 100
            }       
        )
        Description = [ordered]@{
            "@odata.type" = "Microsoft.Dynamics.CRM.Label"
            LocalizedLabels = @(
                [ordered]@{
                    "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                    Label = $Description
                    LanguageCode = 1033
                }
            )
        }
        DisplayCollectionName = [ordered]@{
            "@odata.type" = "Microsoft.Dynamics.CRM.Label"
            LocalizedLabels = @(
                [ordered]@{
                    "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                    Label = $LabelPlural
                    LanguageCode = 1033
                }
            )
        }
        DisplayName = [ordered]@{
            "@odata.type" = "Microsoft.Dynamics.CRM.Label"
            LocalizedLabels = @(
                [ordered]@{
                    "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                    Label = $Label
                    LanguageCode = 1033
                }
            )
        }
        HasActivities = $false
        HasNotes = $false
        IsActivity = $false
        OwnershipType = "UserOwned"
        SchemaName = $qualifiedName
    }

    $existingEntity = Get-DataverseTable -Name $Name -SchemaPrefix $SchemaPrefix
    if ($existingEntity) {
        Write-Host "Updating table: $Name [ID=$($existingEntity.MetadataId)]" -f Cyan
        $entityId = $existingEntity.MetadataId
        $method = "Put"
        $uri = $script:dataverseEnvironmentUrl + "/EntityDefinitions($entityId)"
    }
    else {
        Write-Host "Creating table: $Name" -f Cyan
        $method = "Post"
        $uri = $script:dataverseEnvironmentUrl + "/EntityDefinitions"
    }

    # Convert the data to JSON
    $jsonData = $data | ConvertTo-Json -Depth 100

    # Send the HTTP request
    $statusCode = $null
    $responseHeaders = $null
    $response = Invoke-RestMethod `
                    -Uri $uri `
                    -Method $method `
                    -Body $jsonData `
                    -Headers $headers `
                    -StatusCodeVariable statusCode `
                    -ResponseHeadersVariable responseHeaders

    # Check the response
    if ($statusCode -eq 204) {
        Write-Host "  Success" -f Green
        # Extract EntityId from the response headers which has the following format:
        # "[Organization URI]/api/data/v9.2/EntityDefinitions(<36-character-guid>)"
        $entityUri = $responseHeaders["OData-EntityId"] | Select-Object -First 1
        $entityId = $entityUri.SubString($entityUri.Length - 37, 36)
        return [guid]$entityId
    } else {
        Write-Host "  Failed to create/update table. Status code: $($response.StatusCode)" -f Red
        return $null
    }

}