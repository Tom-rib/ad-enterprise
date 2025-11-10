# Guide 01 - Création et Configuration du Tenant Azure AD

## 📚 À quoi ça sert ?

Le **tenant** (ou locataire) est votre organisation dans le cloud Azure AD. C'est l'instance dédiée d'Entra ID qui contient tous vos utilisateurs, groupes, applications et configurations de sécurité.

### Pourquoi configurer un tenant ?
- **Isolation** : Environnement dédié et isolé pour votre organisation
- **Identité** : Point central pour toutes les authentifications
- **Sécurité** : Contrôle complet sur les accès et permissions
- **Conformité** : Respect des réglementations et standards

---

## 🆕 Créer un nouveau tenant Azure AD

### Option 1 : Azure for Students (Gratuit - Recommandé)

#### Prérequis
- Email étudiant (@edu ou reconnu par Azure)
- Pas de carte bancaire nécessaire

#### Étapes de création

```powershell
# 1. Accéder au portail Azure for Students
# URL : https://azure.microsoft.com/fr-fr/free/students/

# 2. Cliquer sur "Activer maintenant"
# 3. Se connecter avec email étudiant
# 4. Vérifier le statut étudiant
# 5. Accepter les conditions
```

**Avantages :**
- 100$ de crédit Azure
- Services gratuits pendant 12 mois
- Pas besoin de carte bancaire
- Azure AD Premium P2 (essai 30 jours)

### Option 2 : Microsoft 365 Developer Program (Gratuit)

#### Création du tenant développeur

```powershell
# 1. S'inscrire au programme développeur
# URL : https://developer.microsoft.com/en-us/microsoft-365/dev-program

# 2. Créer un profil développeur
# 3. Configurer un abonnement instantané
#    - Nom du tenant : uss-enterprise
#    - Domaine : uss-enterprise.onmicrosoft.com
#    - Région : Votre région
#    - Admin : Votre compte

# 4. Recevoir les identifiants administrateur
```

**Avantages :**
- Tenant gratuit renouvelable tous les 90 jours
- Microsoft 365 E5 inclus
- Azure AD Premium P2 inclus
- 25 utilisateurs de test préconfigurés

### Option 3 : Azure Trial (Essai gratuit)

```powershell
# 1. Accéder à Azure Portal
# URL : https://azure.microsoft.com/fr-fr/free/

# 2. Cliquer sur "Commencer gratuitement"
# 3. Se connecter avec compte Microsoft
# 4. Fournir informations :
#    - Téléphone pour vérification
#    - Carte bancaire (non débitée)
# 5. Créer le tenant
```

**Avantages :**
- 200$ de crédit pour 30 jours
- Services gratuits pendant 12 mois
- Accès complet à Azure

---

## ⚙️ Configuration initiale du tenant

### 1. Accéder au tenant via PowerShell

```powershell
# Se connecter au tenant
Connect-MgGraph -TenantId "VOTRE-TENANT-ID"

# Ou avec le domaine
Connect-MgGraph -TenantId "uss-enterprise.onmicrosoft.com"

# Vérifier la connexion
$context = Get-MgContext
Write-Host "Tenant : $($context.TenantId)"
```

### 2. Configurer les informations du tenant

```powershell
# Obtenir les informations actuelles
$org = Get-MgOrganization

Write-Host "Nom : $($org.DisplayName)"
Write-Host "ID : $($org.Id)"
Write-Host "Domaine : $($org.VerifiedDomains[0].Name)"

# Mettre à jour les informations
Update-MgOrganization -OrganizationId $org.Id `
    -DisplayName "USS Enterprise" `
    -TechnicalNotificationMails @("admin@uss-enterprise.onmicrosoft.com") `
    -MarketingNotificationEmails @("comms@uss-enterprise.onmicrosoft.com")

Write-Host "✓ Informations du tenant mises à jour" -ForegroundColor Green
```

### 3. Configurer les paramètres de sécurité par défaut

```powershell
# Activer les paramètres de sécurité par défaut
# Note : Ceci nécessite l'accès au portail Azure

# Via le portail :
# 1. Portail Azure > Entra ID > Propriétés
# 2. Gérer les paramètres de sécurité par défaut
# 3. Activer les paramètres de sécurité

# Ce qui est activé automatiquement :
# - MFA pour les administrateurs
# - MFA pour les utilisateurs quand nécessaire
# - Blocage des protocoles d'authentification hérités
# - Protection Azure AD Identity Protection
```

### 4. Configurer les paramètres de mot de passe

```powershell
# Configurer la politique de mot de passe
# Via PowerShell avec MSOnline (si disponible)

# Installer le module si nécessaire
# Install-Module -Name MSOnline -Force

Connect-MsolService

# Obtenir la politique actuelle
Get-MsolPasswordPolicy

# Définir une nouvelle politique
Set-MsolPasswordPolicy -ValidityPeriod 90 -NotificationDays 14

Write-Host "✓ Politique de mot de passe configurée" -ForegroundColor Green
```

---

## 🏢 Configurer le domaine personnalisé (Optionnel)

### Ajouter un domaine personnalisé

```powershell
# 1. Ajouter le domaine
$domain = New-MgDomain -Id "uss-enterprise.com"

Write-Host "Domaine ajouté : $($domain.Id)" -ForegroundColor Green

# 2. Obtenir les enregistrements DNS à configurer
$verification = Get-MgDomainVerificationDnsRecord -DomainId "uss-enterprise.com"

foreach ($record in $verification) {
    Write-Host "`nType : $($record.RecordType)"
    Write-Host "Nom : $($record.Label)"
    Write-Host "Valeur : $($record.Text)"
}

# 3. Configurer les enregistrements DNS chez votre registrar
# (Cette étape se fait sur le site de votre hébergeur de domaine)

# 4. Vérifier le domaine (après configuration DNS)
Confirm-MgDomain -DomainId "uss-enterprise.com"

# 5. Définir comme domaine par défaut
Update-MgDomain -DomainId "uss-enterprise.com" -IsDefault

Write-Host "✓ Domaine personnalisé configuré" -ForegroundColor Green
```

---

## 📋 Configuration des licences

### Vérifier les licences disponibles

```powershell
# Lister toutes les licences
$licenses = Get-MgSubscribedSku

foreach ($license in $licenses) {
    Write-Host "`n=== $($license.SkuPartNumber) ===" -ForegroundColor Cyan
    Write-Host "Total : $($license.PrepaidUnits.Enabled)"
    Write-Host "Consommées : $($license.ConsumedUnits)"
    Write-Host "Disponibles : $($license.PrepaidUnits.Enabled - $license.ConsumedUnits)"
}
```

### Activer l'essai Azure AD Premium P2

```powershell
# Via le portail Azure
# 1. Entra ID > Licences > Tous les produits
# 2. Essayer/Acheter
# 3. Sélectionner Azure Active Directory Premium P2
# 4. Essai gratuit (30 jours)

# Vérifier l'activation
$licenses = Get-MgSubscribedSku | Where-Object { $_.SkuPartNumber -like "*AAD_PREMIUM*" }

if ($licenses) {
    Write-Host "✓ Azure AD Premium activé" -ForegroundColor Green
    foreach ($license in $licenses) {
        Write-Host "  - $($license.SkuPartNumber) : $($license.PrepaidUnits.Enabled) licences"
    }
} else {
    Write-Host "⚠️  Azure AD Premium non activé" -ForegroundColor Yellow
}
```

### Assigner des licences aux utilisateurs

```powershell
# Fonction pour assigner une licence
function Set-UserLicense {
    param(
        [string]$UserPrincipalName,
        [string]$SkuPartNumber
    )
    
    # Obtenir l'utilisateur
    $user = Get-MgUser -Filter "userPrincipalName eq '$UserPrincipalName'"
    
    # Obtenir le SKU
    $sku = Get-MgSubscribedSku | Where-Object { $_.SkuPartNumber -eq $SkuPartNumber }
    
    # Assigner la licence
    Set-MgUserLicense -UserId $user.Id `
        -AddLicenses @{SkuId = $sku.SkuId} `
        -RemoveLicenses @()
    
    Write-Host "✓ Licence $SkuPartNumber assignée à $UserPrincipalName" -ForegroundColor Green
}

# Utilisation
Set-UserLicense -UserPrincipalName "james.kirk@uss-enterprise.com" `
    -SkuPartNumber "AAD_PREMIUM_P2"
```

---

## 🔐 Configuration de la sécurité du tenant

### 1. Créer le compte d'urgence (Break Glass)

```powershell
function New-EmergencyAccount {
    <#
    .SYNOPSIS
        Crée un compte d'urgence pour l'accès en cas de problème
    #>
    
    # Générer un mot de passe très sécurisé
    $password = -join ((65..90) + (97..122) + (48..57) + (33..47) | 
        Get-Random -Count 32 | ForEach-Object {[char]$_})
    
    $passwordProfile = @{
        Password = $password
        ForceChangePasswordNextSignIn = $false
    }
    
    # Créer le compte
    $emergencyUser = New-MgUser `
        -DisplayName "Emergency Admin - USS Enterprise" `
        -UserPrincipalName "emergency-admin@uss-enterprise.onmicrosoft.com" `
        -MailNickname "emergency-admin" `
        -AccountEnabled:$true `
        -PasswordProfile $passwordProfile `
        -UsageLocation "FR"
    
    # Assigner le rôle Global Administrator
    $globalAdminRole = Get-MgDirectoryRoleTemplate | 
        Where-Object { $_.DisplayName -eq "Global Administrator" }
    
    # Activer le rôle si nécessaire
    $activeRole = Get-MgDirectoryRole | 
        Where-Object { $_.RoleTemplateId -eq $globalAdminRole.Id }
    
    if (-not $activeRole) {
        $activeRole = New-MgDirectoryRole -RoleTemplateId $globalAdminRole.Id
    }
    
    # Assigner le rôle
    $memberRef = @{
        "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($emergencyUser.Id)"
    }
    New-MgDirectoryRoleMemberByRef -DirectoryRoleId $activeRole.Id -BodyParameter $memberRef
    
    # Sauvegarder les informations de manière sécurisée
    $emergencyInfo = @{
        UserPrincipalName = $emergencyUser.UserPrincipalName
        Password = $password
        Created = Get-Date
        Note = "À conserver dans un coffre-fort sécurisé. À exclure de toutes les politiques MFA."
    }
    
    Write-Host "`n=== COMPTE D'URGENCE CRÉÉ ===" -ForegroundColor Red
    Write-Host "⚠️  INFORMATIONS CRITIQUES - À SAUVEGARDER IMMÉDIATEMENT :" -ForegroundColor Yellow
    Write-Host "`nUPN : $($emergencyInfo.UserPrincipalName)" -ForegroundColor Cyan
    Write-Host "Mot de passe : $($emergencyInfo.Password)" -ForegroundColor Cyan
    Write-Host "`n⚠️  ACTIONS REQUISES :" -ForegroundColor Yellow
    Write-Host "1. Sauvegarder ces informations dans un coffre-fort physique" -ForegroundColor White
    Write-Host "2. Exclure ce compte de TOUTES les politiques MFA" -ForegroundColor White
    Write-Host "3. Exclure ce compte de TOUTES les politiques d'accès conditionnel" -ForegroundColor White
    Write-Host "4. Ne JAMAIS utiliser sauf en cas d'urgence absolue" -ForegroundColor White
    
    return $emergencyInfo
}

# Créer le compte
$emergencyAccount = New-EmergencyAccount
```

### 2. Configurer les paramètres d'audit

```powershell
# Activer les logs d'audit (nécessite Azure AD Premium)

# Via le portail :
# 1. Entra ID > Paramètres de diagnostic
# 2. Ajouter un paramètre de diagnostic
# 3. Sélectionner :
#    - AuditLogs
#    - SignInLogs
#    - NonInteractiveUserSignInLogs
#    - ServicePrincipalSignInLogs
# 4. Destination : Log Analytics workspace

Write-Host "Configuration des logs d'audit..." -ForegroundColor Cyan
Write-Host "✓ À configurer via le portail Azure" -ForegroundColor Yellow
Write-Host "  Entra ID > Paramètres de diagnostic" -ForegroundColor White
```

### 3. Configurer la période de rétention des logs

```powershell
# Configuration via le portail Azure
# Entra ID > Logs d'audit > Paramètres d'exportation

# Périodes recommandées :
# - Logs d'audit : 90 jours minimum
# - Logs de connexion : 30 jours minimum
# - Logs de sécurité : 180 jours minimum

Write-Host "Périodes de rétention recommandées :" -ForegroundColor Cyan
Write-Host "  - Logs d'audit : 90 jours" -ForegroundColor White
Write-Host "  - Logs de connexion : 30 jours" -ForegroundColor White
Write-Host "  - Logs de sécurité : 180 jours" -ForegroundColor White
```

---

## 🏗️ Créer la structure organisationnelle initiale

### Script complet de configuration du tenant

```powershell
<#
.SYNOPSIS
    Configuration complète du tenant USS Enterprise
.DESCRIPTION
    Ce script configure tous les aspects initiaux du tenant
#>

function Initialize-USSEnterpriseTenant {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$TenantName = "USS Enterprise",
        
        [Parameter(Mandatory=$false)]
        [string]$TenantDomain = "uss-enterprise.onmicrosoft.com"
    )
    
    Write-Host "`n=== CONFIGURATION DU TENANT USS ENTERPRISE ===" -ForegroundColor Cyan
    Write-Host "Tenant : $TenantName" -ForegroundColor White
    Write-Host "Domaine : $TenantDomain`n" -ForegroundColor White
    
    # 1. Connexion
    Write-Host "[Étape 1/7] Connexion au tenant..." -ForegroundColor Yellow
    Connect-MgGraph -Scopes @(
        "Organization.ReadWrite.All",
        "User.ReadWrite.All",
        "Group.ReadWrite.All",
        "Directory.ReadWrite.All",
        "RoleManagement.ReadWrite.Directory"
    )
    
    $org = Get-MgOrganization
    Write-Host "✓ Connecté : $($org.DisplayName)" -ForegroundColor Green
    
    # 2. Configuration de base
    Write-Host "`n[Étape 2/7] Configuration des informations du tenant..." -ForegroundColor Yellow
    Update-MgOrganization -OrganizationId $org.Id `
        -DisplayName $TenantName `
        -TechnicalNotificationMails @("admin@$TenantDomain")
    Write-Host "✓ Informations mises à jour" -ForegroundColor Green
    
    # 3. Compte d'urgence
    Write-Host "`n[Étape 3/7] Création du compte d'urgence..." -ForegroundColor Yellow
    $emergencyAccount = New-EmergencyAccount
    
    # 4. Structure de groupes
    Write-Host "`n[Étape 4/7] Création de la structure de groupes..." -ForegroundColor Yellow
    
    $groups = @(
        @{Name="Tier 0 - Global Administrators"; Desc="Administrateurs globaux du tenant"},
        @{Name="Tier 0 - Security Administrators"; Desc="Administrateurs de sécurité"},
        @{Name="Tier 1 - Command Team"; Desc="Équipe de commandement"},
        @{Name="Tier 1 - Engineering Team"; Desc="Équipe d'ingénierie"},
        @{Name="Tier 1 - Medical Team"; Desc="Équipe médicale"},
        @{Name="Tier 1 - Science Team"; Desc="Équipe scientifique"},
        @{Name="Tier 2 - Senior Officers"; Desc="Officiers supérieurs"},
        @{Name="Tier 2 - Technical Support"; Desc="Support technique"}
    )
    
    $createdGroups = @{}
    foreach ($groupDef in $groups) {
        $mailNickname = ($groupDef.Name -replace '[^a-zA-Z0-9]', '').ToLower()
        
        $group = New-MgGroup `
            -DisplayName $groupDef.Name `
            -Description $groupDef.Desc `
            -MailEnabled:$false `
            -SecurityEnabled:$true `
            -MailNickname $mailNickname
        
        $createdGroups[$groupDef.Name] = $group
        Write-Host "  ✓ $($groupDef.Name)" -ForegroundColor Green
        Start-Sleep -Milliseconds 500
    }
    
    # 5. Utilisateurs de test
    Write-Host "`n[Étape 5/7] Création des utilisateurs principaux..." -ForegroundColor Yellow
    
    $users = @(
        @{First="James"; Last="Kirk"; Rank="Captain"; Dept="Command"},
        @{First="Spock"; Last=""; Rank="Commander"; Dept="Science"},
        @{First="Leonard"; Last="McCoy"; Rank="Doctor"; Dept="Medical"},
        @{First="Montgomery"; Last="Scott"; Rank="Commander"; Dept="Engineering"}
    )
    
    foreach ($userData in $users) {
        $firstName = $userData.First
        $lastName = $userData.Last
        $displayName = if ($lastName) { "$($userData.Rank) $firstName $lastName" } else { "$($userData.Rank) $firstName" }
        $mailNickname = if ($lastName) { "$($firstName.ToLower()).$($lastName.ToLower())" } else { $firstName.ToLower() }
        $upn = "$mailNickname@$TenantDomain"
        
        $password = "Starfleet$(Get-Random -Minimum 1000 -Maximum 9999)!"
        
        $user = New-MgUser `
            -DisplayName $displayName `
            -UserPrincipalName $upn `
            -MailNickname $mailNickname `
            -AccountEnabled:$true `
            -PasswordProfile @{ Password = $password; ForceChangePasswordNextSignIn = $true } `
            -Department $userData.Dept `
            -JobTitle $userData.Rank `
            -UsageLocation "FR"
        
        Write-Host "  ✓ $displayName ($upn)" -ForegroundColor Green
        Start-Sleep -Milliseconds 500
    }
    
    # 6. Configuration de la sécurité
    Write-Host "`n[Étape 6/7] Configuration de la sécurité..." -ForegroundColor Yellow
    Write-Host "  ⚠️  À faire manuellement dans le portail Azure :" -ForegroundColor Yellow
    Write-Host "    - Activer les paramètres de sécurité par défaut" -ForegroundColor White
    Write-Host "    - Configurer les logs d'audit" -ForegroundColor White
    Write-Host "    - Activer Azure AD Premium P2 (essai)" -ForegroundColor White
    
    # 7. Sauvegarde de la configuration
    Write-Host "`n[Étape 7/7] Sauvegarde de la configuration..." -ForegroundColor Yellow
    
    $configPath = "./config"
    if (-not (Test-Path $configPath)) {
        New-Item -ItemType Directory -Path $configPath -Force | Out-Null
    }
    
    $tenantConfig = @{
        TenantName = $TenantName
        TenantDomain = $TenantDomain
        TenantId = $org.Id
        ConfigurationDate = Get-Date
        EmergencyAccount = $emergencyAccount.UserPrincipalName
        Groups = $createdGroups.Keys
    }
    
    $tenantConfig | ConvertTo-Json -Depth 10 | Out-File "$configPath/tenant-config.json" -Encoding UTF8
    
    Write-Host "✓ Configuration sauvegardée" -ForegroundColor Green
    
    # Résumé
    Write-Host "`n=== CONFIGURATION TERMINÉE ===" -ForegroundColor Green
    Write-Host "`nTenant configuré avec succès !" -ForegroundColor Green
    Write-Host "  - Nom : $TenantName" -ForegroundColor Cyan
    Write-Host "  - ID : $($org.Id)" -ForegroundColor Cyan
    Write-Host "  - Groupes créés : $($createdGroups.Count)" -ForegroundColor Cyan
    Write-Host "  - Utilisateurs créés : $($users.Count)" -ForegroundColor Cyan
    
    Write-Host "`n⚠️  ACTIONS IMPORTANTES :" -ForegroundColor Red
    Write-Host "1. Sauvegarder les informations du compte d'urgence" -ForegroundColor Yellow
    Write-Host "2. Configurer les paramètres de sécurité dans le portail" -ForegroundColor Yellow
    Write-Host "3. Activer Azure AD Premium P2" -ForegroundColor Yellow
    Write-Host "4. Configurer les politiques d'accès conditionnel" -ForegroundColor Yellow
    
    return $tenantConfig
}

# Exécuter la configuration
$config = Initialize-USSEnterpriseTenant
```

---

## 🎯 Résumé des commandes essentielles

| Action | Commande |
|--------|----------|
| **Obtenir info tenant** | `Get-MgOrganization` |
| **Mettre à jour tenant** | `Update-MgOrganization -OrganizationId "id"` |
| **Ajouter domaine** | `New-MgDomain -Id "domain.com"` |
| **Vérifier domaine** | `Confirm-MgDomain -DomainId "domain.com"` |
| **Lister licences** | `Get-MgSubscribedSku` |
| **Assigner licence** | `Set-MgUserLicense -UserId "id" -AddLicenses @{SkuId="sku"}` |

---

## ⚠️ Checklist de configuration du tenant

- [ ] Tenant créé (Azure for Students ou M365 Dev)
- [ ] Connexion PowerShell testée
- [ ] Informations du tenant configurées
- [ ] Paramètres de sécurité par défaut activés
- [ ] Compte d'urgence créé et sécurisé
- [ ] Compte d'urgence exclu des politiques MFA
- [ ] Logs d'audit configurés
- [ ] Azure AD Premium P2 activé (essai)
- [ ] Structure de groupes créée
- [ ] Utilisateurs principaux créés
- [ ] Configuration sauvegardée

---

## 📚 Ressources complémentaires

- [Azure for Students](https://azure.microsoft.com/fr-fr/free/students/)
- [M365 Developer Program](https://developer.microsoft.com/en-us/microsoft-365/dev-program)
- [Configuration tenant](https://learn.microsoft.com/en-us/azure/active-directory/fundamentals/)
- [Sécurité par défaut](https://learn.microsoft.com/en-us/azure/active-directory/fundamentals/concept-fundamentals-security-defaults)

---

**Date de création** : Novembre 2024  
**Version** : 1.0  
**Projet** : USS Enterprise - Entra ID Security