# Setup Scripts

This directory contains automation scripts to help set up Azure OIDC authentication for GitHub Actions.

## Azure OIDC Setup Scripts

These scripts automate the process of configuring OpenID Connect (OIDC) authentication between GitHub Actions and Azure, eliminating the need for long-lived service principal credentials.

### PowerShell Script (Windows)

**File:** `setup-azure-oidc.ps1`

**Usage:**
```powershell
# Basic usage
.\scripts\setup-azure-oidc.ps1 -GitHubOrg "YourGitHubOrg" -GitHubRepo "YourRepoName"

# With custom app name
.\scripts\setup-azure-oidc.ps1 -GitHubOrg "YourOrg" -GitHubRepo "YourRepo" -AppName "my-custom-app"

# Preview mode (see what would be done without making changes)
.\scripts\setup-azure-oidc.ps1 -GitHubOrg "YourOrg" -GitHubRepo "YourRepo" -WhatIf
```

**Parameters:**
- `-GitHubOrg` (required): Your GitHub organization or username
- `-GitHubRepo` (required): Your repository name
- `-AppName` (optional): Custom name for the Azure App Registration (default: "podcast-hosting-github-oidc")
- `-WhatIf` (optional): Show what would be done without making changes

### Bash Script (Linux/macOS)

**File:** `setup-azure-oidc.sh`

**Usage:**
```bash
# Make script executable (Linux/macOS only)
chmod +x scripts/setup-azure-oidc.sh

# Basic usage
./scripts/setup-azure-oidc.sh -o "YourGitHubOrg" -r "YourRepoName"

# With custom app name
./scripts/setup-azure-oidc.sh -o "YourOrg" -r "YourRepo" -n "my-custom-app"

# Preview mode
./scripts/setup-azure-oidc.sh -o "YourOrg" -r "YourRepo" --whatif

# Show help
./scripts/setup-azure-oidc.sh --help
```

**Parameters:**
- `-o, --org` (required): Your GitHub organization or username
- `-r, --repo` (required): Your repository name
- `-n, --name` (optional): Custom name for the Azure App Registration
- `-w, --whatif` (optional): Show what would be done without making changes
- `-h, --help`: Show help message

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