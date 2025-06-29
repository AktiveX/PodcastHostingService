co@description('The name of the app registration')
param appName string

@description('The environment name')
param environment string

@description('The location for resources')
param location string

@description('The Static Web App URL for redirect configuration')
param staticWebAppUrl string = ''

@description('The resource group name')
param resourceGroupName string = resourceGroup().name

// Create a user assigned managed identity for the deployment script
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-appregistration-${environment}'
  location: location
  tags: {
    Environment: environment
    Project: 'PodcastHostingService'
  }
}

// Create role assignment for the managed identity to create app registrations
// This requires the Application Administrator role or appropriate Graph permissions
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, managedIdentity.id, 'Application Administrator')
  scope: subscription()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3') // Application Administrator
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Storage account for deployment script logs and outputs
resource deploymentStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'stappscript${uniqueString(resourceGroup().id, environment)}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
  tags: {
    Environment: environment
    Project: 'PodcastHostingService'
  }
}

// Deployment script to manage app registration
resource appRegistrationScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'ds-appregistration-${environment}'
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  dependsOn: [
    roleAssignment
  ]
  properties: {
    azPowerShellVersion: '10.0'
    retentionInterval: 'P1D'
    timeout: 'PT30M'
    cleanupPreference: 'OnSuccess'
    storageAccountSettings: {
      storageAccountName: deploymentStorageAccount.name
      storageAccountKey: deploymentStorageAccount.listKeys().keys[0].value
    }
    arguments: '-AppName "${appName}" -Environment "${environment}" -StaticWebAppUrl "${staticWebAppUrl}"'
    scriptContent: loadTextContent('../scripts/manage-app-registration.ps1')
  }
  tags: {
    Environment: environment
    Project: 'PodcastHostingService'
  }
}

// Parse the output from the PowerShell script
var scriptOutput = appRegistrationScript.properties.outputs.text
var resultPrefix = 'RESULT:'
var resultIndex = indexOf(scriptOutput, resultPrefix)
var jsonResult = resultIndex >= 0 ? substring(scriptOutput, resultIndex + length(resultPrefix)) : '{}'
var appRegistrationData = json(jsonResult)

// Outputs
output appId string = appRegistrationData.appId
output tenantId string = appRegistrationData.tenantId
output displayName string = appRegistrationData.displayName
output objectId string = appRegistrationData.objectId
output managedIdentityId string = managedIdentity.id
output managedIdentityPrincipalId string = managedIdentity.properties.principalId
