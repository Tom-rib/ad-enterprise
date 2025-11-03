# scripts/04-test-policies.ps1

# Simuler une connexion depuis différents emplacements
$testUsers = @(
    "ensign.test@uss-enterprise.com"
)

# Utiliser What-If Analysis
foreach ($user in $testUsers) {
    Write-Host "Test de connexion pour $user depuis un emplacement non autorisé" -ForegroundColor Yellow
    
    # Simulation (à adapter selon votre configuration)
    Test-MgIdentityConditionalAccessPolicy -UserId $user
}