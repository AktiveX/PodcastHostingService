# Complete Setup Instructions for Podcast Hosting Service

## Step 1: Install Required Tools

### Install Azure CLI
**Windows:**
1. Download from: https://aka.ms/installazurecliwindows
2. Run the installer
3. Restart your terminal
4. Verify: `az --version`

**Alternative (PowerShell):**
```powershell
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; Remove-Item .\AzureCLI.msi
```

### Install GitHub CLI (Optional but recommended)
```powershell
winget install --id GitHub.cli
```

## Step 2: Azure Setup

### Login to Azure
```bash
az login
```

### Set your subscription
```bash
# List available subscriptions
az account list --output table

# Set the subscription you want to use
az account set --subscription "your-subscription-id"
```

### Create Service Principal
```bash
# Replace {subscription-id} with your actual subscription ID
az ad sp create-for-rbac --name "podcast-hosting-sp" \
  --role contributor \
  --scopes /subscriptions/{subscription-id} \
  --sdk-auth
```

**Save the output** - you'll need this entire JSON for GitHub secrets!

### Create Azure AD App Registration
```bash
# Create the app registration
az ad app create --display-name "podcast-hosting-app"

# Get the app details (save these values)
az ad app list --display-name "podcast-hosting-app" --query "[0].{appId:appId}" --output table
```

**Save the Application (Client) ID and your Tenant ID**

## Step 3: Update Parameter Files

Update these files with your actual values:

### infrastructure/parameters/dev.json
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environment": {
      "value": "dev"
    },
    "location": {
      "value": "East US"
    },
    "baseName": {
      "value": "podcast"
    },
    "tenantId": {
      "value": "YOUR_ACTUAL_TENANT_ID"
    },
    "clientId": {
      "value": "YOUR_ACTUAL_CLIENT_ID"
    }
  }
}
```

### infrastructure/parameters/staging.json
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environment": {
      "value": "staging"
    },
    "location": {
      "value": "East US"
    },
    "baseName": {
      "value": "podcast"
    },
    "tenantId": {
      "value": "YOUR_ACTUAL_TENANT_ID"
    },
    "clientId": {
      "value": "YOUR_ACTUAL_CLIENT_ID"
    }
  }
}
```

### infrastructure/parameters/prod.json
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environment": {
      "value": "prod"
    },
    "location": {
      "value": "East US"
    },
    "baseName": {
      "value": "podcast"
    },
    "tenantId": {
      "value": "YOUR_ACTUAL_TENANT_ID"
    },
    "clientId": {
      "value": "YOUR_ACTUAL_CLIENT_ID"
    }
  }
}
```

## Step 4: GitHub Repository Setup

### Create Repository on GitHub
1. Go to https://github.com/AktiveX
2. Click "+" → "New repository"
3. Name: `PodcastHostingService`
4. Description: `Complete podcast hosting solution with Azure Bicep CI/CD`
5. Make it **Public**
6. **Don't** initialize with README
7. Click "Create repository"

### Push Local Repository to GitHub
```bash
git remote add origin https://github.com/AktiveX/PodcastHostingService.git
git push -u origin main
git push origin dev
git push origin staging
```

## Step 5: Configure GitHub Secrets and Variables

### Create GitHub Environments
1. Go to your repository: https://github.com/AktiveX/PodcastHostingService
2. Go to Settings → Environments
3. Create three environments:
   - **dev** (no protection rules)
   - **staging** (optional: add reviewers)
   - **prod** (required: add required reviewers)

### Add Repository Secrets
Go to Settings → Secrets and variables → Actions → New repository secret

**AZURE_CREDENTIALS**
```json
{
  "clientId": "service-principal-client-id",
  "clientSecret": "service-principal-secret",
  "subscriptionId": "your-subscription-id",
  "tenantId": "your-tenant-id"
}
```
(Use the complete JSON output from the service principal creation)

### Add Repository Variables
Go to Settings → Secrets and variables → Actions → Variables tab

**AAD_TENANT_ID**: Your Azure AD Tenant ID
**AAD_CLIENT_ID**: Your Azure AD Application Client ID

## Step 6: Test Infrastructure Deployment

### Manual Test (Recommended first)
```bash
# Test Bicep template locally
az bicep build --file infrastructure/main.bicep

# Test deployment (what-if)
az deployment group what-if \
  --resource-group rg-podcast-dev \
  --template-file infrastructure/main.bicep \
  --parameters infrastructure/parameters/dev.json
```

### Deploy via GitHub Actions
1. Go to your repository
2. Actions → Infrastructure Deployment
3. Click "Run workflow"
4. Select "dev" environment
5. Click "Run workflow"

## Step 7: Get Function App Publish Profiles

After infrastructure deployment succeeds:

### Download Publish Profiles
```bash
# For dev environment
az functionapp deployment list-publishing-profiles \
  --name "your-function-app-name-dev" \
  --resource-group "rg-podcast-dev" \
  --xml

# For staging environment
az functionapp deployment list-publishing-profiles \
  --name "your-function-app-name-staging" \
  --resource-group "rg-podcast-staging" \
  --xml

# For prod environment
az functionapp deployment list-publishing-profiles \
  --name "your-function-app-name-prod" \
  --resource-group "rg-podcast-prod" \
  --xml
```

### Add Publish Profile to GitHub Secrets
Add this secret to your repository:
**AZURE_FUNCTIONAPP_PUBLISH_PROFILE**: The XML content from the publish profile

## Step 8: Test Full Deployment

1. Make a change to the backend code
2. Commit and push to dev branch
3. Watch the GitHub Actions run
4. Verify deployment in Azure Portal

## Step 9: Promote Through Environments

### Dev → Staging
```bash
git checkout staging
git merge dev
git push origin staging
```

### Staging → Production
```bash
git checkout main
git merge staging
git push origin main
```

## Troubleshooting Commands

### Check Azure Resources
```bash
# List resource groups
az group list --output table

# List resources in a group
az resource list --resource-group rg-podcast-dev --output table

# Check Function App status
az functionapp show --name "your-function-app-name" --resource-group "rg-podcast-dev"
```

### Check GitHub Actions
- Go to repository → Actions tab
- Click on failed workflow
- Check logs for specific errors
- Common issues are in WORKFLOW_FIXES.md

## Quick Reference

### Repository URLs
- **GitHub**: https://github.com/AktiveX/PodcastHostingService  
- **Actions**: https://github.com/AktiveX/PodcastHostingService/actions

### Azure Portal
- **Resource Groups**: Search "rg-podcast" in Azure Portal
- **Function Apps**: Check each environment's resource group
- **Static Web Apps**: Check each environment's resource group

This completes the setup for your production-ready CI/CD pipeline!
