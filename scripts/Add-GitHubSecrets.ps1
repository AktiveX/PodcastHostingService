# Add GitHub Repository Secrets for OIDC Authentication
# This script uses GitHub CLI to automatically add the required secrets

param(
    [Parameter(Mandatory=$false)]
    [string]$GitHubOrg = "AktiveX",
    
    [Parameter(Mandatory=$false)]
    [string]$GitHubRepo = "PodcastHostingService",
    
    [Parameter(Mandatory=$false)]
    [string]$SecretsFile = "azure-secrets.txt"
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

# Function to check GitHub CLI
function Test-GitHubCLI {
    Write-ColorOutput "`n=== Checking GitHub CLI ===" -Color "Cyan"
    
    try {
        $ghVersion = gh --version 2>$null
        if ($ghVersion) {
            Write-ColorOutput "[OK] GitHub CLI is installed" -Color "Green"
            Write-ColorOutput "   Version: $($ghVersion.Split("`n")[0])" -Color "Gray"
        }
        else {
            throw "GitHub CLI not found"
        }
    }
    catch {
        Write-ColorOutput "[ERROR] GitHub CLI is not installed or not in PATH" -Color "Red"
        Write-ColorOutput "Please install GitHub CLI from: https://cli.github.com/" -Color "Yellow"
        Write-ColorOutput "After installation, run: gh auth login" -Color "Yellow"
        exit 1
    }
    
    # Check if authenticated
    try {
        $authStatus = gh auth status 2>&1
        if ($authStatus -match "Logged in") {
            Write-ColorOutput "[OK] Logged into GitHub CLI" -Color "Green"
            $username = ($authStatus | Select-String "account (.+?) \(" | ForEach-Object { $_.Matches.Groups[1].Value })
            if ($username) {
                Write-ColorOutput "   Authenticated as: $username" -Color "Gray"
            }
        }
        else {
            throw "Not authenticated"
        }
    }
    catch {
        Write-ColorOutput "[ERROR] Not authenticated with GitHub CLI" -Color "Red"
        Write-ColorOutput "Please run: gh auth login" -Color "Yellow"
        exit 1
    }
}

# Function to parse secrets from file
function Get-SecretsFromFile {
    param($FilePath)
    
    Write-ColorOutput "`n=== Reading Secrets File ===" -Color "Cyan"
    
    if (-not (Test-Path $FilePath)) {
        Write-ColorOutput "[ERROR] Secrets file not found: $FilePath" -Color "Red"
        Write-ColorOutput "Please run the Azure OIDC setup script first." -Color "Yellow"
        exit 1
    }
    
    $secrets = @{}
    $content = Get-Content $FilePath
    
    foreach ($line in $content) {
        if ($line -match "^(AZURE_\w+)=(.+)$") {
            $secretName = $matches[1]
            $secretValue = $matches[2]
            $secrets[$secretName] = $secretValue
            Write-ColorOutput "   Found secret: $secretName" -Color "Gray"
        }
    }
    
    if ($secrets.Count -eq 0) {
        Write-ColorOutput "[ERROR] No secrets found in file: $FilePath" -Color "Red"
        exit 1
    }
    
    Write-ColorOutput "[OK] Found $($secrets.Count) secrets to add" -Color "Green"
    return $secrets
}

# Function to add secrets to GitHub repository
function Add-GitHubSecrets {
    param($Secrets, $Repository)
    
    Write-ColorOutput "`n=== Adding Secrets to GitHub Repository ===" -Color "Cyan"
    Write-ColorOutput "Repository: $Repository" -Color "Yellow"
    
    foreach ($secretName in $secrets.Keys) {
        $secretValue = $secrets[$secretName]
        
        try {
            Write-ColorOutput "Adding secret: $secretName" -Color "Blue"
            
            # Use GitHub CLI to add the secret
            $secretValue | gh secret set $secretName --repo $Repository
            
            Write-ColorOutput "   [OK] Successfully added $secretName" -Color "Green"
        }
        catch {
            Write-ColorOutput "   [ERROR] Failed to add ${secretName}: $($_.Exception.Message)" -Color "Red"
        }
    }
}

# Function to verify secrets were added
function Test-GitHubSecrets {
    param($Repository)
    
    Write-ColorOutput "`n=== Verifying GitHub Secrets ===" -Color "Cyan"
    
    try {
        $existingSecrets = gh secret list --repo $Repository --json name | ConvertFrom-Json
        
        $requiredSecrets = @("AZURE_CLIENT_ID", "AZURE_TENANT_ID", "AZURE_SUBSCRIPTION_ID")
        $foundSecrets = @()
        
        foreach ($required in $requiredSecrets) {
            $found = $existingSecrets | Where-Object { $_.name -eq $required }
            if ($found) {
                Write-ColorOutput "   [OK] $required is configured" -Color "Green"
                $foundSecrets += $required
            }
            else {
                Write-ColorOutput "   [ERROR] $required is missing" -Color "Red"
            }
        }
        
        if ($foundSecrets.Count -eq $requiredSecrets.Count) {
            Write-ColorOutput "`n[SUCCESS] All required secrets are configured!" -Color "Green"
            return $true
        }
        else {
            Write-ColorOutput "`n[WARNING] Some secrets are missing. Please check the configuration." -Color "Yellow"
            return $false
        }
    }
    catch {
        Write-ColorOutput "[ERROR] Failed to verify secrets: $($_.Exception.Message)" -Color "Red"
        return $false
    }
}

# Function to display next steps
function Show-NextSteps {
    param($Repository)
    
    Write-ColorOutput "`n=== Next Steps ===" -Color "Cyan"
    Write-ColorOutput "1. GitHub secrets have been configured for OIDC authentication" -Color "White"
    Write-ColorOutput "2. You can now trigger the infrastructure deployment" -Color "White"
    Write-ColorOutput "3. Push changes to the dev branch to trigger GitHub Actions" -Color "White"
    Write-ColorOutput ""
    Write-ColorOutput "GitHub Actions will now be able to:" -Color "Yellow"
    Write-ColorOutput "   - Authenticate to Azure using OIDC" -Color "White"
    Write-ColorOutput "   - Deploy infrastructure to the DEV environment" -Color "White"
    Write-ColorOutput "   - Create all required Azure resources" -Color "White"
    Write-ColorOutput ""
    Write-ColorOutput "Repository URL: https://github.com/$Repository" -Color "Blue"
    Write-ColorOutput "Actions URL: https://github.com/$Repository/actions" -Color "Blue"
}

# Main execution
try {
    Write-ColorOutput "[SETUP] GitHub Repository Secrets Setup for OIDC" -Color "Cyan"
    Write-ColorOutput "Repository: $GitHubOrg/$GitHubRepo" -Color "Yellow"
    Write-ColorOutput "Secrets File: $SecretsFile" -Color "Yellow"
    
    # Step 1: Check GitHub CLI
    Test-GitHubCLI
    
    # Step 2: Read secrets from file
    $secrets = Get-SecretsFromFile -FilePath $SecretsFile
    
    # Step 3: Add secrets to GitHub repository
    $repository = "$GitHubOrg/$GitHubRepo"
    Add-GitHubSecrets -Secrets $secrets -Repository $repository
    
    # Step 4: Verify secrets were added
    $success = Test-GitHubSecrets -Repository $repository
    
    # Step 5: Show next steps
    if ($success) {
        Show-NextSteps -Repository $repository
    }
    
    Write-ColorOutput "`n[SUCCESS] GitHub secrets setup completed!" -Color "Green"
}
catch {
    Write-ColorOutput "`n[ERROR] Script failed: $($_.Exception.Message)" -Color "Red"
    Write-ColorOutput "Stack trace: $($_.ScriptStackTrace)" -Color "Gray"
    exit 1
}