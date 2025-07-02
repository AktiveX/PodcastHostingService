# Setup Scripts

This directory contains automation scripts to help set up Azure OIDC authentication for GitHub Actions.

## Quick Start (Recommended)

### Complete Setup Script (Windows PowerShell)

**File:** `Complete-AzureOIDCSetup.ps1` - **⭐ RECOMMENDED FOR MOST USERS**

This comprehensive script handles the entire OIDC setup process with enhanced features:

**Quick Run:**
```powershell
# Simple execution with pre-configured repository settings
.\scripts\Run-PodcastOIDCSetup.ps1
```

**Advanced Usage:**
```powershell
# Basic usage
.\scripts\Complete-AzureOIDCSetup.ps1 -GitHubOrg "YourOrg" -GitHubRepo "YourRepo"

# Preview mode (see what would be done without making changes)
.\scripts\Complete-AzureOIDCSetup.ps1 -GitHubOrg "YourOrg" -GitHubRepo "YourRepo" -WhatIf

# Custom app name and skip browser opening
.\scripts\Complete-AzureOIDCSetup.ps1 -GitHubOrg "YourOrg" -GitHubRepo "YourRepo" -AppName "my-app" -SkipBrowser
```

**Enhanced Features:**
- ✅ **Complete automation** - handles entire setup process
- ✅ **Error handling** with detailed messages and recovery guidance
- ✅ **Prerequisites checking** - validates Azure CLI and login status
- ✅ **Colored output** for better readability
- ✅ **WhatIf mode** to preview changes before execution
- ✅ **Secrets file generation** - saves credentials to a text file for easy copying
- ✅ **Browser integration** - optionally opens GitHub settings page
- ✅ **Comprehensive validation** - checks for existing resources to avoid duplicates

**Parameters:**
- `-GitHubOrg` (required): Your GitHub organization or username
- `-GitHubRepo` (required): Your repository name
- `-AppName` (optional): Custom name for the Azure App Registration (default: "podcast-hosting-github-oidc")
- `-WhatIf` (optional): Show what would be done without making changes
- `-SkipBrowser` (optional): Don't open GitHub repository settings in browser

## GitHub Secrets Setup

### Add GitHub Secrets Script

**File:** `Add-GitHubSecrets.ps1` - **✅ TESTED AND VALIDATED**

This script automatically adds the Azure OIDC secrets to your GitHub repository using GitHub CLI:

**Usage:**
```powershell
# Basic usage (uses default repository settings)
.\scripts\Add-GitHubSecrets.ps1

# Custom repository
.\scripts\Add-GitHubSecrets.ps1 -GitHubOrg "YourOrg" -GitHubRepo "YourRepo"

# Custom secrets file
.\scripts\Add-GitHubSecrets.ps1 -SecretsFile "custom-secrets.txt"
```

**Features:**
- ✅ **Automatic secret upload** to GitHub repository
- ✅ **Validation and verification** of added secrets
- ✅ **GitHub CLI integration** with authentication check
- ✅ **Error handling** with clear status messages
- ✅ **Post-setup verification** to confirm all secrets are configured

**Prerequisites:**
- GitHub CLI installed and authenticated (`gh auth login`)
- Azure OIDC setup completed (azure-secrets.txt file present)

## 📁 Current Scripts Directory

All scripts have been optimized for PowerShell and are emoji-free for maximum compatibility:

```
scripts/
├── Add-GitHubSecrets.ps1           # ✅ GitHub secrets automation
├── azure-secrets.txt               # ✅ Generated OIDC credentials
├── Complete-AzureOIDCSetup.ps1     # ✅ Comprehensive OIDC setup
├── README.md                       # ✅ This documentation
├── Run-PodcastOIDCSetup.ps1        # ✅ Interactive setup wrapper
├── CLEANUP_SUMMARY.md              # 📄 Cleanup documentation
└── SCRIPT_FUNCTIONALITY_COMPARISON.md  # 📄 Script analysis
```

**Note**: All redundant and bash scripts have been removed for clarity. Only PowerShell scripts optimized for Windows development remain.

## What These Scripts Do

1. **Create Azure App Registration**: Sets up an Azure AD application for OIDC authentication
2. **Create Service Principal**: Creates a service principal from the app registration
3. **Assign Permissions**: Grants necessary Azure permissions (Contributor, User Access Administrator)
4. **Configure Federated Credentials**: Sets up OIDC trust relationships for GitHub branches (main, staging, dev) and pull requests
5. **Display Configuration**: Shows the secrets you need to add to your GitHub repository

## Prerequisites

- **Azure CLI** installed and authenticated (`az login`)
- **Appropriate Azure permissions** to create app registrations and assign roles
- **GitHub repository** with Actions enabled

## After Running the Script

The script will output three values that you need to add as secrets to your GitHub repository:

```
AZURE_CLIENT_ID = <application-id>
AZURE_TENANT_ID = <tenant-id>
AZURE_SUBSCRIPTION_ID = <subscription-id>
```

### Adding Secrets to GitHub

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** for each of the three secrets above
4. Create GitHub environments: `dev`, `staging`, `prod` (optional but recommended)

## Security Benefits

Using these scripts to set up OIDC authentication provides:

- ✅ **No long-lived secrets** stored in GitHub
- ✅ **Short-lived tokens** that expire automatically
- ✅ **Better audit trail** in Azure AD logs
- ✅ **Reduced credential management** overhead
- ✅ **Enhanced security posture**

## Troubleshooting

### Common Issues

1. **"az command not found"**
   - Install Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

2. **"Not logged into Azure"**
   - Run `az login` and select the correct subscription

3. **"Insufficient permissions"**
   - Ensure you have permissions to create app registrations and assign roles in Azure

4. **"GitHub Actions still failing"**
   - Verify the secrets are correctly added to GitHub
   - Check that the repository and organization names match exactly
   - Ensure the workflow has the correct OIDC permissions

### Getting Help

- Review the detailed setup guide: [`AZURE_OIDC_SETUP_GUIDE.md`](../AZURE_OIDC_SETUP_GUIDE.md)
- Check the updated deployment guide: [`DEPLOYMENT_GUIDE.md`](../DEPLOYMENT_GUIDE.md)
- Verify the GitHub Actions workflow: [`.github/workflows/infrastructure.yml`](../.github/workflows/infrastructure.yml)

## Manual Setup

If you prefer to set up OIDC authentication manually, follow the comprehensive guide in [`AZURE_OIDC_SETUP_GUIDE.md`](../AZURE_OIDC_SETUP_GUIDE.md).