param(
    [Parameter(Mandatory = $true)]
    [string]$Environment,
    
    [Parameter(Mandatory = $false)]
    [string]$AppName = "podcast"
)

Write-Host "Testing App Registration for Environment: $Environment" -ForegroundColor Green

try {
    # Import required modules
    Import-Module Microsoft.Graph.Applications -Force
    Import-Module Microsoft.Graph.Authentication -Force

    # Connect to Microsoft Graph
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
    Connect-MgGraph -Scopes "Application.Read.All" -NoWelcome

    # Check if app registration exists
    $displayName = "$AppName-$Environment"
    Write-Host "Looking for app registration: $displayName" -ForegroundColor Yellow
    
    $app = Get-MgApplication -Filter "displayName eq '$displayName'" -ErrorAction SilentlyContinue

    if ($app) {
        Write-Host "✅ App registration found!" -ForegroundColor Green
        Write-Host "   Display Name: $($app.DisplayName)" -ForegroundColor White
        Write-Host "   App ID: $($app.AppId)" -ForegroundColor White
        Write-Host "   Object ID: $($app.Id)" -ForegroundColor White
        Write-Host "   Sign-in Audience: $($app.SignInAudience)" -ForegroundColor White
        
        if ($app.Web.RedirectUris.Count -gt 0) {
            Write-Host "   Redirect URIs:" -ForegroundColor White
            foreach ($uri in $app.Web.RedirectUris) {
                Write-Host "     - $uri" -ForegroundColor Gray
            }
        } else {
            Write-Host "   ⚠️  No redirect URIs configured" -ForegroundColor Yellow
        }

        if ($app.RequiredResourceAccess.Count -gt 0) {
            Write-Host "   API Permissions:" -ForegroundColor White
            foreach ($resource in $app.RequiredResourceAccess) {
                Write-Host "     - Resource: $($resource.ResourceAppId)" -ForegroundColor Gray
                foreach ($access in $resource.ResourceAccess) {
                    Write-Host "       Permission: $($access.Id) (Type: $($access.Type))" -ForegroundColor Gray
                }
            }
        }

        # Check tags
        if ($app.Tags.Count -gt 0) {
            Write-Host "   Tags:" -ForegroundColor White
            foreach ($tag in $app.Tags) {
                Write-Host "     - $tag" -ForegroundColor Gray
            }
        }

        Write-Host "✅ App registration validation completed successfully!" -ForegroundColor Green
        return $true
    } else {
        Write-Host "❌ App registration not found: $displayName" -ForegroundColor Red
        Write-Host "   This might be expected if you haven't deployed the infrastructure yet." -ForegroundColor Yellow
        return $false
    }

} catch {
    Write-Host "❌ Error during validation: $($_.Exception.Message)" -ForegroundColor Red
    return $false
} finally {
    # Disconnect from Microsoft Graph
    Disconnect-MgGraph -ErrorAction SilentlyContinue
}
