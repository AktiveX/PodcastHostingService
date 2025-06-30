# Azure OIDC Setup Script for GitHub Actions
# This script automates the setup of OIDC authentication between GitHub Actions and Azure

param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubOrg,
    
    [Parameter(Mandatory=$true)]
    [string]$GitHubRepo,
    
    [Parameter(Mandatory=$false)]
    [string]$AppName = "podcast-hosting-github-oidc",
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf
)

Write-Host "=== Azure OIDC Setup for GitHub Actions ===" -ForegroundColor Cyan
Write-Host "GitHub Repository: $GitHubOrg/$GitHubRepo" -ForegroundColor Yellow
Write-Host "App Registration Name: $AppName" -ForegroundColor Yellow

if ($WhatIf) {
    Write-Host "Running in WhatIf mode - no changes will be made" -ForegroundColor Magenta
}

# Step 1: Get Azure context
Write-Host "`n1. Getting Azure context..." -ForegroundColor Green
try {
    $context = az account show | ConvertFrom-Json
    Write-Host "   Subscription: $($context.name) ($($context.id))" -ForegroundColor Gray
    Write-Host "   Tenant: $($context.tenantId)" -ForegroundColor Gray
    
    $subscriptionId = $context.id
    $tenantId = $context.tenantId
} catch {
    Write-Error "Failed to get Azure context. Please run 'az login' first."
    exit 1
}

# Step 2: Create App Registration
Write-Host "`n2. Creating App Registration..." -ForegroundColor Green
if (!$WhatIf) {
    try {
        $appExists = az ad app list --display-name $AppName | ConvertFrom-Json
        if ($appExists.Count -gt 0) {
            Write-Host "   App Registration '$AppName' already exists" -ForegroundColor Yellow
            $appId = $appExists[0].appId
        } else {
            az ad app create --display-name $AppName | Out-Null
            $app = az ad app list --display-name $AppName | ConvertFrom-Json
            $appId = $app[0].appId
            Write-Host "   Created App Registration: $appId" -ForegroundColor Gray
        }
    } catch {
        Write-Error "Failed to create App Registration: $_"
        exit 1
    }
} else {
    Write-Host "   [WhatIf] Would create App Registration '$AppName'" -ForegroundColor Magenta
    $appId = "00000000-0000-0000-0000-000000000000"
}

# Step 3: Create Service Principal
Write-Host "`n3. Creating Service Principal..." -ForegroundColor Green
if (!$WhatIf) {
    try {
        $spExists = az ad sp show --id $appId 2>$null
        if ($spExists) {
            Write-Host "   Service Principal already exists" -ForegroundColor Yellow
        } else {
            az ad sp create --id $appId | Out-Null
            Write-Host "   Created Service Principal" -ForegroundColor Gray
        }
    } catch {
        Write-Error "Failed to create Service Principal: $_"
        exit 1
    }
} else {
    Write-Host "   [WhatIf] Would create Service Principal for $appId" -ForegroundColor Magenta
}

# Step 4: Assign permissions
Write-Host "`n4. Assigning Azure permissions..." -ForegroundColor Green
$roles = @("Contributor", "User Access Administrator")
foreach ($role in $roles) {
    if (!$WhatIf) {
        try {
            $existing = az role assignment list --assignee $appId --role $role --scope "/subscriptions/$subscriptionId" | ConvertFrom-Json
            if ($existing.Count -eq 0) {
                az role assignment create --assignee $appId --role $role --scope "/subscriptions/$subscriptionId" | Out-Null
                Write-Host "   Assigned '$role' role" -ForegroundColor Gray
            } else {
                Write-Host "   '$role' role already assigned" -ForegroundColor Yellow
            }
        } catch {
            Write-Warning "Failed to assign '$role' role: $_"
        }
    } else {
        Write-Host "   [WhatIf] Would assign '$role' role to subscription scope" -ForegroundColor Magenta
    }
}

# Step 5: Create federated credentials
Write-Host "`n5. Creating federated identity credentials..." -ForegroundColor Green
$branches = @("main", "staging", "dev")
foreach ($branch in $branches) {
    $credentialName = "podcast-hosting-$branch"
    $subject = "repo:$GitHubOrg/${GitHubRepo}:ref:refs/heads/$branch"
    
    if (!$WhatIf) {
        try {
            $existing = az ad app federated-credential list --id $appId | ConvertFrom-Json | Where-Object { $_.name -eq $credentialName }
            if ($existing) {
                Write-Host "   Federated credential '$credentialName' already exists" -ForegroundColor Yellow
            } else {
                $credential = @{
                    name = $credentialName
                    issuer = "https://token.actions.githubusercontent.com"
                    subject = $subject
                    description = "GitHub Actions OIDC for $branch branch"
                    audiences = @("api://AzureADTokenExchange")
                } | ConvertTo-Json -Depth 3
                
                az ad app federated-credential create --id $appId --parameters $credential | Out-Null
                Write-Host "   Created federated credential for '$branch' branch" -ForegroundColor Gray
            }
        } catch {
            Write-Warning "Failed to create federated credential for '$branch': $_"
        }
    } else {
        Write-Host "   [WhatIf] Would create federated credential for '$branch' branch" -ForegroundColor Magenta
        Write-Host "     Subject: $subject" -ForegroundColor DarkGray
    }
}

# Step 6: Display results
Write-Host "`n=== Setup Complete ===" -ForegroundColor Cyan
Write-Host "`nAdd these secrets to your GitHub repository:" -ForegroundColor Yellow
Write-Host "AZURE_CLIENT_ID = $appId" -ForegroundColor White
Write-Host "AZURE_TENANT_ID = $tenantId" -ForegroundColor White  
Write-Host "AZURE_SUBSCRIPTION_ID = $subscriptionId" -ForegroundColor White

Write-Host "`nGitHub Repository Settings:" -ForegroundColor Yellow
Write-Host "Go to: https://github.com/$GitHubOrg/$GitHubRepo/settings/secrets/actions" -ForegroundColor Blue

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Add the above secrets to your GitHub repository" -ForegroundColor Gray
Write-Host "2. Create GitHub environments: dev, staging, prod" -ForegroundColor Gray
Write-Host "3. Test the deployment workflow" -ForegroundColor Gray
Write-Host "4. Remove any old AZURE_CREDENTIALS secret" -ForegroundColor Gray

if ($WhatIf) {
    Write-Host "`nRun without -WhatIf to make actual changes" -ForegroundColor Magenta
}