@description('The name of the storage account')
param name string

@description('The location for the storage account')
param location string

@description('The environment name')
param environment string

@description('The principal ID of the function app managed identity')
param functionAppPrincipalId string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: name
  location: location
  sku: {
    name: environment == 'prod' ? 'Standard_ZRS' : 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
  tags: {
    Environment: environment
    Project: 'PodcastHostingService'
  }
}

// Create blob service with CORS configuration
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: [
        {
          allowedOrigins: ['*']
          allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
          allowedHeaders: ['*']
          exposedHeaders: ['*']
          maxAgeInSeconds: 86400
        }
      ]
    }
    deleteRetentionPolicy: {
      enabled: true
      days: environment == 'prod' ? 30 : 7
    }
  }
}

// Create containers for podcasts and episodes
resource podcastContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: 'podcasts'
  properties: {
    publicAccess: 'Blob'
  }
}

resource episodeContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: 'episodes'
  properties: {
    publicAccess: 'Blob'
  }
}

// Role assignments for Function App managed identity
resource storageBlobDataContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor
}

resource storageAccountContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '17d1049b-9a84-46fb-8f53-869881c3d3ab' // Storage Account Contributor
}

resource functionAppBlobDataAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (functionAppPrincipalId != '') {
  scope: storageAccount
  name: guid(storageAccount.id, functionAppPrincipalId, storageBlobDataContributorRoleDefinition.id)
  properties: {
    roleDefinitionId: storageBlobDataContributorRoleDefinition.id
    principalId: functionAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource functionAppStorageAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (functionAppPrincipalId != '') {
  scope: storageAccount
  name: guid(storageAccount.id, functionAppPrincipalId, storageAccountContributorRoleDefinition.id)
  properties: {
    roleDefinitionId: storageAccountContributorRoleDefinition.id
    principalId: functionAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output name string = storageAccount.name
output id string = storageAccount.id
output primaryEndpoints object = storageAccount.properties.primaryEndpoints
