# scripts/08-configure-sso.ps1

# Creer une application d'entreprise
$app = New-MgApplication -DisplayName "Captain's Log" `
    -SignInAudience "AzureADMyOrg" `
    -Web @{
        RedirectUris = @("https://captains-log.uss-enterprise.com/auth/callback")
    }

# Creer le service principal
$sp = New-MgServicePrincipal -AppId $app.AppId

Write-Host "Application creee : Captain's Log" -ForegroundColor Green
Write-Host "App ID : $($app.AppId)" -ForegroundColor Cyan