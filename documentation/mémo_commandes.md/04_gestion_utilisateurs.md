# Guide 04 - Gestion des Utilisateurs (Users)

## 📚 À quoi ça sert ?

Les utilisateurs sont les **identités individuelles** dans votre tenant Entra ID. Chaque personne qui accède à vos ressources Azure doit avoir un compte utilisateur.

### Pourquoi gérer des utilisateurs ?
- **Authentification** : Permettre aux personnes de se connecter
- **Autorisation** : Attribuer des permissions et accès
- **Audit** : Tracer qui fait quoi dans le système
- **Collaboration** : Partager des ressources entre membres d'équipe

---

## 🔍 Consulter les utilisateurs existants

### Lister tous les utilisateurs

```powershell
# Lister tous les utilisateurs
Get-MgUser

# Avec pagination (affiche 10 utilisateurs à la fois)
Get-MgUser -Top 10

# Afficher seulement certaines propriétés
Get-MgUser | Select-Object DisplayName, UserPrincipalName, Mail
```

### Rechercher un utilisateur spécifique

```powershell
# Par nom d'utilisateur principal (UPN)
Get-MgUser -UserId "james.kirk@uss-enterprise.com"

# Par filtre sur le nom d'affichage
Get-MgUser -Filter "startswith(displayName, 'James')"

# Par département
Get-MgUser -Filter "department eq 'Engineering'"

# Recherche combinée
Get-MgUser -Filter "startswith(displayName, 'Captain') and department eq 'Command'"
```

### Obtenir des détails complets sur un utilisateur

```powershell
# Toutes les propriétés
Get-MgUser -UserId "james.kirk@uss-enterprise.com" | Format-List

# Propriétés spécifiques
Get-MgUser -UserId "james.kirk@uss-enterprise.com" | 
    Select-Object DisplayName, UserPrincipalName, Department, JobTitle, AccountEnabled
```

---

## ➕ Créer des utilisateurs

### Créer un utilisateur simple

```powershell
# Définir le mot de passe
$passwordProfile = @{
    Password = "Starfleet2024!"
    ForceChangePasswordNextSignIn = $true
}

# Créer l'utilisateur
$newUser = New-MgUser -DisplayName "James Kirk" `
    -UserPrincipalName "james.kirk@uss-enterprise.onmicrosoft.com" `
    -MailNickname "james.kirk" `
    -AccountEnabled `
    -PasswordProfile $passwordProfile `
    -UsageLocation "FR"

Write-Host "✓ Utilisateur créé : $($newUser.DisplayName)" -ForegroundColor Green
Write-Host "  UPN : $($newUser.UserPrincipalName)" -ForegroundColor Cyan
Write-Host "  ID : $($newUser.Id)" -ForegroundColor Cyan
```

### Créer un utilisateur avec tous les détails

```powershell
# Mot de passe
$passwordProfile = @{
    Password = "VotreMotDePasse123!"
    ForceChangePasswordNextSignIn = $true
}

# Paramètres complets
$userParams = @{
    DisplayName = "Captain James Kirk"
    GivenName = "James"
    Surname = "Kirk"
    UserPrincipalName = "james.kirk@uss-enterprise.onmicrosoft.com"
    MailNickname = "james.kirk"
    AccountEnabled = $true
    PasswordProfile = $passwordProfile
    UsageLocation = "FR"  # Code pays ISO (obligatoire pour licences)
    
    # Informations professionnelles
    JobTitle = "Captain"
    Department = "Command"
    CompanyName = "USS Enterprise"
    OfficeLocation = "Bridge"
    EmployeeId = "NCC-1701-001"
    
    # Coordonnées
    BusinessPhones = @("+33 1 23 45 67 89")
    MobilePhone = "+33 6 12 34 56 78"
    StreetAddress = "Starfleet Headquarters"
    City = "Paris"
    State = "Ile-de-France"
    PostalCode = "75001"
    Country = "France"
}

$user = New-MgUser @userParams

Write-Host "✓ Utilisateur créé avec tous les détails" -ForegroundColor Green
```

### Fonction de création d'utilisateur réutilisable

```powershell
function New-EnterpriseCrewMember {
    <#
    .SYNOPSIS
        Crée un nouveau membre d'équipage de l'USS Enterprise
    .PARAMETER FirstName
        Prénom
    .PARAMETER LastName
        Nom de famille
    .PARAMETER Rank
        Grade (Captain, Commander, Lieutenant, etc.)
    .PARAMETER Department
        Département (Command, Engineering, Medical, etc.)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FirstName,
        
        [Parameter(Mandatory=$true)]
        [string]$LastName,
        
        [Parameter(Mandatory=$true)]
        [string]$Rank,
        
        [Parameter(Mandatory=$true)]
        [string]$Department
    )
    
    try {
        # Construire les identifiants
        $displayName = "$Rank $FirstName $LastName"
        $mailNickname = "$($FirstName.ToLower()).$($LastName.ToLower())"
        $upn = "$mailNickname@uss-enterprise.onmicrosoft.com"
        
        # Générer un mot de passe temporaire sécurisé
        $password = "Starfleet$(Get-Random -Minimum 1000 -Maximum 9999)!"
        
        $passwordProfile = @{
            Password = $password
            ForceChangePasswordNextSignIn = $true
        }
        
        # Créer l'utilisateur
        $user = New-MgUser -DisplayName $displayName `
            -UserPrincipalName $upn `
            -MailNickname $mailNickname `
            -AccountEnabled `
            -PasswordProfile $passwordProfile `
            -Department $Department `
            -JobTitle $Rank `
            -UsageLocation "FR"
        
        Write-Host "✓ Membre d'équipage créé : $displayName" -ForegroundColor Green
        Write-Host "  UPN : $upn" -ForegroundColor Cyan
        Write-Host "  Mot de passe temporaire : $password" -ForegroundColor Yellow
        Write-Host "  ⚠️  À communiquer de manière sécurisée!" -ForegroundColor Red
        
        return @{
            User = $user
            Password = $password
        }
        
    } catch {
        Write-Error "Erreur lors de la création de l'utilisateur : $_"
        throw
    }
}

# Utilisation
New-EnterpriseCrewMember -FirstName "James" -LastName "Kirk" `
    -Rank "Captain" -Department "Command"
```

### Créer plusieurs utilisateurs en masse

```powershell
# Définir une liste d'utilisateurs
$crewMembers = @(
    @{FirstName="James"; LastName="Kirk"; Rank="Captain"; Department="Command"},
    @{FirstName="Spock"; LastName=""; Rank="Commander"; Department="Science"},
    @{FirstName="Leonard"; LastName="McCoy"; Rank="Doctor"; Department="Medical"},
    @{FirstName="Montgomery"; LastName="Scott"; Rank="Commander"; Department="Engineering"},
    @{FirstName="Nyota"; LastName="Uhura"; Rank="Lieutenant"; Department="Communications"}
)

# Créer tous les utilisateurs
$createdUsers = @()
foreach ($member in $crewMembers) {
    $result = New-EnterpriseCrewMember @member
    $createdUsers += $result
    Start-Sleep -Seconds 1  # Pause pour éviter le throttling
}

# Exporter les credentials (ATTENTION : fichier sensible!)
$createdUsers | ConvertTo-Json | Out-File "./users-credentials-PRIVATE.json" -Encoding UTF8

Write-Host "`n⚠️  IMPORTANT : Fichier credentials créé - À distribuer puis SUPPRIMER!" -ForegroundColor Red
```

---

## ✏️ Modifier des utilisateurs

### Modifier un utilisateur existant

```powershell
# Modifier le département et le titre
Update-MgUser -UserId "james.kirk@uss-enterprise.com" `
    -Department "Command" `
    -JobTitle "Fleet Admiral"

Write-Host "✓ Utilisateur mis à jour" -ForegroundColor Green
```

### Modifier plusieurs propriétés

```powershell
$userId = "james.kirk@uss-enterprise.com"

Update-MgUser -UserId $userId `
    -Department "Command" `
    -JobTitle "Fleet Admiral" `
    -OfficeLocation "Starfleet Headquarters" `
    -MobilePhone "+33 6 12 34 56 78"
```

### Activer/Désactiver un compte

```powershell
# Désactiver un compte
Update-MgUser -UserId "james.kirk@uss-enterprise.com" -AccountEnabled:$false

Write-Host "✓ Compte désactivé" -ForegroundColor Yellow

# Réactiver un compte
Update-MgUser -UserId "james.kirk@uss-enterprise.com" -AccountEnabled:$true

Write-Host "✓ Compte réactivé" -ForegroundColor Green
```

### Forcer le changement de mot de passe

```powershell
$userId = "james.kirk@uss-enterprise.com"

Update-MgUser -UserId $userId -PasswordProfile @{
    ForceChangePasswordNextSignIn = $true
}

Write-Host "✓ Changement de mot de passe obligatoire activé" -ForegroundColor Green
```

### Réinitialiser le mot de passe

```powershell
# Générer un nouveau mot de passe
$newPassword = "NouveauMotDePasse123!"

$passwordProfile = @{
    Password = $newPassword
    ForceChangePasswordNextSignIn = $true
}

Update-MgUser -UserId "james.kirk@uss-enterprise.com" `
    -PasswordProfile $passwordProfile

Write-Host "✓ Mot de passe réinitialisé" -ForegroundColor Green
Write-Host "  Nouveau mot de passe : $newPassword" -ForegroundColor Yellow
```

---

## 🗑️ Supprimer des utilisateurs

### Supprimer un utilisateur

```powershell
# Supprimer (envoi dans la corbeille pendant 30 jours)
Remove-MgUser -UserId "james.kirk@uss-enterprise.com"

Write-Host "✓ Utilisateur supprimé (soft delete)" -ForegroundColor Yellow
Write-Host "  L'utilisateur peut être restauré pendant 30 jours" -ForegroundColor Cyan
```

### Restaurer un utilisateur supprimé

```powershell
# Lister les utilisateurs supprimés
Get-MgDirectoryDeletedItem -DirectoryObjectId (Get-MgUser).Id

# Restaurer un utilisateur
Restore-MgDirectoryDeletedItem -DirectoryObjectId "USER-OBJECT-ID"

Write-Host "✓ Utilisateur restauré" -ForegroundColor Green
```

### Supprimer définitivement

```powershell
# Supprimer définitivement (hard delete - IRRÉVERSIBLE!)
Remove-MgDirectoryDeletedItem -DirectoryObjectId "USER-OBJECT-ID"

Write-Host "⚠️  Utilisateur supprimé définitivement (irréversible)" -ForegroundColor Red
```

---

## 👤 Gestion des propriétés étendues

### Attributs personnalisés (Extension Attributes)

```powershell
# Définir des attributs personnalisés
$userId = "james.kirk@uss-enterprise.com"

# Azure AD supporte 15 attributs d'extension (extensionAttribute1 à extensionAttribute15)
Update-MgUser -UserId $userId `
    -OnPremisesExtensionAttributes @{
        extensionAttribute1 = "ClearanceLevel:TopSecret"
        extensionAttribute2 = "ShipAssignment:NCC-1701"
        extensionAttribute3 = "MissionType:Exploration"
    }

Write-Host "✓ Attributs étendus configurés" -ForegroundColor Green
```

### Lire les attributs étendus

```powershell
$user = Get-MgUser -UserId "james.kirk@uss-enterprise.com" `
    -Property "OnPremisesExtensionAttributes"

Write-Host "Attributs étendus :" -ForegroundColor Cyan
$user.OnPremisesExtensionAttributes | Format-List
```

---

## 📊 Requêtes et filtres avancés

### Filtres complexes

```powershell
# Utilisateurs d'un département spécifique
Get-MgUser -Filter "department eq 'Engineering'" | 
    Select-Object DisplayName, JobTitle

# Utilisateurs avec un titre spécifique
Get-MgUser -Filter "jobTitle eq 'Captain'" | 
    Select-Object DisplayName, Department

# Utilisateurs créés récemment (derniers 7 jours)
$date = (Get-Date).AddDays(-7).ToString("yyyy-MM-ddTHH:mm:ssZ")
Get-MgUser -Filter "createdDateTime ge $date" | 
    Select-Object DisplayName, CreatedDateTime

# Utilisateurs activés seulement
Get-MgUser -Filter "accountEnabled eq true" | 
    Select-Object DisplayName, UserPrincipalName

# Recherche dans le nom
Get-MgUser -Filter "startswith(displayName, 'Captain')" | 
    Select-Object DisplayName

# Combinaisons
Get-MgUser -Filter "department eq 'Engineering' and accountEnabled eq true" | 
    Select-Object DisplayName, JobTitle
```

### Tri et pagination

```powershell
# Trier par nom d'affichage
Get-MgUser -Sort "displayName" | Select-Object DisplayName

# Top 20 utilisateurs
Get-MgUser -Top 20 | Select-Object DisplayName, UserPrincipalName

# Pagination manuelle
$users = Get-MgUser -Top 10
# Traiter le premier lot
# Récupérer le lot suivant avec -Skip
$moreUsers = Get-MgUser -Top 10 -Skip 10
```

---

## 🔐 Gestion des sessions et sécurité

### Révoquer toutes les sessions d'un utilisateur

```powershell
# Révoquer les sessions (force une nouvelle connexion)
Revoke-MgUserSignInSession -UserId "james.kirk@uss-enterprise.com"

Write-Host "✓ Sessions révoquées - l'utilisateur devra se reconnecter" -ForegroundColor Yellow
```

### Vérifier le statut de connexion

```powershell
# Obtenir les informations de connexion (nécessite AuditLog.Read.All)
Connect-MgGraph -Scopes "AuditLog.Read.All"

# Dernières connexions d'un utilisateur
$signIns = Get-MgAuditLogSignIn -Filter "userPrincipalName eq 'james.kirk@uss-enterprise.com'" -Top 10

$signIns | Select-Object CreatedDateTime, AppDisplayName, IpAddress, Location | Format-Table
```

---

## 📝 Scripts utiles

### Script : Audit des utilisateurs

```powershell
<#
.SYNOPSIS
    Génère un rapport d'audit des utilisateurs
#>

function Get-UserAuditReport {
    Connect-MgGraph -Scopes "User.Read.All"
    
    Write-Host "Génération du rapport d'audit des utilisateurs..." -ForegroundColor Cyan
    
    $users = Get-MgUser -All
    
    $report = $users | Select-Object `
        DisplayName,
        UserPrincipalName,
        Department,
        JobTitle,
        AccountEnabled,
        @{Name='CreatedDate'; Expression={$_.CreatedDateTime}},
        @{Name='LastPasswordChange'; Expression={$_.LastPasswordChangeDateTime}}
    
    # Exporter en CSV
    $report | Export-Csv -Path "./reports/user-audit-$(Get-Date -Format 'yyyyMMdd').csv" `
        -NoTypeInformation -Encoding UTF8
    
    Write-Host "✓ Rapport généré : ./reports/user-audit-$(Get-Date -Format 'yyyyMMdd').csv" -ForegroundColor Green
    
    # Statistiques
    Write-Host "`n=== Statistiques ===" -ForegroundColor Cyan
    Write-Host "Total utilisateurs : $($users.Count)" -ForegroundColor Yellow
    Write-Host "Comptes actifs : $(($users | Where-Object {$_.AccountEnabled}).Count)" -ForegroundColor Green
    Write-Host "Comptes désactivés : $(($users | Where-Object {-not $_.AccountEnabled}).Count)" -ForegroundColor Red
}

Get-UserAuditReport
```

### Script : Nettoyage des utilisateurs inactifs

```powershell
<#
.SYNOPSIS
    Liste les utilisateurs qui ne se sont pas connectés depuis X jours
#>

function Get-InactiveUsers {
    param(
        [int]$DaysInactive = 90
    )
    
    Connect-MgGraph -Scopes "User.Read.All", "AuditLog.Read.All"
    
    $cutoffDate = (Get-Date).AddDays(-$DaysInactive)
    
    Write-Host "Recherche des utilisateurs inactifs depuis $DaysInactive jours..." -ForegroundColor Cyan
    
    $users = Get-MgUser -All
    $inactiveUsers = @()
    
    foreach ($user in $users) {
        # Obtenir la dernière connexion
        $lastSignIn = Get-MgAuditLogSignIn -Filter "userId eq '$($user.Id)'" `
            -Top 1 -Sort "createdDateTime desc"
        
        if (-not $lastSignIn -or $lastSignIn.CreatedDateTime -lt $cutoffDate) {
            $inactiveUsers += [PSCustomObject]@{
                DisplayName = $user.DisplayName
                UserPrincipalName = $user.UserPrincipalName
                LastSignIn = if ($lastSignIn) { $lastSignIn.CreatedDateTime } else { "Jamais" }
                Department = $user.Department
            }
        }
    }
    
    Write-Host "`nUtilisateurs inactifs trouvés : $($inactiveUsers.Count)" -ForegroundColor Yellow
    $inactiveUsers | Format-Table
    
    # Exporter
    $inactiveUsers | Export-Csv -Path "./reports/inactive-users-$(Get-Date -Format 'yyyyMMdd').csv" `
        -NoTypeInformation -Encoding UTF8
}

Get-InactiveUsers -DaysInactive 90
```

---

## 🎯 Résumé des commandes essentielles

| Action | Commande |
|--------|----------|
| **Lister les utilisateurs** | `Get-MgUser` |
| **Chercher un utilisateur** | `Get-MgUser -UserId "email@domain.com"` |
| **Créer un utilisateur** | `New-MgUser -DisplayName "Name" -UserPrincipalName "email"` |
| **Modifier un utilisateur** | `Update-MgUser -UserId "email" -Department "Dept"` |
| **Désactiver un compte** | `Update-MgUser -UserId "email" -AccountEnabled:$false` |
| **Supprimer un utilisateur** | `Remove-MgUser -UserId "email"` |
| **Révoquer les sessions** | `Revoke-MgUserSignInSession -UserId "email"` |
| **Filtrer** | `Get-MgUser -Filter "department eq 'IT'"` |

---

## ⚠️ Bonnes pratiques

### ✅ À FAIRE
- Toujours définir `UsageLocation` (obligatoire pour les licences)
- Forcer le changement de mot de passe à la première connexion
- Utiliser des mots de passe complexes générés aléatoirement
- Documenter les comptes créés
- Désactiver les comptes plutôt que les supprimer (sauf si nécessaire)
- Utiliser des noms d'utilisateur cohérents (prenom.nom@domain.com)

### ❌ À ÉVITER
- Créer des utilisateurs sans mot de passe
- Utiliser des mots de passe simples ou réutilisés
- Supprimer des utilisateurs sans sauvegarde
- Oublier d'assigner un département/titre
- Créer des comptes sans plan de gestion
- Ne pas révoquer les accès des comptes inactifs

---

## 📚 Ressources complémentaires

- [Microsoft Graph User API](https://learn.microsoft.com/en-us/graph/api/resources/user)
- [PowerShell User Cmdlets](https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.users/)
- [Filtres OData](https://learn.microsoft.com/en-us/graph/query-parameters)

---

**Date de création** : Novembre 2024  
**Version** : 1.0  
**Projet** : USS Enterprise - Entra ID Security