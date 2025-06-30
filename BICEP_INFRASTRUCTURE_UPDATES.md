# Bicep Infrastructure Updates for API-First OAuth Architecture

## Overview

This document provides the complete updated Bicep infrastructure templates to align with our new API-first OAuth architecture. The updates include:

1. **Key Vault integration** for secret management
2. **System Managed Identity** for Function App
3. **Enhanced storage configuration** for new auth tables
4. **Updated Function App settings** for OAuth providers
5. **Fixed syntax errors** in existing templates

## Files to Update

### 1. Fix Syntax Error in `infrastructure/modules/app-registration-setup.bicep`

**Issue:** Line 1 has `co@description` instead of `@description`

**Fix:** Replace line 1:
```bicep
// FROM:
co@description('The name of the app registration')

// TO:
@description('The name of the app registration')
```

**Issue:** Line 30 has incorrect scope for role assignment

**Fix:** Replace the roleAssignment resource:
```bicep
// REMOVE the existing roleAssignment resource and replace with:
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managedIdentity.id, 'Application Administrator')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3') // Application Administrator
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}
```

### 2. Update `infrastructure/main.bicep`

**Add Key Vault and update architecture:**

```bicep
@description('The environment name (dev, staging, prod)')
param environment string

@description('The location for all resources')
param location string = resourceGroup().location

@description('The base name for all resources')
param baseName string = 'podcast'

@description('Google OAuth Client ID (to be set manually)')
param googleClientId string = ''

// Generate unique names based on environment and base name
var uniqueSuffix = uniqueString(resourceGroup().id, environment)
var storageAccountName = 'st${baseName}${environment}${uniqueSuffix}'
var functionAppName = 'func-${baseName}-${environment}-${uniqueSuffix}'
var staticWebAppName = 'swa-${baseName}-${environment}'
var appInsightsName = 'ai-${baseName}-${environment}'
var hostingPlanName = 'plan-${baseName}-${environment}'
var keyVaultName = 'kv-${baseName}-${environment}-${uniqueSuffix}'

// Deploy Application Insights
module appInsights 'modules/app-insights.bicep' = {
  name: 'appInsights'
  params: {
    name: appInsightsName
    location: location
    environment: environment
  }
}

// Deploy Storage Account (updated for new tables)
module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    name: storageAccountName
    location: location
    environment: environment
  }
}

// Deploy Key Vault
module keyVault 'modules/key-vault.bicep' = {
  name: 'keyVault'
  params: {
    name: keyVaultName
    location: location
    environment: environment
    googleClientId: googleClientId
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

// Create App Registration with enhanced OAuth support
module appRegistration 'modules/app-registration-setup.bicep' = {
  name: 'appRegistration'
  params: {
    appName: baseName
    environment: environment
    location: location
    staticWebAppUrl: 'https://${staticWebAppName}.azurestaticapps.net' // Placeholder URL
  }
}

// Deploy Function App (updated with OAuth and Key Vault integration)
module functionApp 'modules/function-app.bicep' = {
  name: 'functionApp'
  params: {
    name: functionAppName
    location: location
    environment: environment
    storageAccountName: storage.outputs.name
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
    hostingPlanId: hostingPlan.outputs.id
    keyVaultName: keyVault.outputs.name
    microsoftClientId: appRegistration.outputs.appId
    microsoftTenantId: appRegistration.outputs.tenantId
    googleClientId: googleClientId
  }
  dependsOn: [
    keyVault
    appRegistration
  ]
}

// Grant Function App access to Key Vault
module keyVaultAccess 'modules/key-vault-access.bicep' = {
  name: 'keyVaultAccess'
  params: {
    keyVaultName: keyVault.outputs.name
    functionAppPrincipalId: functionApp.outputs.principalId
    storageAccountName: storage.outputs.name
    functionAppPrincipalId2: functionApp.outputs.principalId // For storage access
  }
  dependsOn: [
    functionApp
  ]
}

// Deploy Static Web App (updated for API-first approach)
module staticWebApp 'modules/static-web-app.bicep' = {
  name: 'staticWebApp'
  params: {
    name: staticWebAppName
    location: location
    environment: environment
    functionAppUrl: functionApp.outputs.functionAppUrl
  }
  dependsOn: [
    functionApp
  ]
}

// Outputs
output storageAccountName string = storage.outputs.name
output functionAppName string = functionApp.outputs.name
output staticWebAppName string = staticWebApp.outputs.name
output functionAppUrl string = functionApp.outputs.functionAppUrl
output staticWebAppUrl string = staticWebApp.outputs.url
output keyVaultName string = keyVault.outputs.name
output microsoftAppId string = appRegistration.outputs.appId
output microsoftTenantId string = appRegistration.outputs.tenantId
output functionAppPrincipalId string = functionApp.outputs.principalId
```

### 3. Create New `infrastructure/modules/key-vault.bicep`

```bicep
@description('The name of the key vault')
param name string

@description('The location for the key vault')
param location string

@description('The environment name')
param environment string

@description('Google OAuth Client ID')
param googleClientId string = ''

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: name
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true // Use RBAC instead of access policies
    enableSoftDelete: true
    softDeleteRetentionInDays: environment == 'prod' ? 90 : 7
    enablePurgeProtection: environment == 'prod' ? true : false
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
  tags: {
    Environment: environment
    Project: 'PodcastHostingService'
  }
}

// Store Google OAuth Client Secret (to be updated manually)
resource googleClientSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = if (!empty(googleClientId)) {
  parent: keyVault
  name: 'GoogleClientSecret'
  properties: {
    value: 'PLACEHOLDER-UPDATE-MANUALLY' // You'll update this manually after creating Google OAuth app
  }
}

// JWT Signing Key (auto-generated)
resource jwtSigningKey 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'JWTSigningKey'
  properties: {
    value: base64(guid(resourceGroup().id, 'jwt-signing-key', environment))
  }
}

// Encryption key for sensitive data
resource encryptionKey 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'DataEncryptionKey'
  properties: {
    value: base64(guid(resourceGroup().id, 'data-encryption', environment))
  }
}

// Outputs
output name string = keyVault.name
output id string = keyVault.id
output uri string = keyVault.properties.vaultUri
```

### 4. Create New `infrastructure/modules/key-vault-access.bicep`

```bicep
@description('The name of the key vault')
param keyVaultName string

@description('The Function App principal ID')
param functionAppPrincipalId string

@description('The storage account name')
param storageAccountName string

@description('The Function App principal ID for storage access (same as above)')
param functionAppPrincipalId2 string

// Get existing Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// Get existing Storage Account
