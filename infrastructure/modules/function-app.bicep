@description('The name of the function app')
param name string

@description('The location for the function app')
param location string

@description('The environment name')
param environment string

@description('The storage connection string')
param storageConnectionString string

@description('The Application Insights instrumentation key')
param appInsightsInstrumentationKey string

@description('The hosting plan ID')
param hostingPlanId string

resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: name
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: hostingPlanId
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: storageConnectionString
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: storageConnectionString
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(name)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'BlobStorageConnection'
          value: storageConnectionString
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
      ]
      cors: {
        allowedOrigins: [
          '*'
        ]
        supportCredentials: false
      }
      use32BitWorkerProcess: false
      netFrameworkVersion: 'v6.0'
    }
    httpsOnly: true
    clientAffinityEnabled: false
  }
  tags: {
    Environment: environment
    Project: 'PodcastHostingService'
  }
}

// Outputs
output name string = functionApp.name
output id string = functionApp.id
output functionAppUrl string = 'https://${functionApp.properties.defaultHostName}/api'
output defaultHostName string = functionApp.properties.defaultHostName
