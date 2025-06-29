@description('The environment name (dev, staging, prod)')
param environment string

@description('The location for all resources')
param location string = resourceGroup().location

@description('The base name for all resources')
param baseName string = 'podcast'


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

// Deploy Storage Account
module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    name: storageAccountName
    location: location
    environment: environment
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
    storageConnectionString: storage.outputs.connectionString
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
    hostingPlanId: hostingPlan.outputs.id
  }
}

// Deploy Static Web App (without auth config initially)
module staticWebApp 'modules/static-web-app.bicep' = {
  name: 'staticWebApp'
  params: {
    name: staticWebAppName
    location: location
    environment: environment
    functionAppUrl: functionApp.outputs.functionAppUrl
    tenantId: '' // Will be updated after app registration is created
    clientId: '' // Will be updated after app registration is created
  }
}

// Create App Registration with the actual Static Web App URL
module appRegistration 'modules/app-registration-setup.bicep' = {
  name: 'appRegistration'
  params: {
    appName: baseName
    environment: environment
    location: location
    staticWebAppUrl: staticWebApp.outputs.url
  }
  dependsOn: [
    staticWebApp
  ]
}

// Update Static Web App with the created app registration details
module staticWebAppUpdate 'modules/static-web-app.bicep' = {
  name: 'staticWebAppUpdate'
  params: {
    name: staticWebAppName
    location: location
    environment: environment
    functionAppUrl: functionApp.outputs.functionAppUrl
    tenantId: appRegistration.outputs.tenantId
    clientId: appRegistration.outputs.appId
  }
  dependsOn: [
    appRegistration
  ]
}

// Outputs
output storageAccountName string = storage.outputs.name
output functionAppName string = functionApp.outputs.name
output staticWebAppName string = staticWebApp.outputs.name
output functionAppUrl string = functionApp.outputs.functionAppUrl
output staticWebAppUrl string = staticWebApp.outputs.url
output appRegistrationId string = appRegistration.outputs.appId
output appRegistrationTenantId string = appRegistration.outputs.tenantId
output appRegistrationDisplayName string = appRegistration.outputs.displayName
