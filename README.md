# Podcast Hosting Service

A complete podcast hosting solution with C# Azure Functions backend, Azure Blob Storage, and a Vue.js frontend with OAuth authentication.

## Project Structure

- `/backend` - C# Azure Functions backend for podcast management
- `/frontend` - Vue.js frontend application for podcast owners

## Prerequisites

- [.NET 6 SDK](https://dotnet.microsoft.com/download/dotnet/6.0) or later
- [Azure Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Azure Storage Account](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-create)
- [Node.js](https://nodejs.org/) (for Vue.js frontend)

## Setup Instructions

### Backend Setup

1. Install Azure Functions Core Tools (if not already installed):
   ```
   dotnet tool install --global Microsoft.Azure.Functions.Worker.Tools
   ```

2. Navigate to the backend directory:
   ```
   cd backend
   ```

3. Create a `local.settings.json` file with your Azure Storage connection string:
   ```json
   {
     "IsEncrypted": false,
     "Values": {
       "AzureWebJobsStorage": "YOUR_AZURE_STORAGE_CONNECTION_STRING",
       "FUNCTIONS_WORKER_RUNTIME": "dotnet",
       "BlobStorageConnection": "YOUR_AZURE_STORAGE_CONNECTION_STRING"
     },
     "Host": {
       "CORS": "*"
     }
   }
   ```

4. Build the project:
   ```
   dotnet build
   ```

5. Start the Azure Functions locally:
   ```
   func start
   ```

### Frontend Setup

1. Navigate to the frontend directory:
   ```
   cd frontend
   ```

2. Install dependencies:
   ```
   npm install
   ```

3. Create a `.env` file with your Azure Function API URL and authentication settings:
   ```
   VUE_APP_API_URL=http://localhost:7071/api
   VUE_APP_AUTH_CLIENT_ID=YOUR_AUTH_CLIENT_ID
   VUE_APP_AUTH_AUTHORITY=https://login.microsoftonline.com/YOUR_TENANT_ID
   ```

4. Start the Vue.js development server:
   ```
   npm run serve
   ```

## Infrastructure as Code

This project uses Azure Bicep templates for Infrastructure as Code deployment with **automatic Azure AD app registration creation**. Each environment (dev, staging, prod) gets its own dedicated app registration.

### Prerequisites for Deployment

1. **Azure CLI** installed and authenticated
2. **PowerShell** (for app registration scripts)
3. **Azure AD Permissions** - one of the following:
   - `Application Administrator` role in Azure AD
   - `Application.ReadWrite.All` permission in Microsoft Graph

### Quick Deployment

1. **Deploy to Dev Environment:**
   ```bash
   az deployment group create \
     --resource-group rg-podcast-dev \
     --template-file infrastructure/main.bicep \
     --parameters infrastructure/parameters/dev.json
   ```

2. **Deploy to Production:**
   ```bash
   az deployment group create \
     --resource-group rg-podcast-prod \
     --template-file infrastructure/main.bicep \
     --parameters infrastructure/parameters/prod.json
   ```

### What Gets Deployed

- **Azure Function App** (backend API)
- **Azure Static Web App** (frontend hosting)
- **Azure Storage Account** (blob storage for podcasts)
- **Application Insights** (monitoring)
- **Azure AD App Registration** (authentication) - **Created Automatically!**

### App Registration Features

- ✅ **Automatic Creation**: App registrations are created during deployment
- ✅ **Environment Isolation**: Separate apps for dev/staging/prod
- ✅ **Dynamic Configuration**: Redirect URIs configured with actual deployed URLs
- ✅ **Idempotent**: Safe to run multiple times
- ✅ **No Manual Setup Required**: No need to manually create app registrations

### Detailed Deployment Guide

For complete deployment instructions, troubleshooting, and security considerations, see:
📖 **[App Registration Deployment Guide](infrastructure/APP_REGISTRATION_DEPLOYMENT_GUIDE.md)**

### Testing App Registration

After deployment, verify your app registration was created:

```powershell
# Test app registration for dev environment
.\infrastructure\scripts\test-app-registration.ps1 -Environment "dev"

# Test app registration for production
.\infrastructure\scripts\test-app-registration.ps1 -Environment "prod"
```

## Manual Deployment (Legacy)

<details>
<summary>Click to expand manual deployment instructions</summary>

### Backend Deployment

1. Create an Azure Function App:
   ```
   az functionapp create --resource-group YourResourceGroup --consumption-plan-location westus --runtime dotnet --functions-version 4 --name YourFunctionAppName --storage-account YourStorageAccountName
   ```

2. Deploy the function app:
   ```
   func azure functionapp publish YourFunctionAppName
   ```

### Frontend Deployment

1. Build the Vue.js app:
   ```
   npm run build
   ```

2. Deploy to Azure Static Web Apps or your preferred hosting service.

</details>
