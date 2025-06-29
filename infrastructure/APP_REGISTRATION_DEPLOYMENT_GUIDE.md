# App Registration Deployment Guide

This guide explains how to deploy the PodcastHostingService infrastructure with automatic Azure AD app registration creation.

## Overview

The infrastructure now automatically creates Azure AD app registrations as part of the deployment process. Each environment (dev, staging, prod) gets its own dedicated app registration with the naming pattern: `podcast-{environment}`.

## Prerequisites

### 1. Azure AD Permissions

The deployment account (service principal or user) needs one of the following:

**Option A: Azure AD Role**
- `Application Administrator` role in Azure AD

**Option B: Microsoft Graph API Permissions**
- `Application.ReadWrite.All` permission in Microsoft Graph

### 2. Azure Subscription Permissions

The deployment account needs:
- `Contributor` role on the target subscription or resource group
- `User Access Administrator` role to create role assignments for the managed identity

## Deployment Process

### 1. Grant Required Permissions

Before deploying, ensure your deployment account has the necessary permissions:

```powershell
# Check current user permissions
az ad signed-in-user show
az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv)

# If using a service principal, grant Application Administrator role
az role assignment create \
  --role "Application Administrator" \
  --assignee <service-principal-object-id> \
  --scope /

# Or grant specific Graph permissions (requires admin consent)
az ad app permission add \
  --id <your-app-id> \
  --api 00000003-0000-0000-c000-000000000000 \
  --api-permissions 1bfefb4e-e0b5-418b-a88f-73c46d1d8e2e=Role

az ad app permission grant \
  --id <your-app-id> \
  --api 00000003-0000-0000-c000-000000000000

az ad app permission admin-consent --id <your-app-id>
```

### 2. Deploy Infrastructure

Deploy using your preferred method:

**Azure CLI:**
```bash
# Deploy to dev environment
az deployment group create \
  --resource-group rg-podcast-dev \
  --template-file infrastructure/main.bicep \
  --parameters infrastructure/parameters/dev.json

# Deploy to staging environment
az deployment group create \
  --resource-group rg-podcast-staging \
  --template-file infrastructure/main.bicep \
  --parameters infrastructure/parameters/staging.json

# Deploy to production environment
az deployment group create \
  --resource-group rg-podcast-prod \
  --template-file infrastructure/main.bicep \
  --parameters infrastructure/parameters/prod.json
```

**Azure PowerShell:**
```powershell
# Deploy to dev environment
New-AzResourceGroupDeployment `
  -ResourceGroupName "rg-podcast-dev" `
  -TemplateFile "infrastructure/main.bicep" `
  -TemplateParameterFile "infrastructure/parameters/dev.json"
```

### 3. Verify Deployment

After deployment, verify the app registrations were created:

```bash
# List app registrations
az ad app list --display-name "podcast-dev" --query "[].{Name:displayName, AppId:appId, ObjectId:id}"
az ad app list --display-name "podcast-staging" --query "[].{Name:displayName, AppId:appId, ObjectId:id}"
az ad app list --display-name "podcast-prod" --query "[].{Name:displayName, AppId:appId, ObjectId:id}"
```

## What Gets Created

### App Registration Configuration

Each app registration is configured with:

- **Display Name**: `podcast-{environment}` (e.g., `podcast-dev`)
- **Sign-in Audience**: Single tenant (AzureADMyOrg)
- **Authentication Flow**: Authorization Code with PKCE (no client secret)
- **API Permissions**: User.Read (Microsoft Graph)

### Redirect URIs

The following redirect URIs are automatically configured:

- `https://{static-web-app-url}` - Production URL
- `https://{static-web-app-url}/.auth/login/aad/callback` - Azure Static Web Apps auth callback
- `http://localhost:3000` - Local development (React/Next.js)
- `http://localhost:5173` - Local development (Vite)

### Tags

Each app registration includes tags for organization:
- `Environment`: dev/staging/prod
- `Project`: PodcastHostingService

## Deployment Script Details

### Key Components

1. **PowerShell Script** (`infrastructure/scripts/manage-app-registration.ps1`)
   - Checks for existing app registrations
   - Creates new ones if they don't exist
   - Updates redirect URIs for existing registrations
   - Handles both local and Azure-hosted execution

2. **Bicep Module** (`infrastructure/modules/app-registration-setup.bicep`)
   - Creates managed identity for script execution
   - Assigns necessary permissions
   - Executes PowerShell script via deployment script resource
   - Parses and outputs app registration details

3. **Main Template Updates** (`infrastructure/main.bicep`)
   - Orchestrates the deployment sequence
   - Creates Static Web App first to get URL
   - Creates app registration with actual URLs
   - Updates Static Web App configuration with auth details

## Troubleshooting

### Common Issues

**1. Permission Denied Errors**
```
Error: Insufficient privileges to complete the operation
```
- Ensure the deployment account has Application Administrator role or appropriate Graph permissions
- Wait up to 15 minutes for role assignments to propagate

**2. Module Installation Failures**
```
Error: Unable to install module Microsoft.Graph.Applications
```
- The script automatically installs required PowerShell modules
- Ensure the execution environment allows module installation
- For Azure DevOps agents, consider pre-installing modules

**3. App Registration Already Exists**
```
Warning: App registration already exists with ID: xxx
```
- This is normal behavior - the script is idempotent
- Existing app registrations will be updated with current redirect URIs

**4. Deployment Script Timeout**
```
Error: Deployment script execution timed out
```
- Increase timeout in the Bicep template (currently 30 minutes)
- Check Azure portal for detailed script execution logs

### Debugging

1. **Check Deployment Script Logs**:
   - Navigate to Azure Portal > Resource Groups > Deployment Scripts
   - View execution logs and outputs

2. **Verify Managed Identity Permissions**:
   ```bash
   az role assignment list --assignee <managed-identity-object-id>
   ```

3. **Manual Script Testing**:
   ```powershell
   # Test the PowerShell script locally
   .\infrastructure\scripts\manage-app-registration.ps1 `
     -AppName "podcast" `
     -Environment "dev" `
     -StaticWebAppUrl "https://your-static-web-app.azurestaticapps.net"
   ```

## Security Considerations

- App registrations use authorization code flow with PKCE (no client secrets)
- Managed identity has minimal required permissions
- Deployment scripts are cleaned up after successful execution
- Each environment has isolated app registrations

## Maintenance

### Updating Redirect URIs

If you need to add additional redirect URIs, update the PowerShell script in the `$redirectUris` array section.

### Changing App Registration Names

Modify the `$displayName` variable in the PowerShell script or the `appName` parameter in your Bicep deployment.

### Adding API Permissions

Update the `RequiredResourceAccess` section in the PowerShell script to include additional Microsoft Graph or other API permissions.
