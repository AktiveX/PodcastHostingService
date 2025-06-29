# GitHub Actions Workflow Fixes

## Critical Issues Identified

### 1. **Missing Required Secrets and Variables**
The workflows reference secrets and variables that need to be configured in GitHub:

**Missing Secrets:**
- `AZURE_CREDENTIALS` - Service Principal credentials for Azure authentication
- `AZURE_FUNCTIONAPP_PUBLISH_PROFILE_DEV` - Function App publish profile for dev
- `AZURE_FUNCTIONAPP_PUBLISH_PROFILE_STAGING` - Function App publish profile for staging
- `AZURE_FUNCTIONAPP_PUBLISH_PROFILE_PROD` - Function App publish profile for prod

**Missing Variables:**
- `AAD_TENANT_ID` - Azure Active Directory Tenant ID
- `AAD_CLIENT_ID` - Azure Active Directory Client ID

### 2. **Parameter Files Have Placeholder Values**
The Bicep parameter files contain placeholder values:
- `tenantId: "YOUR_TENANT_ID"`
- `clientId: "YOUR_CLIENT_ID"`

### 3. **Environment Variable Reference Logic Error**
In the resource group determination logic, there's a self-referencing issue in the infrastructure workflow.

### 4. **Frontend Package-lock.json Missing**
The frontend workflow references `package-lock.json` for caching, but the file doesn't exist.

### 5. **Test Project Missing**
The backend workflow tries to run `dotnet test` but there's no test project in the solution.

### 6. **GitHub Environments Not Created**
The workflows reference GitHub Environments (dev, staging, prod) that need to be created manually.

## Required Setup Steps

### Step 1: Create GitHub Environments
1. Go to your repository → Settings → Environments
2. Create three environments: `dev`, `staging`, `prod`
3. For `prod` environment, add required reviewers for manual approval

### Step 2: Configure Azure Service Principal
```bash
# Create service principal with contributor role
az ad sp create-for-rbac --name "podcast-hosting-sp" \
  --role contributor \
  --scopes /subscriptions/{subscription-id} \
  --sdk-auth
```

### Step 3: Add GitHub Secrets
Add these secrets to your repository (Settings → Secrets and variables → Actions):

**Repository Secrets:**
- `AZURE_CREDENTIALS`: The complete JSON output from the service principal creation

**Environment-Specific Secrets (add to each environment):**
- `AZURE_FUNCTIONAPP_PUBLISH_PROFILE_DEV`: Get from Azure Portal after Function App is created
- `AZURE_FUNCTIONAPP_PUBLISH_PROFILE_STAGING`: Get from Azure Portal after Function App is created  
- `AZURE_FUNCTIONAPP_PUBLISH_PROFILE_PROD`: Get from Azure Portal after Function App is created

### Step 4: Add GitHub Variables
Add these variables at the repository level:
- `AAD_TENANT_ID`: Your Azure AD Tenant ID
- `AAD_CLIENT_ID`: Your Azure AD Application Client ID

### Step 5: Update Parameter Files
Replace placeholder values in:
- `infrastructure/parameters/dev.json`
- `infrastructure/parameters/staging.json`
- `infrastructure/parameters/prod.json`

Replace:
```json
"tenantId": { "value": "YOUR_TENANT_ID" }
"clientId": { "value": "YOUR_CLIENT_ID" }
```

With your actual values:
```json
"tenantId": { "value": "your-actual-tenant-id" }
"clientId": { "value": "your-actual-client-id" }
```

## Workflow Execution Order

### For First-Time Deployment:
1. **Infrastructure First**: Deploy via manual trigger or push to infrastructure/
2. **Get Publish Profiles**: Download from Azure Portal after Function Apps are created
3. **Add Publish Profiles**: Add to GitHub Environment secrets
4. **Backend Deployment**: Will work after publish profiles are added
5. **Frontend Deployment**: Will work after backend is deployed

### For Subsequent Deployments:
The workflows will automatically detect changes and deploy the appropriate components.

## Testing the Fixes

### Test Infrastructure Deployment:
1. Update parameter files with real values
2. Add AZURE_CREDENTIALS secret
3. Manually trigger Infrastructure Deployment workflow
4. Check Azure Portal for created resources

### Test Backend Deployment:
1. Ensure infrastructure is deployed
2. Get Function App publish profile from Azure Portal
3. Add publish profile to GitHub environment secrets
4. Manually trigger Backend Deployment workflow

### Test Frontend Deployment:
1. Ensure backend is deployed
2. Add AAD_TENANT_ID and AAD_CLIENT_ID variables
3. Manually trigger Frontend Deployment workflow

## Common Error Solutions

### "Azure login failed"
- Verify AZURE_CREDENTIALS secret is correctly formatted JSON
- Check service principal has proper permissions

### "Resource group not found"
- Ensure infrastructure deployment completed successfully
- Check resource group naming in workflows

### "Function App not found"
- Verify infrastructure deployment created Function App
- Check Function App naming convention

### "Static Web App deployment failed"
- Ensure frontend build succeeds locally
- Check output_location is correct ("dist")

### "Environment not found"
- Create GitHub Environments in repository settings
- Ensure environment names match workflow references
