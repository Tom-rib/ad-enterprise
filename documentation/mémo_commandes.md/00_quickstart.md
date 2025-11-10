# 🚀 Quick Start - USS Enterprise (30 minutes)

## ⚡ Parcours express pour démarrer rapidement

**Temps total : ~30 minutes**

---

## 📋 Vue d'ensemble

Ce guide express vous permet de créer rapidement une infrastructure de base. Pour une compréhension complète, consultez [00-DEMARRER-ICI.md](./00-DEMARRER-ICI.md).

---

## 🎯 Étapes rapides

### 1️⃣ Installation (5 minutes)

```powershell
# Installer PowerShell 7 (si pas déjà fait)
winget install --id Microsoft.Powershell --source winget

# Redémarrer le terminal PowerShell

# Installer le module Graph
Install-Module -Name Microsoft.Graph -Force -Scope CurrentUser

# Autoriser l'exécution de scripts
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 2️⃣ Créer le tenant (5 minutes - via navigateur)

1. Aller sur https://azure.microsoft.com/fr-fr/free/students/
2. Cliquer "Activer maintenant"
3. Se connecter avec email étudiant
4. Suivre les instructions
5. Noter votre **Tenant ID**

**OU**

1. Aller sur https://developer.microsoft.com/microsoft-365/dev-program
2. S'inscrire au programme développeur
3. Créer un abonnement instantané
4. Nom du tenant : `uss-enterprise`

### 3️⃣ Connexion (2 minutes)

```powershell
# Se connecter avec TOUS les scopes nécessaires
Connect-MgGraph -Scopes @(
    "User.ReadWrite.All",
    "Group.ReadWrite.All",
    "Directory.ReadWrite.All",
    "Policy.ReadWrite.ConditionalAccess",
    "RoleManagement.ReadWrite.Directory",
    "Organization.ReadWrite.All"
)

# Vérifier la connexion
Get-MgContext

# Voir votre tenant
Get-MgOrganization | Select-Object DisplayName, Id
```

### 4️⃣ Script tout-en-un (15 minutes)

Copiez-collez et exécutez ce script complet :

```powershell
<#
.SYNOPSIS
    Script tout-en-un pour créer l'infrastructure USS Enterprise
#>

Write-Host "`n🚀 === USS ENTERPRISE - QUICK START ===" -ForegroundColor Cyan
Write-Host "Création de l'infrastructure complète...`n" -ForegroundColor Yellow

# 1. COMPTE D'URGENCE
Write-Host "[1/5] Création du compte d'urgence..." -ForegroundColor Yellow
$emergencyPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 24 | ForEach-Object {[char]$_})

$emergencyUser = New-MgUser `
    -DisplayName "Emergency Admin" `
    -UserPrincipalName "emergency-admin@$((Get-MgOrganization).VerifiedDomains[0].Name)" `
    -MailNickname "emergency-admin" `
    -AccountEnabled:$true `
    -PasswordProfile @{ Password = $emergencyPassword; ForceChangePasswordNextSignIn = $false } `
    -UsageLocation "FR"

$globalAdminRole = Get-MgDirectoryRoleTemplate | Where-Object { $_.DisplayName -eq "Global Administrator" }
$activeRole = Get-MgDirectoryRole | Where-Object { $_.RoleTemplateId -eq $globalAdminRole.Id }
if (-not $activeRole) {
    $activeRole = New-MgDirectoryRole -RoleTemplateId $globalAdminRole.Id
}
New-MgDirectoryRoleMemberByRef -DirectoryRoleId $activeRole.Id -BodyParameter @{
    "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($emergencyUser.Id)"
}

Write-Host "✓ Compte d'urgence : $($emergencyUser.UserPrincipalName)" -ForegroundColor Green
Write-Host "  Mot de passe : $emergencyPassword" -ForegroundColor Red
Write-Host "  ⚠️  À SAUVEGARDER IMMÉDIATEMENT !`n" -ForegroundColor Yellow

# 2. GROUPES
Write-Host "[2/5] Création des groupes..." -ForegroundColor Yellow
$groupNames = @(
    "Command Team",
    "Engineering Team", 
    "Medical Team",
    "Science Team",
    "Security Team"
)

$groups = @{}
foreach ($name in $groupNames) {
    $group = New-MgGroup `
        -DisplayName $name `
        -MailEnabled:$false `
        -SecurityEnabled:$true `
        -MailNickname ($name -replace '\s', '').ToLower()
    $groups[$name] = $group
    Write-Host "  ✓ $name" -ForegroundColor Green
}

# 3. UTILISATEURS
Write-Host "`n[3/5] Création des utilisateurs..." -ForegroundColor Yellow
$crew = @(
    @{First="James"; Last="Kirk"; Rank="Captain"; Dept="Command"; Group="Command Team"},
    @{First="Spock"; Last=""; Rank="Commander"; Dept="Science"; Group="Science Team"},
    @{First="Leonard"; Last="McCoy"; Rank="Doctor"; Dept="Medical"; Group="Medical Team"},
    @{First="Montgomery"; Last="Scott"; Rank="Commander"; Dept="Engineering"; Group="Engineering Team"}
)

$domain = (Get-MgOrganization).VerifiedDomains[0].Name
foreach ($member in $crew) {
    $firstName = $member.First
    $lastName = $member.Last
    $displayName = if ($lastName) { "$($member.Rank) $firstName $lastName" } else { "$($member.Rank) $firstName" }
    $mailNickname = if ($lastName) { "$($firstName.ToLower()).$($lastName.ToLower())" } else { $firstName.ToLower() }
    $upn = "$mailNickname@$domain"
    $password = "Starfleet$(Get-Random -Minimum 1000 -Maximum 9999)!"
    
    $user = New-MgUser `
        -DisplayName $displayName `
        -UserPrincipalName $upn `
        -MailNickname $mailNickname `
        -AccountEnabled:$true `
        -PasswordProfile @{ Password = $password; ForceChangePasswordNextSignIn = $true } `
        -Department $member.Dept `
        -JobTitle $member.Rank `
        -UsageLocation "FR"
    
    # Ajouter au groupe
    New-MgGroupMember -GroupId $groups[$member.Group].Id -DirectoryObjectId $user.Id
    
    Write-Host "  ✓ $displayName ($upn) - Pwd: $password" -ForegroundColor Green
}

# 4. RÔLES
Write-Host "`n[4/5] Attribution des rôles..." -ForegroundColor Yellow
$kirk = Get-MgUser -Filter "startswith(userPrincipalName, 'james.kirk')"
$spock = Get-MgUser -Filter "startswith(userPrincipalName, 'spock')"

# Kirk = Global Admin
New-MgDirectoryRoleMemberByRef -DirectoryRoleId $activeRole.Id -BodyParameter @{
    "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($kirk.Id)"
}
Write-Host "  ✓ James Kirk → Global Administrator" -ForegroundColor Green

# Spock = Security Admin
$secAdminRole = Get-MgDirectoryRoleTemplate | Where-Object { $_.DisplayName -eq "Security Administrator" }
$activeSecRole = Get-MgDirectoryRole | Where-Object { $_.RoleTemplateId -eq $secAdminRole.Id }
if (-not $activeSecRole) {
    $activeSecRole = New-MgDirectoryRole -RoleTemplateId $secAdminRole.Id
}
New-MgDirectoryRoleMemberByRef -DirectoryRoleId $activeSecRole.Id -BodyParameter @{
    "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($spock.Id)"
}
Write-Host "  ✓ Spock → Security Administrator" -ForegroundColor Green

# 5. SÉCURITÉ DE BASE
Write-Host "`n[5/5] Configuration sécurité..." -ForegroundColor Yellow

# MFA pour administrateurs
$mfaPolicy = @{
    DisplayName = "MFA - Administrators"
    State = "enabled"
    Conditions = @{
        Users = @{
            IncludeRoles = @("62e90394-69f5-4237-9190-012177145e10")  # Global Admin
            ExcludeUsers = @($emergencyUser.Id)
        }
        Applications = @{ IncludeApplications = @("All") }
    }
    GrantControls = @{
        Operator = "OR"
        BuiltInControls = @("mfa")
    }
}
New-MgIdentityConditionalAccessPolicy -BodyParameter $mfaPolicy
Write-Host "  ✓ Politique MFA créée" -ForegroundColor Green

# Blocage authentification héritée
$legacyAuthPolicy = @{
    DisplayName = "Block Legacy Auth"
    State = "enabled"
    Conditions = @{
        Users = @{
            IncludeUsers = @("All")
            ExcludeUsers = @($emergencyUser.Id)
        }
        Applications = @{ IncludeApplications = @("All") }
        ClientAppTypes = @("exchangeActiveSync", "other")
    }
    GrantControls = @{
        Operator = "OR"
        BuiltInControls = @("block")
    }
}
New-MgIdentityConditionalAccessPolicy -BodyParameter $legacyAuthPolicy
Write-Host "  ✓ Authentification héritée bloquée" -ForegroundColor Green

# RÉSUMÉ
Write-Host "`n🎉 === INFRASTRUCTURE CRÉÉE ===" -ForegroundColor Green
Write-Host "`nCOMPTE D'URGENCE (CRITIQUE) :" -ForegroundColor Red
Write-Host "  UPN : $($emergencyUser.UserPrincipalName)" -ForegroundColor Yellow
Write-Host "  Mot de passe : $emergencyPassword" -ForegroundColor Yellow
Write-Host "`nUtilisateurs créés : 4" -ForegroundColor Cyan
Write-Host "Groupes créés : $($groups.Count)" -ForegroundColor Cyan
Write-Host "Politiques de sécurité : 2" -ForegroundColor Cyan
Write-Host "`n✅ L'infrastructure USS Enterprise est prête !" -ForegroundColor Green
Write-Host "`n⚠️  ACTIONS SUIVANTES :" -ForegroundColor Yellow
Write-Host "1. Sauvegarder le mot de passe du compte d'urgence" -ForegroundColor White
Write-Host "2. Distribuer les mots de passe aux utilisateurs" -ForegroundColor White
Write-Host "3. Configurer les méthodes MFA" -ForegroundColor White
Write-Host "4. Ajouter plus de politiques de sécurité (Guide 07)" -ForegroundColor White
```

### 5️⃣ Vérification (3 minutes)

```powershell
# Vérifier les utilisateurs
Write-Host "`n=== UTILISATEURS ===" -ForegroundColor Cyan
Get-MgUser | Select-Object DisplayName, UserPrincipalName, Department | Format-Table

# Vérifier les groupes
Write-Host "`n=== GROUPES ===" -ForegroundColor Cyan
Get-MgGroup | Select-Object DisplayName, Id | Format-Table

# Vérifier les politiques
Write-Host "`n=== POLITIQUES ===" -ForegroundColor Cyan
Get-MgIdentityConditionalAccessPolicy | Select-Object DisplayName, State | Format-Table

Write-Host "✅ Vérification terminée !`n" -ForegroundColor Green
```

---

## 📊 Résultat en 30 minutes

Vous aurez créé :

### ✅ Infrastructure de base
- 1 Tenant Azure AD configuré
- 1 Compte d'urgence (Break Glass)
- 4 Utilisateurs principaux
- 5 Groupes de sécurité
- 2 Politiques de sécurité

### 👤 Utilisateurs
- Captain James Kirk (Command) - Global Admin
- Commander Spock (Science) - Security Admin
- Dr. Leonard McCoy (Medical)
- Commander Montgomery Scott (Engineering)

### 👥 Groupes
- Command Team
- Engineering Team
- Medical Team
- Science Team
- Security Team

### 🔐 Sécurité
- MFA pour administrateurs
- Blocage authentification héritée
- Compte d'urgence sécurisé

---

## ⚠️ IMPORTANT - À faire immédiatement

### 1. Sauvegarder le compte d'urgence
Le mot de passe du compte d'urgence a été affiché UNE SEULE FOIS.
**→ Notez-le dans un endroit très sécurisé !**

### 2. Distribuer les mots de passe
Les mots de passe des utilisateurs ont été affichés.
**→ Communiquez-les de manière sécurisée**

### 3. Exclure le compte d'urgence
**→ Le compte d'urgence doit être exclu de TOUTES les politiques MFA**

---

## 🚀 Prochaines étapes

Votre infrastructure de base est prête ! Maintenant :

### Option 1 : Approfondir (recommandé)
Consultez les guides détaillés pour comprendre chaque composant :
- [Guide 07](./07-MFA-Acces-Conditionnel.md) - Ajouter plus de sécurité
- [Guide 03](./03-Gestion-Groupes.md) - Groupes dynamiques
- [Guide 04](./04-Gestion-Roles.md) - Rôles avancés

### Option 2 : Continuer rapidement
```powershell
# Ajouter des emplacements nommés
$france = New-MgIdentityConditionalAccessNamedLocation -BodyParameter @{
    "@odata.type" = "#microsoft.graph.countryNamedLocation"
    DisplayName = "France"
    CountriesAndRegions = @("FR")
    IncludeUnknownCountriesAndRegions = $false
}

# Politique de blocage géographique
$geoBlock = @{
    DisplayName = "Block Unauthorized Locations"
    State = "enabled"
    Conditions = @{
        Users = @{ IncludeUsers = @("All"); ExcludeUsers = @("EMERGENCY-ID") }
        Applications = @{ IncludeApplications = @("All") }
        Locations = @{
            IncludeLocations = @("All")
            ExcludeLocations = @($france.Id, "AllTrusted")
        }
    }
    GrantControls = @{
        Operator = "OR"
        BuiltInControls = @("block")
    }
}
New-MgIdentityConditionalAccessPolicy -BodyParameter $geoBlock
```

---

## 🔍 Commandes de dépannage

### Si quelque chose ne fonctionne pas

```powershell
# Vérifier la connexion
Get-MgContext

# Reconnecter si nécessaire
Disconnect-MgGraph
Connect-MgGraph -Scopes @(
    "User.ReadWrite.All",
    "Group.ReadWrite.All",
    "Directory.ReadWrite.All",
    "Policy.ReadWrite.ConditionalAccess",
    "RoleManagement.ReadWrite.Directory"
)

# Vérifier les permissions
(Get-MgContext).Scopes
```

### Erreurs courantes

| Erreur | Solution |
|--------|----------|
| "Insufficient privileges" | Reconnecter avec plus de scopes |
| "User already exists" | Changer le nom d'utilisateur |
| "Module not found" | `Install-Module Microsoft.Graph -Force` |
| "Scripts disabled" | `Set-ExecutionPolicy RemoteSigned` |

---

## 📚 Aller plus loin

### Documentation complète
Consultez les guides complets pour maîtriser chaque aspect :

1. [00-DEMARRER-ICI.md](./00-DEMARRER-ICI.md) - Parcours complet
2. [07-MFA-Acces-Conditionnel.md](./07-MFA-Acces-Conditionnel.md) - Sécurité avancée
3. [06-Creation-Configuration-Tenant.md](./06-Creation-Configuration-Tenant.md) - Configuration tenant

### Scripts additionnels
Tous les scripts avancés sont disponibles dans les guides :
- Groupes dynamiques
- Rôles d'application
- Surveillance et logs
- Simulation d'incidents
- Intégration applications

---

## ✅ Checklist Quick Start

- [ ] PowerShell 7+ installé
- [ ] Module Microsoft.Graph installé
- [ ] Tenant créé (Azure for Students ou M365 Dev)
- [ ] Connecté avec tous les scopes
- [ ] Script tout-en-un exécuté
- [ ] Compte d'urgence sauvegardé ⚠️ CRITIQUE
- [ ] Vérification effectuée
- [ ] Prêt pour la suite !

---

## 🎉 Félicitations !

En 30 minutes, vous avez créé une infrastructure Azure AD complète !

**Temps passé :** ~30 minutes  
**Infrastructure créée :** ✅ Complète  
**Sécurité de base :** ✅ Active  
**Prêt pour le projet :** ✅ OUI  

**Maintenant, explorez les guides détaillés pour aller plus loin ! 🚀**

---

**Version** : 1.0 - Quick Start  
**Projet** : USS Enterprise - Entra ID Security  
**Date** : Novembre 2024