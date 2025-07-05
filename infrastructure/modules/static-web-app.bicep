@description('The name of the static web app')
param name string

@description('The location for the static web app')
param location string

@description('The environment name')
param environment string

@description('The function app URL')
param functionAppUrl string

@description('The AAD tenant ID')
param tenantId string

@description('The AAD client ID')
param clientId string

resource staticWebApp 'Microsoft.Web/staticSites@2023-01-01' = {
  name: name
  location: location
  sku: {
    name: 'Free'
    tier: 'Free'
  }
  properties: {
    repositoryUrl: ''
    branch: ''
    buildProperties: {
      appLocation: 'frontend'
      outputLocation: 'dist'
    }
    stagingEnvironmentPolicy: 'Enabled'
    allowConfigFileUpdates: true
    provider: 'None'
  }
  tags: {
    Environment: environment
    Project: 'PodcastHostingService'
  }
}

// Configure app settings for the static web app
resource staticWebAppConfig 'Microsoft.Web/staticSites/config@2023-01-01' = {
  parent: staticWebApp
  name: 'appsettings'
  properties: {
    VUE_APP_API_URL: functionAppUrl
    VUE_APP_AUTH_CLIENT_ID: clientId
    VUE_APP_AUTH_AUTHORITY: 'https://login.microsoftonline.com/${tenantId}'
    VUE_APP_ENVIRONMENT: environment
  }
}

// Outputs
output name string = staticWebApp.name
output id string = staticWebApp.id
output url string = 'https://${staticWebApp.properties.defaultHostname}'
output defaultHostname string = staticWebApp.properties.defaultHostname
