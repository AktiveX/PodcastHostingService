# Complete Azure OIDC Setup Script for GitHub Actions
# This script automates the entire setup process including Azure configuration and GitHub guidance

param(
    [Parameter(Mandatory=$true, HelpMessage="Your GitHub organization or username")]
    [string]$GitHubOrg,
    
    [Parameter(Mandatory=$true, HelpMessage="Your GitHub repository name")]
    [string]$GitHubRepo,
    
    [Parameter(Mandatory=$false, HelpMessage="Name for the Azure App Registration")]
    [string]$AppName = "podcast-hosting-github-oidc",
    
    [Parameter(Mandatory=$false, HelpMessage="Show what would be done without making changes")]
    [switch]$WhatIf,
    
    [Parameter(Mandatory=$false, HelpMessage="Skip opening GitHub repository settings in browser")]
    [switch]$SkipBrowser
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    $colorMap = @{
        "Red" = [ConsoleColor]::Red
        "Green" = [ConsoleColor]::Green
        "Yellow" = [ConsoleColor]::Yellow
        "Blue" = [ConsoleColor]::Blue
        "Cyan" = [ConsoleColor]::Cyan
        "Magenta" = [ConsoleColor]::Magenta
        "Gray" = [ConsoleColor]::Gray
        "White" = [ConsoleColor]::White
    }
    
    Write-Host $Message -ForegroundColor $colorMap[$Color]
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-ColorOutput "`n=== Checking Prerequisites ===" -Color "Cyan"
    
    # Check if Azure CLI is installed
    try {
        $azVersion = az version --output json 2>$null | ConvertFrom-Json
        Write-ColorOutput "[OK] Azure CLI version: $($azVersion.'azure-cli')" -Color "Green"
    }
    catch {
        Write-ColorOutput "[ERROR] Azure CLI is not installed or not in PATH" -Color "Red"
        Write-ColorOutput "Please install Azure CLI from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -Color "Yellow"
        exit 1
    }
    
    # Check if logged into Azure
    try {
        $context = az account show --output json 2>$null | ConvertFrom-Json
        Write-ColorOutput "[OK] Logged into Azure as: $($context.user.name)" -Color "Green"
        Write-ColorOutput "   Subscription: $($context.name) ($($context.id))" -Color "Gray"
        return $context
    }
    catch {
        Write-ColorOutput "[ERROR] Not logged into Azure" -Color "Red"
        Write-ColorOutput "Please run: az login" -Color "Yellow"
        exit 1
    }
}

# Function to create app registration
function New-AppRegistration {
    param($AppName, $WhatIf)
    
    Write-ColorOutput "`n=== Creating Azure App Registration ===" -Color "Cyan"
    
    if ($WhatIf) {
        Write-ColorOutput "[WhatIf] Would create App Registration: $AppName" -Color "Magenta"
        return "00000000-0000-0000-0000-000000000000"
    }
    
    try {
        # Check if app already exists
        $existingApp = az ad app list --display-name $AppName --output json | ConvertFrom-Json
        
        if ($existingApp.Count -gt 0) {
            Write-ColorOutput "[OK] App Registration '$AppName' already exists" -Color "Yellow"
            $appId = $existingApp[0].appId
        }
        else {
            Write-ColorOutput "Creating App Registration: $AppName" -Color "Blue"
            az ad app create --display-name $AppName --output none
            
            $newApp = az ad app list --display-name $AppName --output json | ConvertFrom-Json
            $appId = $newApp[0].appId
            Write-ColorOutput "[OK] Created App Registration: $appId" -Color "Green"
        }
        
        return $appId
    }
    catch {
        Write-ColorOutput "[ERROR] Failed to create App Registration: $($_.Exception.Message)" -Color "Red"
        exit 1
    }
}

# Function to create service principal
function New-ServicePrincipal {
    param($AppId, $WhatIf)
    
    Write-ColorOutput "`n=== Creating Service Principal ===" -Color "Cyan"
    
    if ($WhatIf) {
        Write-ColorOutput "[WhatIf] Would create Service Principal for: $AppId" -Color "Magenta"
        return
    }
    
    try {
        # Check if service principal already exists
        $existingSP = az ad sp show --id $AppId --output json 2>$null
        
        if ($existingSP) {
            Write-ColorOutput "[OK] Service Principal already exists" -Color "Yellow"
        }
        else {
            Write-ColorOutput "Creating Service Principal..." -Color "Blue"
            az ad sp create --id $AppId --output none
            Write-ColorOutput "[OK] Created Service Principal" -Color "Green"
        }
    }
    catch {
        Write-ColorOutput "[ERROR] Failed to create Service Principal: $($_.Exception.Message)" -Color "Red"
        exit 1
    }
}

# Function to assign permissions
function Set-AzurePermissions {
    param($AppId, $SubscriptionId, $WhatIf)
    
    Write-ColorOutput "`n=== Assigning Azure Permissions ===" -Color "Cyan"
    
    $roles = @("Contributor", "User Access Administrator")
    
    foreach ($role in $roles) {
        if ($WhatIf) {
            Write-ColorOutput "[WhatIf] Would assign '$role' role to subscription" -Color "Magenta"
            continue
        }
        
        try {
            # Check if role is already assigned
            $existingAssignment = az role assignment list --assignee $AppId --role $role --scope "/subscriptions/$SubscriptionId" --output json | ConvertFrom-Json
            
            if ($existingAssignment.Count -eq 0) {
                Write-ColorOutput "Assigning '$role' role..." -Color "Blue"
                az role assignment create --assignee $AppId --role $role --scope "/subscriptions/$SubscriptionId" --output none
                Write-ColorOutput "[OK] Assigned '$role' role" -Color "Green"
            }
            else {
                Write-ColorOutput "[OK] '$role' role already assigned" -Color "Yellow"
            }
        }
        catch {
            Write-ColorOutput "⚠️  Failed to assign '$role' role: $($_.Exception.Message)" -Color "Yellow"
        }
    }
}

# Function to create federated credentials
function New-FederatedCredentials {
    param($AppId, $GitHubOrg, $GitHubRepo, $WhatIf)
    
    Write-ColorOutput "`n=== Creating Federated Identity Credentials ===" -Color "Cyan"
    
    $branches = @("main", "staging", "dev")
    
    foreach ($branch in $branches) {
        $credentialName = "podcast-hosting-$branch"
        $subject = "repo:$GitHubOrg/${GitHubRepo}:ref:refs/heads/$branch"
        
        if ($WhatIf) {
            Write-ColorOutput "[WhatIf] Would create federated credential for '$branch' branch" -Color "Magenta"
            Write-ColorOutput "   Subject: $subject" -Color "Gray"
            continue
        }
        
        try {
            # Check if credential already exists
            $existingCreds = az ad app federated-credential list --id $AppId --output json | ConvertFrom-Json
            $existingCred = $existingCreds | Where-Object { $_.name -eq $credentialName }
            
            if ($existingCred) {
                Write-ColorOutput "[OK] Federated credential '$credentialName' already exists" -Color "Yellow"
            }
            else {
                Write-ColorOutput "Creating federated credential for '$branch' branch..." -Color "Blue"
                
                # Create temporary JSON file to avoid PowerShell quoting issues
                $tempJsonFile = "temp-$branch-cred.json"
                $credContent = @{
                    name = $credentialName
                    issuer = "https://token.actions.githubusercontent.com"
                    subject = $subject
                    description = "GitHub Actions OIDC for $branch branch"
                    audiences = @("api://AzureADTokenExchange")
                } | ConvertTo-Json -Depth 3
                
                $credContent | Out-File -FilePath $tempJsonFile -Encoding UTF8
                az ad app federated-credential create --id $AppId --parameters $tempJsonFile --output none
                Remove-Item $tempJsonFile -Force -ErrorAction SilentlyContinue
                Write-ColorOutput "[OK] Created federated credential for '$branch' branch" -Color "Green"
            }
        }
        catch {
            Write-ColorOutput "⚠️  Failed to create federated credential for '$branch': $($_.Exception.Message)" -Color "Yellow"
        }
    }
    
    # Create pull request credential
    $prCredentialName = "podcast-hosting-pr"
    $prSubject = "repo:$GitHubOrg/${GitHubRepo}:pull_request"
    
    if ($WhatIf) {
        Write-ColorOutput "[WhatIf] Would create federated credential for pull requests" -Color "Magenta"
        Write-ColorOutput "   Subject: $prSubject" -Color "Gray"
        return
    }
    
    try {
        $existingCreds = az ad app federated-credential list --id $AppId --output json | ConvertFrom-Json
        $existingPRCred = $existingCreds | Where-Object { $_.name -eq $prCredentialName }
        
        if ($existingPRCred) {
            Write-ColorOutput "[OK] Pull request federated credential already exists" -Color "Yellow"
        }
        else {
            Write-ColorOutput "Creating federated credential for pull requests..." -Color "Blue"
            
            # Create temporary JSON file to avoid PowerShell quoting issues
            $tempPRJsonFile = "temp-pr-cred.json"
            $prCredContent = @{
                name = $prCredentialName
                issuer = "https://token.actions.githubusercontent.com"
                subject = $prSubject
                description = "GitHub Actions OIDC for pull requests"
                audiences = @("api://AzureADTokenExchange")
            } | ConvertTo-Json -Depth 3
            
            $prCredContent | Out-File -FilePath $tempPRJsonFile -Encoding UTF8
            az ad app federated-credential create --id $AppId --parameters $tempPRJsonFile --output none
            Remove-Item $tempPRJsonFile -Force -ErrorAction SilentlyContinue
            Write-ColorOutput "[OK] Created federated credential for pull requests" -Color "Green"
        }
    }
    catch {
        Write-ColorOutput "⚠️  Failed to create pull request federated credential: $($_.Exception.Message)" -Color "Yellow"
    }
    
    # Create environment credentials for GitHub Environments
    Write-ColorOutput "`nCreating environment-based federated credentials..." -Color "Blue"
    $environments = @("dev", "staging", "prod")
    
    foreach ($env in $environments) {
        $envCredentialName = "podcast-hosting-$env-environment"
        $envSubject = "repo:$GitHubOrg/${GitHubRepo}:environment:$env"
        
        if ($WhatIf) {
            Write-ColorOutput "[WhatIf] Would create federated credential for '$env' environment" -Color "Magenta"
            Write-ColorOutput "   Subject: $envSubject" -Color "Gray"
            continue
        }
        
        try {
            $existingCreds = az ad app federated-credential list --id $AppId --output json | ConvertFrom-Json
            $existingEnvCred = $existingCreds | Where-Object { $_.name -eq $envCredentialName }
            
            if ($existingEnvCred) {
                Write-ColorOutput "[OK] Environment credential '$envCredentialName' already exists" -Color "Yellow"
            }
            else {
                Write-ColorOutput "Creating federated credential for '$env' environment..." -Color "Blue"
                
                # Create temporary JSON file to avoid PowerShell quoting issues
                $tempJsonFile = "temp-$env-env-cred.json"
                $envCredContent = @{
                    name = $envCredentialName
                    issuer = "https://token.actions.githubusercontent.com"
                    subject = $envSubject
                    description = "GitHub Actions OIDC for $env environment"
                    audiences = @("api://AzureADTokenExchange")
                } | ConvertTo-Json -Depth 3
                
                $envCredContent | Out-File -FilePath $tempJsonFile -Encoding UTF8
                az ad app federated-credential create --id $AppId --parameters $tempJsonFile --output none
                Remove-Item $tempJsonFile -Force -ErrorAction SilentlyContinue
                Write-ColorOutput "[OK] Created federated credential for '$env' environment" -Color "Green"
            }
        }
        catch {
            Write-ColorOutput "⚠️  Failed to create federated credential for '$env' environment: $($_.Exception.Message)" -Color "Yellow"
        }
    }
}

# Function to display results and next steps
function Show-Results {
    param($AppId, $TenantId, $SubscriptionId, $GitHubOrg, $GitHubRepo, $SkipBrowser)
    
    Write-ColorOutput "`n=== Setup Complete! ===" -Color "Cyan"
    
    # Display the secrets
    Write-ColorOutput "`nGitHub Repository Secrets" -Color "Yellow"
    Write-ColorOutput "Add these secrets to your GitHub repository:" -Color "White"
    Write-ColorOutput ""
    Write-ColorOutput "AZURE_CLIENT_ID" -Color "Green"
    Write-ColorOutput "$AppId" -Color "White"
    Write-ColorOutput ""
    Write-ColorOutput "AZURE_TENANT_ID" -Color "Green"
    Write-ColorOutput "$TenantId" -Color "White"
    Write-ColorOutput ""
    Write-ColorOutput "AZURE_SUBSCRIPTION_ID" -Color "Green"
    Write-ColorOutput "$SubscriptionId" -Color "White"
    
    # Create a temporary file with the secrets for easy copying
    $secretsFile = "azure-oidc-secrets.txt"
    $secretsContent = @"
GitHub Repository Secrets for OIDC Authentication
Generated: $(Get-Date)
Repository: $GitHubOrg/$GitHubRepo

Copy these secrets to your GitHub repository settings:

AZURE_CLIENT_ID
$AppId

AZURE_TENANT_ID
$TenantId

AZURE_SUBSCRIPTION_ID
$SubscriptionId

GitHub Repository Settings URL:
https://github.com/$GitHubOrg/$GitHubRepo/settings/secrets/actions

Next Steps:
1. Add the above secrets to your GitHub repository
2. Create GitHub environments: dev, staging, prod (optional)
3. Test the deployment workflow
4. Remove any old AZURE_CREDENTIALS secret if it exists

For detailed instructions, see: AZURE_OIDC_SETUP_GUIDE.md
"@
    
    $secretsContent | Out-File -FilePath $secretsFile -Encoding UTF8
    Write-ColorOutput "`nSecrets saved to: $secretsFile" -Color "Blue"
    
    # Display next steps
    Write-ColorOutput "`nNext Steps:" -Color "Yellow"
    Write-ColorOutput "1. Add the secrets above to your GitHub repository" -Color "White"
    Write-ColorOutput "2. Create GitHub environments: dev, staging, prod (optional)" -Color "White"
    Write-ColorOutput "3. Test the deployment workflow" -Color "White"
    Write-ColorOutput "4. Remove old AZURE_CREDENTIALS secret if it exists" -Color "White"
    
    # Offer to open GitHub settings
    $githubUrl = "https://github.com/$GitHubOrg/$GitHubRepo/settings/secrets/actions"
    Write-ColorOutput "`nGitHub Repository Settings:" -Color "Yellow"
    Write-ColorOutput "$githubUrl" -Color "Blue"
    
    if (-not $SkipBrowser) {
        $openBrowser = Read-Host "`nWould you like to open GitHub repository settings in your browser? (Y/n)"
        if ($openBrowser -ne 'n' -and $openBrowser -ne 'N') {
            try {
                Start-Process $githubUrl
                Write-ColorOutput "[OK] Opened GitHub repository settings in browser" -Color "Green"
            }
            catch {
                Write-ColorOutput "⚠️  Could not open browser. Please navigate to the URL above manually." -Color "Yellow"
            }
        }
    }
    
    Write-ColorOutput "`nFor detailed troubleshooting and additional information:" -Color "Yellow"
    Write-ColorOutput "   • AZURE_OIDC_SETUP_GUIDE.md" -Color "Blue"
    Write-ColorOutput "   • DEPLOYMENT_GUIDE.md" -Color "Blue"
    Write-ColorOutput "   • scripts/README.md" -Color "Blue"
}

# Main execution
try {
    Write-ColorOutput "[SETUP] Complete Azure OIDC Setup for GitHub Actions" -Color "Cyan"
    Write-ColorOutput "Repository: $GitHubOrg/$GitHubRepo" -Color "Yellow"
    Write-ColorOutput "App Registration: $AppName" -Color "Yellow"
    
    if ($WhatIf) {
        Write-ColorOutput "[PREVIEW] Running in WhatIf mode - no changes will be made" -Color "Magenta"
    }
    
    # Step 1: Check prerequisites
    $azureContext = Test-Prerequisites
    $subscriptionId = $azureContext.id
    $tenantId = $azureContext.tenantId
    
    # Step 2: Create App Registration
    $appId = New-AppRegistration -AppName $AppName -WhatIf $WhatIf
    
    # Step 3: Create Service Principal
    New-ServicePrincipal -AppId $appId -WhatIf $WhatIf
    
    # Step 4: Assign permissions
    Set-AzurePermissions -AppId $appId -SubscriptionId $subscriptionId -WhatIf $WhatIf
    
    # Step 5: Create federated credentials
    New-FederatedCredentials -AppId $appId -GitHubOrg $GitHubOrg -GitHubRepo $GitHubRepo -WhatIf $WhatIf
    
    # Step 6: Show results
    if (-not $WhatIf) {
        Show-Results -AppId $appId -TenantId $tenantId -SubscriptionId $subscriptionId -GitHubOrg $GitHubOrg -GitHubRepo $GitHubRepo -SkipBrowser $SkipBrowser
    }
    else {
        Write-ColorOutput "`n[PREVIEW] WhatIf mode completed successfully" -Color "Magenta"
        Write-ColorOutput "Run the script without -WhatIf to make actual changes" -Color "Yellow"
    }
}
catch {
    Write-ColorOutput "`n[ERROR] Script failed: $($_.Exception.Message)" -Color "Red"
    Write-ColorOutput "Stack trace: $($_.ScriptStackTrace)" -Color "Gray"
    exit 1
}