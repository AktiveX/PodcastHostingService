param(
    [Parameter(Mandatory = $true)]
    [string]$AppName,
    
    [Parameter(Mandatory = $true)]
    [string]$Environment,
    
    [Parameter(Mandatory = $false)]
    [string]$StaticWebAppUrl,
    
    [Parameter(Mandatory = $false)]
    [string]$TenantId
)

# Install required modules if not present
$requiredModules = @('Microsoft.Graph.Applications', 'Microsoft.Graph.Authentication')
foreach ($module in $requiredModules) {
    if (!(Get-Module -ListAvailable -Name $module)) {
        Write-Output "Installing module: $module"
        Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser
    }
}

# Import required modules
Import-Module Microsoft.Graph.Applications
Import-Module Microsoft.Graph.Authentication

try {
    # Connect to Microsoft Graph using managed identity or current context
    Write-Output "Connecting to Microsoft Graph..."
    
    if ($env:MSI_ENDPOINT) {
        # Running in Azure - use managed identity
        Connect-MgGraph -Identity
    } else {
        # Running locally - use current user context
        Connect-MgGraph -Scopes "Application.ReadWrite.All"
    }
    
    # Get current tenant ID if not provided
    if ([string]::IsNullOrEmpty($TenantId)) {
        $context = Get-MgContext
        $TenantId = $context.TenantId
        Write-Output "Using tenant ID: $TenantId"
    }
    
    # Check if app registration already exists
    $displayName = "$AppName-$Environment"
    Write-Output "Checking for existing app registration: $displayName"
    
    $existingApp = Get-MgApplication -Filter "displayName eq '$displayName'" -ErrorAction SilentlyContinue
    
    if ($existingApp) {
        Write-Output "App registration already exists with ID: $($existingApp.AppId)"
        $appId = $existingApp.AppId
        $objectId = $existingApp.Id
    } else {
        Write-Output "Creating new app registration: $displayName"
        
        # Define redirect URIs
        $redirectUris = @()
        if (![string]::IsNullOrEmpty($StaticWebAppUrl)) {
            $redirectUris += $StaticWebAppUrl
            $redirectUris += "$StaticWebAppUrl/.auth/login/aad/callback"
            # Add localhost for development
            $redirectUris += "http://localhost:3000"
            $redirectUris += "http://localhost:5173"  # Vite default port
        }
        
        # Create the app registration
        $appParams = @{
            DisplayName = $displayName
            SignInAudience = "AzureADMyOrg"
            Web = @{
                RedirectUris = $redirectUris
                ImplicitGrantSettings = @{
                    EnableIdTokenIssuance = $true
                    EnableAccessTokenIssuance = $false
                }
            }
            RequiredResourceAccess = @(
                @{
                    ResourceAppId = "00000003-0000-0000-c000-000000000000"  # Microsoft Graph
                    ResourceAccess = @(
                        @{
                            Id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"  # User.Read
                            Type = "Scope"
                        }
                    )
                }
            )
            Tags = @("Environment:$Environment", "Project:PodcastHostingService")
        }
        
        $newApp = New-MgApplication @appParams
        $appId = $newApp.AppId
        $objectId = $newApp.Id
        
        Write-Output "Created app registration with ID: $appId"
        
        # Wait a moment for replication
        Start-Sleep -Seconds 5
    }
    
    # Update redirect URIs if StaticWebAppUrl is provided and app exists
    if (![string]::IsNullOrEmpty($StaticWebAppUrl) -and $existingApp) {
        Write-Output "Updating redirect URIs for existing app..."
        
        $redirectUris = @(
            $StaticWebAppUrl,
            "$StaticWebAppUrl/.auth/login/aad/callback",
            "http://localhost:3000",
            "http://localhost:5173"
        )
        
        $updateParams = @{
            Web = @{
                RedirectUris = $redirectUris
                ImplicitGrantSettings = @{
                    EnableIdTokenIssuance = $true
                    EnableAccessTokenIssuance = $false
                }
            }
        }
        
        Update-MgApplication -ApplicationId $objectId @updateParams
        Write-Output "Updated redirect URIs"
    }
    
    # Create output object
    $result = @{
        appId = $appId
        tenantId = $TenantId
        displayName = $displayName
        objectId = $objectId
    }
    
    # Output as JSON for consumption by Bicep
    $jsonResult = $result | ConvertTo-Json -Compress
    Write-Output "RESULT:$jsonResult"
    
} catch {
    Write-Error "Error managing app registration: $($_.Exception.Message)"
    throw
} finally {
    # Disconnect from Microsoft Graph
    Disconnect-MgGraph -ErrorAction SilentlyContinue
}
