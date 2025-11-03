# scripts/08-configure-sso.ps1

# Créer une application d'entreprise
$app = New-MgApplication -DisplayName "Captain's Log" `
    -SignInAudience "AzureADMyOrg" `
    -Web @{
        RedirectUris = @("https://captains-log.uss-enterprise.com/auth/callback")
    }

# Créer le service principal
$sp = New-MgServicePrincipal -AppId $app.AppId

Write-Host "Application créée : Captain's Log" -ForegroundColor Green
Write-Host "App ID : $($app.AppId)" -ForegroundColor Cyan