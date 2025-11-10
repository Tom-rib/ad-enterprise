# scripts/02-enable-mfa.ps1

# Definir les officiers superieurs (exemples)
$officiers = @(
    "captain@uss-enterprise.com",
    "first-officer@uss-enterprise.com",
    "chief-engineer@uss-enterprise.com"
)

# Activer le MFA pour chaque officier
foreach ($officier in $officiers) {
    $user = Get-AzureADUser -ObjectId $officier
    
    # Creer une politique de MFA
    Set-MsolUser -UserPrincipalName $officier -StrongAuthenticationRequirements @(
        @{
            RelyingParty = "*"
            State = "Enabled"
        }
    )
    
    Write-Host "MFA active pour $officier" -ForegroundColor Green
}