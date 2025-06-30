# Quick setup script for PodcastHostingService OIDC Authentication
# This script runs the complete OIDC setup with your repository details

# Repository configuration - UPDATE THESE VALUES
$GitHubOrg = "AktiveX"  # Your GitHub username/organization
$GitHubRepo = "PodcastHostingService"  # Your repository name

# Check if the complete setup script exists
$setupScriptPath = Join-Path $PSScriptRoot "Complete-AzureOIDCSetup.ps1"

if (-not (Test-Path $setupScriptPath)) {
    Write-Host "❌ Complete-AzureOIDCSetup.ps1 not found in scripts directory" -ForegroundColor Red
    Write-Host "Please ensure you're running this script from the correct location" -ForegroundColor Yellow
    exit 1
}

Write-Host "🚀 Starting Azure OIDC Setup for PodcastHostingService" -ForegroundColor Cyan
Write-Host "Repository: $GitHubOrg/$GitHubRepo" -ForegroundColor Yellow
Write-Host ""

# Ask user what they want to do
Write-Host "What would you like to do?" -ForegroundColor Yellow
Write-Host "1. Preview what would be done (WhatIf mode)" -ForegroundColor White
Write-Host "2. Run the complete setup" -ForegroundColor White
Write-Host "3. Exit" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Enter your choice (1-3)"

switch ($choice) {
    "1" {
        Write-Host "`n🔍 Running in preview mode..." -ForegroundColor Magenta
        & $setupScriptPath -GitHubOrg $GitHubOrg -GitHubRepo $GitHubRepo -WhatIf
    }
    "2" {
        Write-Host "`n⚡ Running complete setup..." -ForegroundColor Green
        & $setupScriptPath -GitHubOrg $GitHubOrg -GitHubRepo $GitHubRepo
    }
    "3" {
        Write-Host "Exiting..." -ForegroundColor Gray
        exit 0
    }
    default {
        Write-Host "❌ Invalid choice. Please run the script again and select 1, 2, or 3." -ForegroundColor Red
        exit 1
    }
}