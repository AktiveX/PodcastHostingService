# CI/CD Structure Overview

## Folder Structure

```
PodcastHostingService/
├── infrastructure/                   # Azure Bicep Infrastructure as Code
│   ├── main.bicep                   # Main orchestration template
│   ├── parameters/                  # Environment-specific parameters
│   │   ├── dev.json                # Development environment
│   │   ├── staging.json             # Staging environment
│   │   └── prod.json                # Production environment
│   └── modules/                     # Reusable Bicep modules
│       ├── storage.bicep            # Storage Account + Blob containers
│       ├── app-insights.bicep       # Application Insights monitoring
│       ├── hosting-plan.bicep       # Function App hosting plan
│       ├── function-app.bicep       # Azure Functions backend
│       └── static-web-app.bicep     # Static Web App frontend
├── .github/workflows/               # GitHub Actions CI/CD pipelines
│   ├── infrastructure.yml          # Infrastructure deployment
│   ├── backend.yml                 # Backend (.NET Functions) deployment
│   ├── frontend.yml                # Frontend (Vue.js) deployment
│   └── full-deployment.yml         # Orchestrated full deployment
├── backend/                         # .NET 6 Azure Functions
└── frontend/                        # Vue.js application
```

## Environment Strategy

### Branch-Based Environments
| Branch    | Environment | Resource Group       | Auto-Deploy |
|-----------|-------------|---------------------|-------------|
| `dev`     | Development | `rg-podcast-dev`    | ✅ Yes      |
| `staging` | Staging     | `rg-podcast-staging`| ✅ Yes      |
| `main`    | Production  | `rg-podcast-prod`   | ✅ Yes      |

### Deployment Flow
```
Feature Branch → dev → staging → main
     ↓            ↓       ↓        ↓
   Local       Dev    Staging   Prod
   Testing   Environment Environment Environment
```

## Quick Commands

### Manual Deployment Commands

#### Deploy Infrastructure Only
```bash
# Via GitHub Actions UI:
# Actions → Infrastructure Deployment → Run workflow → Select environment
```

#### Deploy Backend Only  
```bash
# Via GitHub Actions UI:
# Actions → Backend Deployment → Run workflow → Select environment
```

#### Deploy Frontend Only
```bash
# Via GitHub Actions UI:
# Actions → Frontend Deployment → Run workflow → Select environment
```

#### Deploy Everything
```bash
# Via GitHub Actions UI:
# Actions → Full Deployment Pipeline → Run workflow → Select environment and components
```

### Local Development Commands

#### Infrastructure Validation
```bash
# Validate Bicep templates
az bicep build --file infrastructure/main.bicep

# Test deployment (what-if)
az deployment group what-if \
  --resource-group rg-podcast-dev \
  --template-file infrastructure/main.bicep \
  --parameters infrastructure/parameters/dev.json
```

#### Backend Development
```bash
cd backend
dotnet restore
dotnet build
dotnet test
func start  # Local development
```

#### Frontend Development
```bash
cd frontend
npm install
npm run serve  # Local development
npm run build  # Production build
```

## Idempotent Deployment Features

### Infrastructure (Bicep)
- ✅ **Resource Consistency**: Same deployment = same result
- ✅ **Incremental Updates**: Only changes what's different
- ✅ **Dependency Management**: Automatic resource ordering
- ✅ **Rollback Support**: ARM deployment history

### Application Deployments
- ✅ **Immutable Packages**: Each deployment creates new package
- ✅ **Health Checks**: Automatic validation after deployment
- ✅ **Zero Downtime**: Deployment slots for Functions
- ✅ **Configuration Management**: Environment-specific settings

## Monitoring & Observability

### Application Insights Integration
- **Infrastructure**: Automatically configured per environment
- **Backend**: Built-in telemetry and performance monitoring  
- **Frontend**: Custom metrics and error tracking
- **Alerts**: Environment-specific thresholds

### Deployment Monitoring
- **GitHub Actions**: Real-time deployment logs
- **Azure Portal**: Resource deployment status
- **ARM Templates**: Deployment history and outputs

## Security Features

### Authentication & Authorization
- **Service Principal**: Least-privilege access for deployments
- **Environment Protection**: Manual approvals for production
- **Secret Management**: GitHub Secrets + Azure Key Vault integration
- **AAD Integration**: OAuth authentication for frontend

### Network Security
- **HTTPS Only**: All services enforce secure communication
- **CORS Configuration**: Appropriate cross-origin settings
- **Private Endpoints**: Optional for production environments

## Cost Management

### Environment-Specific Optimizations
| Resource Type | Dev | Staging | Prod |
|---------------|-----|---------|------|
| Storage Replication | LRS | LRS | ZRS |
| App Insights Retention | 30 days | 30 days | 90 days |
| Function Plan | Consumption | Consumption | Consumption |
| Static Web App | Free | Free | Standard* |

*Standard tier provides custom domains and enhanced performance

### Estimated Monthly Costs
- **Dev**: $5-15/month
- **Staging**: $10-25/month  
- **Prod**: $20-50/month (varies with usage)

## Troubleshooting Quick Reference

### Common Issues & Solutions

1. **"Resource name already exists"**
   - Bicep templates include unique suffixes
   - Check resource group naming conflicts

2. **"Authentication failed"**
   - Verify `AZURE_CREDENTIALS` secret
   - Check service principal permissions

3. **"Function App publish failed"**
   - Verify publish profile secrets are set
   - Check Function App is in correct resource group

4. **"Static Web App deployment failed"**
   - Verify SWA deployment token
   - Check build output location (`dist`)

### Debug Commands
```bash
# Check deployment status
az deployment group list --resource-group {rg-name}

# View specific deployment
az deployment group show --resource-group {rg-name} --name {deployment-name}

# Function App logs
az webapp log tail --name {function-app-name} --resource-group {rg-name}
```

This structure provides a complete, production-ready CI/CD pipeline with proper environment isolation, security, monitoring, and cost optimization for your Podcast Hosting Service.
