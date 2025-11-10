# scripts/09-repair-management-app.ps1

# Creer l'application
$repairApp = New-MgApplication -DisplayName "Repair Management" `
    -SignInAudience "AzureADMyOrg"

# Creer le service principal
$repairSP = New-MgServicePrincipal -AppId $repairApp.AppId

# Creer un rôle personnalise pour les ingenieurs
$engineerRole = @{
    allowedMemberTypes = @("User")
    description = "Ingenieurs autorises a modifier les donnees de reparation"
    displayName = "Engineer"
    id = (New-Guid).ToString()
    isEnabled = $true
    value = "Engineer"
}

Update-MgApplication -ApplicationId $repairApp.Id -AppRoles @($engineerRole)

Write-Host "Application Repair Management creee avec le rôle Engineer" -ForegroundColor Green