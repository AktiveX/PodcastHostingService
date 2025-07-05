// Infrastructure deployment for Podcast Hosting Service
@description('The environment name (dev, staging, prod)')
param environment string

@description('The location for all resources')
param location string = resourceGroup().location

@description('The base name for all resources')
param baseName string = 'podcast'

@description('The AAD tenant ID for authentication')
param tenantId string

@description('The AAD client ID for authentication')
param clientId string

// Generate unique names based on environment and base name
var uniqueSuffix = uniqueString(resourceGroup().id, environment)
var storageAccountName = 'st${baseName}${environment}${uniqueSuffix}'
var functionAppName = 'func-${baseName}-${environment}-${uniqueSuffix}'
var staticWebAppName = 'swa-${baseName}-${environment}'
var appInsightsName = 'ai-${baseName}-${environment}'
var hostingPlanName = 'plan-${baseName}-${environment}'

// Deploy Application Insights
module appInsights 'modules/app-insights.bicep' = {
  name: 'appInsights'
  params: {
    name: appInsightsName
    location: location
    environment: environment
  }
}

// Deploy Storage Account (without role assignments first)
module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    name: storageAccountName
    location: location
    environment: environment
    functionAppPrincipalId: ''
  }
}

// Deploy Hosting Plan
module hostingPlan 'modules/hosting-plan.bicep' = {
  name: 'hostingPlan'
  params: {
    name: hostingPlanName
    location: location
    environment: environment
  }
}

// Deploy Function App
module functionApp 'modules/function-app.bicep' = {
  name: 'functionApp'
  params: {
    name: functionAppName
    location: location
    environment: environment
    storageAccountName: storageAccountName
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
    hostingPlanId: hostingPlan.outputs.id
  }
  dependsOn: [
    storage
  ]
}

// Deploy Static Web App
module staticWebApp 'modules/static-web-app.bicep' = {
  name: 'staticWebApp'
  params: {
    name: staticWebAppName
    location: location
    environment: environment
    functionAppUrl: functionApp.outputs.functionAppUrl
    tenantId: tenantId
    clientId: clientId
  }
}

// Outputs
output storageAccountName string = storage.outputs.name
output functionAppName string = functionApp.outputs.name
output staticWebAppName string = staticWebApp.outputs.name
output functionAppUrl string = functionApp.outputs.functionAppUrl
output staticWebAppUrl string = staticWebApp.outputs.url
