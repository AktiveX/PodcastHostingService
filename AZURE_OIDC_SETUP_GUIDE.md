# Azure OIDC Authentication Setup for GitHub Actions

This guide walks you through setting up secure OpenID Connect (OIDC) authentication between GitHub Actions and Azure, replacing the deprecated service principal credential approach.

## Why OIDC Authentication?

OIDC authentication provides several security benefits over traditional service principal credentials:
- **No long-lived secrets**: No need to store Azure credentials in GitHub secrets
- **Short-lived tokens**: Each workflow gets a temporary token that expires quickly
- **Better audit trail**: Enhanced logging and monitoring of authentication events
- **Reduced credential management**: No need to rotate service principal secrets

## Prerequisites

- Azure subscription with appropriate permissions
- GitHub repository with Actions enabled
- Azure CLI installed locally
- PowerShell or Bash terminal

## Step 1: Create Azure App Registration

Create an Azure App Registration that will be used for OIDC authentication:

```bash
# Create the app registration
az ad app create --display-name "podcast-hosting-github-oidc"

# Get the Application (Client) ID - save this value
APP_ID=$(az ad app list --display-name "podcast-hosting-github-oidc" --query "[0].appId" -o tsv)
echo "Application ID: $APP_ID"

# Get your Tenant ID - save this value
TENANT_ID=$(az account show --query tenantId -o tsv)
echo "Tenant ID: $TENANT_ID"

# Get your Subscription ID - save this value
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "Subscription ID: $SUBSCRIPTION_ID"
```

## Step 2: Create Service Principal

Create a service principal from the app registration:

```bash
# Create service principal
az ad sp create --id $APP_ID

# Get the Object ID of the service principal
SP_OBJECT_ID=$(az ad sp show --id $APP_ID --query id -o tsv)
echo "Service Principal Object ID: $SP_OBJECT_ID"
```

## Step 3: Assign Azure Permissions

Grant the service principal necessary permissions for your deployments:

```bash
# Assign Contributor role at subscription level
az role assignment create \
  --assignee $APP_ID \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

# Assign User Access Administrator role (needed for role assignments in deployment)
az role assignment create \
  --assignee $APP_ID \
  --role "User Access Administrator" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

## Step 4: Configure OIDC Federated Identity

Create federated identity credentials for your GitHub repository:

```bash
# Set your GitHub repository details
GITHUB_ORG="YOUR_GITHUB_ORG"  # Replace with your GitHub organization/username
GITHUB_REPO="YOUR_REPO_NAME"  # Replace with your repository name

# Create federated credential for main branch
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "podcast-hosting-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':ref:refs/heads/main",
    "description": "GitHub Actions OIDC for main branch",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Create federated credential for staging branch
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "podcast-hosting-staging",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':ref:refs/heads/staging",
    "description": "GitHub Actions OIDC for staging branch",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Create federated credential for dev branch
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "podcast-hosting-dev",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':ref:refs/heads/dev",
    "description": "GitHub Actions OIDC for dev branch",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Create federated credential for pull requests (optional)
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "podcast-hosting-pr",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:'$GITHUB_ORG'/'$GITHUB_REPO':pull_request",
    "description": "GitHub Actions OIDC for pull requests",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

## Step 5: Configure GitHub Repository Secrets

Add the following secrets to your GitHub repository:

### Repository-Level Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions, then add:

```
AZURE_CLIENT_ID = <Application ID from Step 1>
AZURE_TENANT_ID = <Tenant ID from Step 1>
AZURE_SUBSCRIPTION_ID = <Subscription ID from Step 1>
```

### Environment-Specific Variables (Optional)

For each environment (dev, staging, prod), you can add environment-specific variables:

1. Go to Settings → Environments
2. Create environments: `dev`, `staging`, `prod`
3. Add environment-specific variables if needed

## Step 6: Update GitHub Actions Workflow

Your workflow is already updated to use OIDC authentication. The key changes are:

1. **Added OIDC permissions**:
   ```yaml
   permissions:
     id-token: write
     contents: read
   ```

2. **Updated Azure Login step**:
   ```yaml
   - name: Azure Login with OIDC
     uses: azure/login@v1
     with:
       client-id: ${{ secrets.AZURE_CLIENT_ID }}
       tenant-id: ${{ secrets.AZURE_TENANT_ID }}
       subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
   ```

## Step 7: Remove Old Service Principal (Optional)

If you were previously using service principal authentication, you can now remove the old credentials:

```bash
# List existing service principals (find the old one)
az ad sp list --display-name "podcast-hosting-sp" --query "[].{Name:displayName, AppId:appId}"

# Delete old service principal if it exists
az ad sp delete --id <OLD_SERVICE_PRINCIPAL_APP_ID>
```

## Step 8: Test the Setup

1. Push a change to your `dev` branch to trigger the workflow
2. Check the GitHub Actions logs to verify successful Azure authentication
3. Look for the "Azure Login with OIDC" step completing successfully

## Troubleshooting

### Common Issues

1. **"AADSTS70021: No matching federated identity record found"**
   - Verify the federated identity credential subject matches your repository exactly
   - Check the branch name in the federated credential matches the triggering branch

2. **"AADSTS50126: Invalid username or password"**
   - Verify the Client ID, Tenant ID, and Subscription ID are correct
   - Ensure the App Registration has been properly created

3. **"AuthorizationFailed: The client does not have authorization to perform action"**
   - Check that the service principal has the necessary role assignments
   - Verify the scope of the role assignments includes your subscription/resource groups

### Verification Commands

```bash
# Verify app registration exists
az ad app show --id $APP_ID

# Verify service principal exists
az ad sp show --id $APP_ID

# List federated credentials
az ad app federated-credential list --id $APP_ID

# Check role assignments
az role assignment list --assignee $APP_ID --include-inherited
```

## Security Best Practices

1. **Principle of Least Privilege**: Only grant necessary permissions to the service principal
2. **Environment Isolation**: Use separate app registrations for different environments if needed
3. **Regular Auditing**: Periodically review federated identity credentials and role assignments
4. **Monitor Usage**: Use Azure Activity Logs to monitor authentication and deployment activities

## Next Steps

After completing this setup:

1. Test deployments to all environments (dev, staging, prod)
2. Update your team documentation to reflect the new authentication method
3. Remove any old service principal credentials from GitHub secrets
4. Set up monitoring and alerting for deployment activities

## Support

If you encounter issues:
1. Check the GitHub Actions logs for detailed error messages
2. Review Azure Activity Logs for authentication attempts
3. Verify all federated identity credentials are correctly configured
4. Ensure the GitHub repository and branch names match exactly

This OIDC setup provides a more secure and maintainable authentication method for your Azure deployments.