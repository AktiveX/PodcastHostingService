# Simple Azure OIDC Setup Script for GitHub Actions
# This script creates the Azure resources needed for OIDC authentication

param(
    [Parameter(Mandatory=$false)]
    [string]$GitHubOrg = "AktiveX",
    
    [Parameter(Mandatory=$false)]
    [string]$GitHubRepo = "PodcastHostingService",
    
    [Parameter(Mandatory=$false)]
    [string]$AppName = "podcast-hosting-github-oidc",
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf
)

Write-Host "=== Azure OIDC Setup for GitHub Actions ===" -ForegroundColor Cyan
Write-Host "Repository: $GitHubOrg/$GitHubRepo" -ForegroundColor Yellow
Write-Host "App Registration: $AppName" -ForegroundColor Yellow

if ($WhatIf) {
    Write-Host "Running in WhatIf mode - no changes will be made" -ForegroundColor Magenta
}

# Step 1: Check Azure CLI and login
Write-Host "`n1. Checking Azure CLI..." -ForegroundColor Green
try {
    $context = az account show --output json | ConvertFrom-Json
    Write-Host "   Logged in as: $($context.user.name)" -ForegroundColor Gray
    Write-Host "   Subscription: $($context.name)" -ForegroundColor Gray
    
    $subscriptionId = $context.id
    $tenantId = $context.tenantId
}
catch {
    Write-Host "   ERROR: Not logged into Azure. Please run 'az login'" -ForegroundColor Red
    exit 1
}

# Step 2: Create App Registration
Write-Host "`n2. Creating App Registration..." -ForegroundColor Green
if ($WhatIf) {
    Write-Host "   [WhatIf] Would create App Registration: $AppName" -ForegroundColor Magenta
    $appId = "00000000-0000-0000-0000-000000000000"
}
else {
    try {
        $existingApp = az ad app list --display-name $AppName --output json | ConvertFrom-Json
        if ($existingApp.Count -gt 0) {
            $appId = $existingApp[0].appId
            Write-Host "   App Registration already exists: $appId" -ForegroundColor Yellow
        }
        else {
            az ad app create --display-name $AppName --output none
            $newApp = az ad app list --display-name $AppName --output json | ConvertFrom-Json
            $appId = $newApp[0].appId
            Write-Host "   Created App Registration: $appId" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "   ERROR: Failed to create App Registration" -ForegroundColor Red
        exit 1
    }
}

# Step 3: Create Service Principal
Write-Host "`n3. Creating Service Principal..." -ForegroundColor Green
if ($WhatIf) {
    Write-Host "   [WhatIf] Would create Service Principal" -ForegroundColor Magenta
}
else {
    try {
        $existingSP = az ad sp show --id $appId --output json 2>$null
        if ($existingSP) {
            Write-Host "   Service Principal already exists" -ForegroundColor Yellow
        }
        else {
            az ad sp create --id $appId --output none
            Write-Host "   Created Service Principal" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "   ERROR: Failed to create Service Principal" -ForegroundColor Red
        exit 1
    }
}

# Step 4: Assign permissions
Write-Host "`n4. Assigning Azure permissions..." -ForegroundColor Green
$roles = @("Contributor", "User Access Administrator")
foreach ($role in $roles) {
    if ($WhatIf) {
        Write-Host "   [WhatIf] Would assign '$role' role" -ForegroundColor Magenta
    }
    else {
        try {
            $existing = az role assignment list --assignee $appId --role $role --scope "/subscriptions/$subscriptionId" --output json | ConvertFrom-Json
            if ($existing.Count -eq 0) {
                az role assignment create --assignee $appId --role $role --scope "/subscriptions/$subscriptionId" --output none
                Write-Host "   Assigned '$role' role" -ForegroundColor Gray
            }
            else {
                Write-Host "   '$role' role already assigned" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "   WARNING: Failed to assign '$role' role" -ForegroundColor Yellow
        }
    }
}

# Step 5: Create federated credentials
Write-Host "`n5. Creating federated credentials..." -ForegroundColor Green
$branches = @("main", "staging", "dev")
foreach ($branch in $branches) {
    $credName = "podcast-hosting-$branch"
    $subject = "repo:$GitHubOrg/${GitHubRepo}:ref:refs/heads/$branch"
    
    if ($WhatIf) {
        Write-Host "   [WhatIf] Would create credential for '$branch' branch" -ForegroundColor Magenta
    }
    else {
        try {
            $existingCreds = az ad app federated-credential list --id $appId --output json | ConvertFrom-Json
            $existingCred = $existingCreds | Where-Object { $_.name -eq $credName }
            
            if ($existingCred) {
                Write-Host "   Credential for '$branch' already exists" -ForegroundColor Yellow
            }
            else {
                $credJson = @{
                    name = $credName
                    issuer = "https://token.actions.githubusercontent.com"
                    subject = $subject
                    description = "GitHub Actions OIDC for $branch branch"
                    audiences = @("api://AzureADTokenExchange")
                } | ConvertTo-Json -Depth 3
                
                az ad app federated-credential create --id $appId --parameters $credJson --output none
                Write-Host "   Created credential for '$branch' branch" -ForegroundColor Gray
            }
        }
        catch {
            Write-Host "   WARNING: Failed to create credential for '$branch'" -ForegroundColor Yellow
        }
    }
}

# Step 6: Display results
Write-Host "`n=== Setup Complete ===" -ForegroundColor Cyan

if (-not $WhatIf) {
    Write-Host "`nGitHub Repository Secrets:" -ForegroundColor Yellow
    Write-Host "Add these to your GitHub repository at:" -ForegroundColor White
    Write-Host "https://github.com/$GitHubOrg/$GitHubRepo/settings/secrets/actions" -ForegroundColor Blue
    Write-Host ""
    Write-Host "AZURE_CLIENT_ID" -ForegroundColor Green
    Write-Host "$appId" -ForegroundColor White
    Write-Host ""
    Write-Host "AZURE_TENANT_ID" -ForegroundColor Green
    Write-Host "$tenantId" -ForegroundColor White
    Write-Host ""
    Write-Host "AZURE_SUBSCRIPTION_ID" -ForegroundColor Green
    Write-Host "$subscriptionId" -ForegroundColor White
    
    # Save to file
    $secretsContent = @"
GitHub Repository Secrets for OIDC Authentication
Generated: $(Get-Date)
Repository: $GitHubOrg/$GitHubRepo

AZURE_CLIENT_ID=$appId
AZURE_TENANT_ID=$tenantId
AZURE_SUBSCRIPTION_ID=$subscriptionId

GitHub Settings URL:
https://github.com/$GitHubOrg/$GitHubRepo/settings/secrets/actions
"@
    
    $secretsContent | Out-File -FilePath "azure-secrets.txt" -Encoding UTF8
    Write-Host "`nSecrets saved to: azure-secrets.txt" -ForegroundColor Blue
    
    Write-Host "`nNext Steps:" -ForegroundColor Yellow
    Write-Host "1. Add the above secrets to your GitHub repository" -ForegroundColor White
    Write-Host "2. Test the GitHub Actions workflow" -ForegroundColor White
    Write-Host "3. Remove old AZURE_CREDENTIALS secret if it exists" -ForegroundColor White
}
else {
    Write-Host "`nRun without -WhatIf to make actual changes" -ForegroundColor Magenta
}