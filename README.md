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

## Deployment

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
