# scripts/05-create-users.ps1

# Fonction pour creer un utilisateur
function New-EnterpriseCrewMember {
    param(
        [string]$FirstName,
        [string]$LastName,
        [string]$Department,
        [string]$Rank
    )
    
    $displayName = "$Rank $FirstName $LastName"
    $userPrincipalName = "$($FirstName.ToLower()).$($LastName.ToLower())@uss-enterprise.com"
    $mailNickname = "$($FirstName.ToLower())$($LastName.ToLower())"
    
    # Generer un mot de passe temporaire
    $passwordProfile = @{
        Password = "Starfleet2024!"
        ForceChangePasswordNextSignIn = $true
    }
    
    # Creer l'utilisateur
    $newUser = New-MgUser -DisplayName $displayName `
        -UserPrincipalName $userPrincipalName `
        -MailNickname $mailNickname `
        -AccountEnabled `
        -PasswordProfile $passwordProfile `
        -Department $department `
        -JobTitle $rank
    
    Write-Host "Utilisateur cree : $displayName" -ForegroundColor Green
    return $newUser
}

# Exemples d'utilisation
New-EnterpriseCrewMember -FirstName "James" -LastName "Kirk" -Department "Command" -Rank "Captain"
New-EnterpriseCrewMember -FirstName "Spock" -LastName "VulcanName" -Department "Science" -Rank "Commander"
New-EnterpriseCrewMember -FirstName "Leonard" -LastName "McCoy" -Department "Medical" -Rank "Doctor"
New-EnterpriseCrewMember -FirstName "Montgomery" -LastName "Scott" -Department "Engineering" -Rank "Commander"