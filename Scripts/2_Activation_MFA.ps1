# scripts/02-enable-mfa.ps1

# Définir les officiers supérieurs (exemples)
$officiers = @(
    "captain@uss-enterprise.com",
    "first-officer@uss-enterprise.com",
    "chief-engineer@uss-enterprise.com"
)

# Activer le MFA pour chaque officier
foreach ($officier in $officiers) {
    $user = Get-AzureADUser -ObjectId $officier
    
    # Créer une politique de MFA
    Set-MsolUser -UserPrincipalName $officier -StrongAuthenticationRequirements @(
        @{
            RelyingParty = "*"
            State = "Enabled"
        }
    )
    
    Write-Host "MFA activé pour $officier" -ForegroundColor Green
}