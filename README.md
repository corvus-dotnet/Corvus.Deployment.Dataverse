# Corvus.Deployment.Dataverse

A PowerShell module to assist with code-first deployment of Microsoft Dataverse schemas.

## Basic Usage

```
Install-Module MSAL.PS -Scope CurrentUser
Install-Module powershell-yaml -Scope CurrentUser
Import-Module ./module/Corvus.Deployment.Dataverse.psd1
```

## Code-First Table Authoring

Dataverse table schemas can be authored as YAML files, whereby a single file defines a single table and its columns.  These files should be structured as shown below:

```
name: applicant
displayName: Applicant
description: An applicant
collectionDisplayName: Applicants
keyType: Uniqueidentifier
keyName: applicantId
keyDisplayName: Applicant Id
keyDescription: The unique identifier for an applicant

columns:
  - name: applicantName
    type: String
    description: The name of the applicant
    displayName: Applicant Name
  - name: applicantDOB
    type: DateTime
    description: The applicant's date of birth
    displayName: Applicant Date of Birth
    additionalProperties:
      Format: DateOnly
  
```

### Column Types

In the current version only a subset of column types have optimised authoring support (whereby the YAML files can use a more terse syntax to define entities than otherwise required by the underlying REST API).

Explicitly supported column types:
* `String`
* `Boolean`

Other types with no associated special metadata can also be used as-is.

In the absence of optimised authoring support, the `additionalProperties` key can be used to provide the additional metadata required by the REST API for certain column types (see the `applicantDOB` column in the above example).


## Code-First Table Deployment

The following script provides a basic example of how this module can be used to deploy the code-first table definitions to a Dataverse environment.

```
Import-Module powershell-yaml
Import-Module ./module/Corvus.Deployment.Dataverse.psd1

# The following will prompt for interactive Microsoft Entra ID authentication
Connect-DataverseEnvironment `
    -TenantId "00000000-0000-0000-0000-000000000000" `
    -EnvironmentUrl "https://myenv.crm11.dynamics.com" `
    -SolutionName "mysolution" `
    -SchemaPrefix "myapp"

$tablesToProcess = Get-ChildItem -Path ./tables/*.yml

foreach ($tableDefintionFile in $tablesToProcess) {

    $tableDefinition = Get-Content $tableDefintionFile | ConvertFrom-Yaml -Ordered

    $tableId = Set-DataverseTable @tableDefinition

    foreach ($column in $tableDefinition.columns) {
        $columnId = $tableId | Set-DataverseColumn @column
    }
}
```
