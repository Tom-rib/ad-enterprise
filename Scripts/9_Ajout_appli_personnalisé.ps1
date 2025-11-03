# scripts/09-repair-management-app.ps1

# Créer l'application
$repairApp = New-MgApplication -DisplayName "Repair Management" `
    -SignInAudience "AzureADMyOrg"

# Créer le service principal
$repairSP = New-MgServicePrincipal -AppId $repairApp.AppId

# Créer un rôle personnalisé pour les ingénieurs
$engineerRole = @{
    allowedMemberTypes = @("User")
    description = "Ingénieurs autorisés à modifier les données de réparation"
    displayName = "Engineer"
    id = (New-Guid).ToString()
    isEnabled = $true
    value = "Engineer"
}

Update-MgApplication -ApplicationId $repairApp.Id -AppRoles @($engineerRole)

Write-Host "Application Repair Management créée avec le rôle Engineer" -ForegroundColor Green