# Podcast Hosting Service - Deployment Guide

This guide provides step-by-step instructions for setting up CI/CD and deploying your Podcast Hosting Service using Azure Bicep and GitHub Actions across three environments: dev, staging, and prod.

## Prerequisites

### Azure Setup
1. **Azure Subscription** with appropriate permissions
2. **Azure CLI** installed locally
3. **Service Principal** for GitHub Actions authentication

### GitHub Setup
1. GitHub repository with your code
2. Three branches: `dev`, `staging`, `main`
3. GitHub Environments configured

## Initial Setup

### 1. Create Azure Service Principal

```bash
# Create service principal
az ad sp create-for-rbac --name "podcast-hosting-sp" --role contributor --scopes /subscriptions/{subscription-id} --sdk-auth

# Save the output - you'll need this for GitHub secrets
```

### 2. Create Azure Active Directory App Registration

```bash
# Create AAD app registration for authentication
az ad app create --display-name "podcast-hosting-app"

# Note the Application (client) ID and Tenant ID
az ad app list --display-name "podcast-hosting-app" --query "[0].{appId:appId,tenantId:publisherDomain}"
```

### 3. Update Parameter Files

Update the parameter files with your actual values:

#### `infrastructure/parameters/dev.json`
```json
{
  "parameters": {
    "tenantId": {
      "value": "YOUR_ACTUAL_TENANT_ID"
    },
    "clientId": {
      "value": "YOUR_ACTUAL_CLIENT_ID"
    }
  }
}
```

Repeat for `staging.json` and `prod.json`.

### 4. GitHub Repository Configuration

#### Create GitHub Environments
1. Go to your repository → Settings → Environments
2. Create three environments: `dev`, `staging`, `prod`
3. Configure protection rules:
   - **prod**: Require manual approval
   - **staging**: Optional approval
   - **dev**: No restrictions

#### Configure GitHub Secrets

**Repository Secrets (Available to all environments):**
```
AZURE_CREDENTIALS = {service-principal-json-output}
```

**Environment-Specific Secrets:**

For each environment (`dev`, `staging`, `prod`), add:
```
AZURE_FUNCTIONAPP_PUBLISH_PROFILE_DEV = {function-app-publish-profile}
AZURE_FUNCTIONAPP_PUBLISH_PROFILE_STAGING = {function-app-publish-profile}
AZURE_FUNCTIONAPP_PUBLISH_PROFILE_PROD = {function-app-publish-profile}
```

**Environment Variables:**
```
AAD_TENANT_ID = {your-tenant-id}
AAD_CLIENT_ID = {your-client-id}
```

## Deployment Workflows

### 1. Infrastructure Deployment (`infrastructure.yml`)
- **Triggers**: Changes to `infrastructure/**` or manual dispatch
- **Purpose**: Deploys Azure resources using Bicep templates
- **Idempotent**: Yes - can be run multiple times safely

### 2. Backend Deployment (`backend.yml`)
- **Triggers**: Changes to `backend/**` or manual dispatch
- **Purpose**: Builds and deploys .NET Azure Functions
- **Features**: Automated testing, health checks

### 3. Frontend Deployment (`frontend.yml`)
- **Triggers**: Changes to `frontend/**` or manual dispatch
- **Purpose**: Builds and deploys Vue.js app to Static Web Apps
- **Features**: Environment-specific configuration

### 4. Full Deployment (`full-deployment.yml`)
- **Triggers**: Any push to tracked branches or manual dispatch
- **Purpose**: Orchestrates complete deployment pipeline
- **Features**: Smart change detection, dependency management

## Branch Strategy

### Environment Mapping
- `dev` branch → Development environment
- `staging` branch → Staging environment  
- `main` branch → Production environment

### Workflow
1. **Development**: Create feature branches, merge to `dev`
2. **Testing**: Promote `dev` → `staging` for integration testing
3. **Production**: Promote `staging` → `main` for production release

## Deployment Process

### First-Time Deployment

1. **Deploy Infrastructure First**:
   ```bash
   # Manually trigger infrastructure deployment
   # Or push changes to infrastructure/ folder
   ```

2. **Deploy Backend**:
   ```bash
   # Will automatically trigger after infrastructure
   # Or manually trigger backend deployment
   ```

3. **Deploy Frontend**:
   ```bash
   # Will automatically trigger after backend
   # Or manually trigger frontend deployment
   ```

### Subsequent Deployments

The system automatically detects changes and deploys only what's needed:
- Infrastructure changes → Full pipeline
- Backend changes → Backend + Frontend
- Frontend changes → Frontend only

## Manual Deployment

Use GitHub Actions → Run workflow for manual deployments:

1. Go to Actions tab in your repository
2. Select the workflow you want to run
3. Click "Run workflow"
4. Select environment and components to deploy

## Monitoring and Troubleshooting

### Application Insights
Each environment includes Application Insights for monitoring:
- Performance metrics
- Error tracking
- Custom telemetry

### Deployment Logs
- Check GitHub Actions logs for deployment status
- Use Azure Portal for runtime logs
- Application Insights for application-level monitoring

### Common Issues

1. **Authentication Failures**
   - Verify service principal permissions
   - Check AAD app registration settings
   - Ensure secrets are correctly configured

2. **Resource Naming Conflicts**
   - Azure resource names must be globally unique
   - Bicep templates include unique suffixes
   - Check resource group naming

3. **Build Failures**
   - Verify .NET 6.0 SDK compatibility
   - Check Node.js version for frontend
   - Review dependency versions

## Security Best Practices

### Infrastructure Security
- Use managed identities where possible
- Enable HTTPS only for all services
- Configure appropriate CORS settings
- Use Azure Key Vault for sensitive data

### CI/CD Security
- Use environment protection rules
- Rotate service principal credentials regularly
- Monitor GitHub Actions usage
- Use least privilege access

### Application Security
- Implement proper authentication flows
- Validate all inputs
- Use secure communication protocols
- Regular security audits

## Cost Optimization

### Environment-Specific Settings
- **Dev**: Basic storage replication, shorter retention
- **Staging**: Standard configurations for testing
- **Prod**: Enhanced replication and longer retention

### Recommendations
- Use consumption-based pricing for Functions
- Monitor storage usage and implement lifecycle policies
- Regular cost analysis and optimization

## Rollback Procedures

### Infrastructure Rollback
```bash
# View deployment history
az deployment group list --resource-group {rg-name}

# Rollback to previous deployment
az deployment group create --resource-group {rg-name} --template-file {previous-template}
```

### Application Rollback
- **Functions**: Use deployment slots for blue-green deployments
- **Static Web Apps**: Built-in version rollback in Azure Portal
- **Configuration**: Git-based rollback of app settings

## Support and Maintenance

### Regular Tasks
- Monitor application performance
- Review and rotate credentials
- Update dependencies
- Backup critical data

### Scaling Considerations
- Functions scale automatically
- Static Web Apps handle traffic spikes
- Storage accounts can be upgraded as needed

This deployment setup provides a robust, scalable, and maintainable CI/CD pipeline for your Podcast Hosting Service across three environments with proper security, monitoring, and rollback capabilities.
