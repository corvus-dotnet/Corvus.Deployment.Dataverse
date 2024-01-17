# <copyright file="Set-DataverseColumn" company="Endjin Limited">
# Copyright (c) Endjin Limited. All rights reserved.
# </copyright>

function Set-DataverseColumn
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [securestring] $AccessToken = $script:dataverseAccessToken,

        [Parameter(Mandatory = $true)]
        [string] $Name,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Alias("TableId")]
        [Alias("TableName")]
        $Table,

        [Parameter(Mandatory = $true)]
        [string] $DisplayName,

        [Parameter(Mandatory = $true)]
        [string] $Description,

        [Parameter(Mandatory = $true)]
        [ValidateSet("String","Money","DateTime","Boolean","Decimal","Integer","Memo","Uniqueidentifier")]
        # TODO: "Lookup","Picklist","State","Status","Uniqueidentifier","Virtual","BigInt","ManagedProperty","EntityName","CalendarRules","VirtualCollection","EntityCollection","BigDateTime","ManagedPropertyCollection","EntityNameReference","EntityCollectionWithAttributes","EntityReference","EntityReferenceWithAttributes","StringType","MemoType","IntegerType","BigIntType","DoubleType","DecimalType","MoneyType","BooleanType","DateTimeType","LookupType","OwnerType","UniqueidentifierType","StateType","StatusType","VirtualType","ManagedPropertyType","EntityNameType","CalendarRulesType","VirtualCollectionType","EntityCollectionType","BigDateTimeType","ManagedPropertyCollectionType","EntityNameReferenceType","EntityCollectionWithAttributesType","EntityReferenceType","EntityReferenceWithAttributesType"
        [string] $Type,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] $SchemaPrefix = $script:schemaPrefix,

        [Parameter()]
        [Alias("additionalProperties")]
        $AdditionalAttributeMetadata = $null
    )

    $qualifiedName = "$($SchemaPrefix)_$Name".ToLower()

    $headers = _getHeaders

    $tableCriteria = _getEntityCriterion $Table $SchemaPrefix

    $data = [ordered]@{
        AttributeType = $Type
        AttributeTypeName = [ordered]@{
            Value = "$($Type)Type"
        }
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
        DisplayName = [ordered]@{
            "@odata.type" = "Microsoft.Dynamics.CRM.Label"
            LocalizedLabels = @(
                [ordered]@{
                    "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                    Label = $DisplayName
                    LanguageCode = 1033
                }
            )
        }
        RequiredLevel = [ordered]@{
            Value = "None"
            CanBeChanged = $true
            ManagedPropertyLogicalName = "canmodifyrequirementlevelsettings"
        }
        SchemaName = $qualifiedName
        "@odata.type" = "Microsoft.Dynamics.CRM.$($Type)AttributeMetadata"
        # FormatName = [ordered]@{
        #     Value = "Text"  # todo
        # }
        # MaxLength = 100 # todo
    }

    # TODO: Refactor this to be pluggable and hence more extensible
    if ($AdditionalAttributeMetadata) {
        foreach ($key in $AdditionalAttributeMetadata.Keys) {
            $data.Add($key, $AdditionalAttributeMetadata[$key])
        }
    }
    # Provide some defaults for the certains types
    elseif ($Type -eq "String") {
        $data.Add("FormatName", [ordered]@{
            Value = "Text"  # todo
        })
        $data.Add("MaxLength", 100) # todo
    }
    elseif ($Type -eq "Boolean") {
        $optionSet = [ordered]@{
            TrueOption = [ordered]@{
                Value = 1
                Label = [ordered]@{
                    "@odata.type" = "Microsoft.Dynamics.CRM.Label"
                    LocalizedLabels = @(
                        [ordered]@{
                            "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                            Label = "True"
                            LanguageCode = 1033
                            IsManaged = $false
                        }
                    )
                }
            
            }
            FalseOption = [ordered]@{
                Value = 0
                Label = [ordered]@{
                    "@odata.type" = "Microsoft.Dynamics.CRM.Label"
                    LocalizedLabels = @(
                        [ordered]@{
                            "@odata.type" = "Microsoft.Dynamics.CRM.LocalizedLabel"
                            Label = "False"
                            LanguageCode = 1033
                            IsManaged = $false
                        }
                    )
                }
            }
            OptionSetType = "Boolean"
        }
        $data.Add("DefaultValue", $false)
        $data.Add("OptionSet", $optionSet)
    }

    $existingEntity = Get-DataverseColumn -Table $Table -Name $Name -SchemaPrefix $SchemaPrefix
    
    # Lookup table name/id for logging purposes
    $tableName = _getEntityName $Table $SchemaPrefix
    
    if ($existingEntity) {
        Write-Host "Updating column: $Name [ID=$($existingEntity.MetadataId)] [Table=$tableName]" -f Magenta
        $entityId = $existingEntity.MetadataId
        $method = "Put"
        $uri = $script:dataverseEnvironmentUrl + "/EntityDefinitions($tableCriteria)/Attributes(LogicalName='$qualifiedName')"
    }
    else {
        Write-Host "Creating column: $Name [Table=$tableName]" -f Magenta
        $method = "Post"
        $uri = $script:dataverseEnvironmentUrl + "/EntityDefinitions($tableCriteria)/Attributes"
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
        # "[Organization URI]/api/data/v9.2/EntityDefinitions(<36-character-guid>)/Attributes(<36-character-guid>)"
        $entityUri = $responseHeaders["OData-EntityId"] | Select-Object -First 1
        $entityId = $entityUri.SubString($entityUri.Length - 37, 36)
        return $entityId
    } else {
        Write-Host "  Failed to create/update column. Status code: $($response.StatusCode)" -f Red
        return $null
    }

}