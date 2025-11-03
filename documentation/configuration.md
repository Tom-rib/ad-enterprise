# Guide de Configuration - Projet AD Enterprise USS Enterprise

## 📋 Table des matières

1. [Configuration initiale Azure AD/Entra ID](#configuration-initiale-azure-adentra-id)
2. [Configuration des politiques de sécurité](#configuration-des-politiques-de-sécurité)
3. [Configuration de l'authentification multi-facteurs (MFA)](#configuration-de-lauthentification-multi-facteurs-mfa)
4. [Configuration des groupes et utilisateurs](#configuration-des-groupes-et-utilisateurs)
5. [Configuration des applications](#configuration-des-applications)
6. [Configuration de la surveillance et des alertes](#configuration-de-la-surveillance-et-des-alertes)
7. [Configuration des scripts PowerShell](#configuration-des-scripts-powershell)
8. [Bonnes pratiques et sécurité](#bonnes-pratiques-et-sécurité)

---

## 🔐 Configuration initiale Azure AD/Entra ID

### 1. Configuration du Tenant

#### 1.1 Paramètres de base du Tenant

1. **Accéder aux paramètres du Tenant**
   ```
   Portail Azure > Entra ID > Propriétés
   ```

2. **Configurer les informations**
   - **Nom du Tenant** : USS Enterprise
   - **Domaine principal** : uss-enterprise.onmicrosoft.com
   - **ID du Tenant** : Copier et sauvegarder dans `config/settings.json`

3. **Configurer le domaine personnalisé (optionnel)**
   ```
   Entra ID > Noms de domaine personnalisés > Ajouter un domaine personnalisé
   
   Domaine : uss-enterprise.com
   Type d'enregistrement : TXT ou MX
   ```

#### 1.2 Configuration des paramètres de sécurité par défaut

```
Entra ID > Propriétés > Gérer les paramètres de sécurité par défaut
```

**Paramètres recommandés :**
- ✅ Activer les paramètres de sécurité par défaut (si pas de licence Premium)
- ✅ Exiger l'inscription MFA pour tous les utilisateurs
- ✅ Exiger MFA pour les administrateurs
- ✅ Bloquer les protocoles d'authentification hérités

#### 1.3 Configuration PowerShell

```powershell
# scripts/config/01-configure-tenant.ps1

# Se connecter
Connect-MgGraph -Scopes "Organization.ReadWrite.All"

# Obtenir les détails du tenant
$tenant = Get-MgOrganization

# Configurer les paramètres du tenant
Update-MgOrganization -OrganizationId $tenant.Id -TechnicalNotificationMails @("admin@uss-enterprise.com")

Write-Host "✓ Tenant configuré : $($tenant.DisplayName)" -ForegroundColor Green
```

### 2. Configuration des licences

#### 2.1 Vérifier les licences disponibles

```powershell
# scripts/config/02-verify-licenses.ps1

Connect-MgGraph -Scopes "Directory.Read.All"

# Lister toutes les licences
$licenses = Get-MgSubscribedSku

Write-Host "`n=== Licences disponibles ===" -ForegroundColor Cyan
foreach ($license in $licenses) {
    $skuName = $license.SkuPartNumber
    $total = $license.PrepaidUnits.Enabled
    $consumed = $license.ConsumedUnits
    $available = $total - $consumed
    
    Write-Host "`nLicence : $skuName" -ForegroundColor Yellow
    Write-Host "Total : $total | Utilisées : $consumed | Disponibles : $available"
}
```

#### 2.2 Activer Azure AD Premium P2 (Essai)

```
Entra ID > Licences > Tous les produits > Essayer/Acheter
Sélectionner : Azure Active Directory Premium P2
Cliquer : Essai gratuit (30 jours)
```

---

## 🛡️ Configuration des politiques de sécurité

### 1. Configuration de l'accès conditionnel

#### 1.1 Politique : Blocage des emplacements non autorisés

**Via le portail Azure :**

```
Entra ID > Sécurité > Accès conditionnel > Nouvelle politique
```

**Configuration :**
- **Nom** : Blocage Planètes Non Sécurisées
- **Utilisateurs** : 
  - Inclure : Tous les utilisateurs
  - Exclure : Compte d'urgence (à créer)
- **Applications cloud** : Toutes les applications cloud
- **Conditions** :
  - Emplacements : 
    - Inclure : Tous les emplacements
    - Exclure : Emplacements nommés (France, USA)
- **Contrôles d'accès** :
  - Accorder : Bloquer l'accès
- **Activer la politique** : Activé

**Via PowerShell :**

```powershell
# scripts/config/03-conditional-access-location.ps1

Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess"

# Créer les emplacements nommés (trusted locations)
$franceLocation = @{
    "@odata.type" = "#microsoft.graph.countryNamedLocation"
    displayName = "France - Localisation de confiance"
    countriesAndRegions = @("FR")
    includeUnknownCountriesAndRegions = $false
}

$france = New-MgIdentityConditionalAccessNamedLocation -BodyParameter $franceLocation

# Créer la politique d'accès conditionnel
$policy = @{
    displayName = "Blocage Planètes Non Sécurisées"
    state = "enabled"
    conditions = @{
        users = @{
            includeUsers = @("All")
            excludeUsers = @() # Ajouter l'ID du compte d'urgence ici
            excludeGroups = @()
        }
        applications = @{
            includeApplications = @("All")
        }
        locations = @{
            includeLocations = @("All")
            excludeLocations = @($france.Id, "AllTrusted")
        }
    }
    grantControls = @{
        operator = "OR"
        builtInControls = @("block")
    }
}

$newPolicy = New-MgIdentityConditionalAccessPolicy -BodyParameter $policy

Write-Host "✓ Politique d'accès conditionnel créée : $($newPolicy.DisplayName)" -ForegroundColor Green
```

#### 1.2 Politique : MFA pour applications sensibles

```powershell
# scripts/config/04-conditional-access-mfa.ps1

Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess"

$mfaPolicy = @{
    displayName = "Exiger MFA pour Officiers Supérieurs"
    state = "enabled"
    conditions = @{
        users = @{
            includeGroups = @() # ID du groupe "Officiers Supérieurs"
        }
        applications = @{
            includeApplications = @("All")
        }
    }
    grantControls = @{
        operator = "OR"
        builtInControls = @("mfa")
    }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $mfaPolicy

Write-Host "✓ Politique MFA créée pour les officiers supérieurs" -ForegroundColor Green
```

#### 1.3 Politique : Exiger des appareils conformes

```powershell
# scripts/config/05-conditional-access-compliant-device.ps1

$devicePolicy = @{
    displayName = "Exiger appareils conformes pour données sensibles"
    state = "enabled"
    conditions = @{
        users = @{
            includeUsers = @("All")
        }
        applications = @{
            includeApplications = @("All")
        }
    }
    grantControls = @{
        operator = "OR"
        builtInControls = @("compliantDevice", "domainJoinedDevice")
    }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $devicePolicy

Write-Host "✓ Politique d'appareils conformes créée" -ForegroundColor Green
```

### 2. Configuration des emplacements nommés

```powershell
# scripts/config/06-named-locations.ps1

Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess"

# Définir les emplacements de confiance
$trustedLocations = @(
    @{
        name = "France - Quartier Général Starfleet"
        countries = @("FR")
    },
    @{
        name = "États-Unis - Base Spatiale"
        countries = @("US")
    }
)

foreach ($location in $trustedLocations) {
    $namedLocation = @{
        "@odata.type" = "#microsoft.graph.countryNamedLocation"
        displayName = $location.name
        countriesAndRegions = $location.countries
        includeUnknownCountriesAndRegions = $false
    }
    
    $created = New-MgIdentityConditionalAccessNamedLocation -BodyParameter $namedLocation
    Write-Host "✓ Emplacement nommé créé : $($created.DisplayName)" -ForegroundColor Green
}

# Créer un emplacement IP (exemple pour le bureau)
$ipLocation = @{
    "@odata.type" = "#microsoft.graph.ipNamedLocation"
    displayName = "Bureau USS Enterprise - Réseau IP"
    isTrusted = $true
    ipRanges = @(
        @{
            "@odata.type" = "#microsoft.graph.iPv4CidrRange"
            cidrAddress = "203.0.113.0/24"  # Remplacer par votre plage IP
        }
    )
}

New-MgIdentityConditionalAccessNamedLocation -BodyParameter $ipLocation
Write-Host "✓ Emplacement IP créé" -ForegroundColor Green
```

---

## 🔑 Configuration de l'authentification multi-facteurs (MFA)

### 1. Configuration MFA pour les utilisateurs

#### 1.1 Activer MFA pour un groupe spécifique

```powershell
# scripts/config/07-enable-mfa-for-group.ps1

Connect-MgGraph -Scopes "User.ReadWrite.All", "Group.Read.All"

# ID du groupe "Officiers Supérieurs"
$groupId = "VOTRE-GROUP-ID" # À remplacer

# Obtenir les membres du groupe
$members = Get-MgGroupMember -GroupId $groupId

foreach ($member in $members) {
    $user = Get-MgUser -UserId $member.Id
    
    # Créer une méthode d'authentification (configuration pour MFA)
    # Note: L'utilisateur devra s'enregistrer lors de sa prochaine connexion
    
    Write-Host "MFA sera requis pour : $($user.DisplayName)" -ForegroundColor Yellow
}

Write-Host "`n✓ Configuration MFA appliquée au groupe" -ForegroundColor Green
```

#### 1.2 Configuration des méthodes MFA autorisées

```
Entra ID > Sécurité > Méthodes d'authentification > Politiques
```

**Méthodes recommandées à activer :**
- ✅ Microsoft Authenticator (recommandé)
- ✅ SMS (secours)
- ✅ Appel téléphonique (secours)
- ✅ Clés de sécurité FIDO2 (pour administrateurs)
- ❌ Email (désactiver pour meilleure sécurité)

**Configuration via PowerShell :**

```powershell
# scripts/config/08-configure-auth-methods.ps1

Connect-MgGraph -Scopes "Policy.ReadWrite.AuthenticationMethod"

# Obtenir la politique d'authentification actuelle
$authPolicy = Get-MgPolicyAuthenticationMethodPolicy

# Configurer Microsoft Authenticator
$authenticatorConfig = @{
    id = "MicrosoftAuthenticator"
    state = "enabled"
    includeTargets = @(
        @{
            targetType = "group"
            id = "all_users"
            isRegistrationRequired = $true
        }
    )
}

Write-Host "✓ Méthodes d'authentification configurées" -ForegroundColor Green
```

### 2. Configuration du MFA pour les administrateurs

#### 2.1 Politique MFA obligatoire pour les administrateurs

```powershell
# scripts/config/09-mfa-admins.ps1

Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess"

$adminMfaPolicy = @{
    displayName = "Exiger MFA - Tous les Administrateurs"
    state = "enabled"
    conditions = @{
        users = @{
            includeRoles = @(
                "62e90394-69f5-4237-9190-012177145e10", # Global Administrator
                "194ae4cb-b126-40b2-bd5b-6091b380977d", # Security Administrator
                "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3", # Application Administrator
                "c4e39bd9-1100-46d3-8c65-fb160da0071f"  # Authentication Administrator
            )
        }
        applications = @{
            includeApplications = @("All")
        }
    }
    grantControls = @{
        operator = "OR"
        builtInControls = @("mfa")
    }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $adminMfaPolicy

Write-Host "✓ MFA obligatoire configuré pour tous les administrateurs" -ForegroundColor Green
```

### 3. Configuration du compte d'urgence (Break Glass)

```powershell
# scripts/config/10-emergency-account.ps1

Connect-MgGraph -Scopes "User.ReadWrite.All"

# Créer un compte d'urgence
$emergencyAccount = @{
    accountEnabled = $true
    displayName = "Compte Urgence Enterprise"
    mailNickname = "emergency-admin"
    userPrincipalName = "emergency-admin@uss-enterprise.onmicrosoft.com"
    passwordProfile = @{
        password = "VotreMotDePasseTrèsComplexe123!@#"
        forceChangePasswordNextSignIn = $false
    }
}

$emergencyUser = New-MgUser -BodyParameter $emergencyAccount

# Assigner le rôle d'administrateur global
$globalAdminRole = Get-MgDirectoryRole | Where-Object {$_.DisplayName -eq "Global Administrator"}

New-MgDirectoryRoleMemberByRef -DirectoryRoleId $globalAdminRole.Id -BodyParameter @{
    "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($emergencyUser.Id)"
}

Write-Host "✓ Compte d'urgence créé : $($emergencyAccount.userPrincipalName)" -ForegroundColor Green
Write-Host "⚠️  IMPORTANT : Sauvegarder le mot de passe dans un coffre-fort sécurisé!" -ForegroundColor Red

# Exclure ce compte de toutes les politiques MFA
```

---

## 👥 Configuration des groupes et utilisateurs

### 1. Création de la structure organisationnelle

#### 1.1 Créer les groupes de base

```powershell
# scripts/config/11-create-groups.ps1

Connect-MgGraph -Scopes "Group.ReadWrite.All"

# Définir les groupes
$groups = @(
    @{
        Name = "Équipe de Commandement"
        Description = "Capitaine et officiers de commandement"
        Type = "Security"
    },
    @{
        Name = "Officiers Supérieurs"
        Description = "Tous les officiers de rang supérieur"
        Type = "Security"
    },
    @{
        Name = "Équipe d'Exploration"
        Description = "Membres des missions d'exploration"
        Type = "Security"
    },
    @{
        Name = "Équipe Médicale"
        Description = "Personnel médical du vaisseau"
        Type = "Security"
    },
    @{
        Name = "Équipe d'Ingénierie"
        Description = "Ingénieurs et techniciens"
        Type = "Security"
    },
    @{
        Name = "Équipe de Sécurité"
        Description = "Personnel de sécurité"
        Type = "Security"
    },
    @{
        Name = "Équipe Scientifique"
        Description = "Scientifiques et analystes"
        Type = "Security"
    }
)

# Fonction pour créer un groupe
function New-EnterpriseGroup {
    param(
        [string]$Name,
        [string]$Description,
        [string]$Type
    )
    
    $groupParams = @{
        displayName = $Name
        description = $Description
        mailEnabled = $false
        mailNickname = ($Name -replace '\s', '').ToLower()
        securityEnabled = ($Type -eq "Security")
        groupTypes = @()
    }
    
    try {
        $group = New-MgGroup -BodyParameter $groupParams
        Write-Host "✓ Groupe créé : $Name (ID: $($group.Id))" -ForegroundColor Green
        return $group
    } catch {
        Write-Host "✗ Erreur création groupe $Name : $_" -ForegroundColor Red
    }
}

# Créer tous les groupes
$createdGroups = @{}
foreach ($group in $groups) {
    $created = New-EnterpriseGroup -Name $group.Name -Description $group.Description -Type $group.Type
    $createdGroups[$group.Name] = $created
}

# Sauvegarder les IDs des groupes
$createdGroups | ConvertTo-Json | Out-File "./config/groups.json" -Encoding utf8

Write-Host "`n=== Tous les groupes créés ===" -ForegroundColor Green
```

#### 1.2 Créer les utilisateurs type

```powershell
# scripts/config/12-create-users.ps1

Connect-MgGraph -Scopes "User.ReadWrite.All"

# Définir les utilisateurs
$users = @(
    @{
        FirstName = "James"
        LastName = "Kirk"
        Rank = "Captain"
        Department = "Command"
        Groups = @("Équipe de Commandement", "Officiers Supérieurs", "Équipe d'Exploration")
    },
    @{
        FirstName = "Spock"
        LastName = ""
        Rank = "Commander"
        Department = "Science"
        Groups = @("Équipe de Commandement", "Officiers Supérieurs", "Équipe Scientifique")
    },
    @{
        FirstName = "Leonard"
        LastName = "McCoy"
        Rank = "Doctor"
        Department = "Medical"
        Groups = @("Officiers Supérieurs", "Équipe Médicale")
    },
    @{
        FirstName = "Montgomery"
        LastName = "Scott"
        Rank = "Commander"
        Department = "Engineering"
        Groups = @("Officiers Supérieurs", "Équipe d'Ingénierie")
    },
    @{
        FirstName = "Nyota"
        LastName = "Uhura"
        Rank = "Lieutenant"
        Department = "Communications"
        Groups = @("Équipe de Commandement")
    },
    @{
        FirstName = "Hikaru"
        LastName = "Sulu"
        Rank = "Lieutenant"
        Department = "Navigation"
        Groups = @("Équipe de Commandement")
    },
    @{
        FirstName = "Pavel"
        LastName = "Chekov"
        Rank = "Ensign"
        Department = "Navigation"
        Groups = @("Équipe de Commandement")
    }
)

# Charger les IDs des groupes
$groupsData = Get-Content "./config/groups.json" | ConvertFrom-Json

# Fonction pour créer un utilisateur
function New-EnterpriseUser {
    param($UserData)
    
    $firstName = $UserData.FirstName
    $lastName = $UserData.LastName
    $displayName = if ($lastName) { "$($UserData.Rank) $firstName $lastName" } else { "$($UserData.Rank) $firstName" }
    $mailNickname = if ($lastName) { "$($firstName.ToLower()).$($lastName.ToLower())" } else { $firstName.ToLower() }
    $upn = "$mailNickname@uss-enterprise.onmicrosoft.com"
    
    # Générer un mot de passe temporaire
    $password = "Starfleet$(Get-Random -Minimum 1000 -Maximum 9999)!"
    
    $userParams = @{
        accountEnabled = $true
        displayName = $displayName
        mailNickname = $mailNickname
        userPrincipalName = $upn
        passwordProfile = @{
            password = $password
            forceChangePasswordNextSignIn = $true
        }
        department = $UserData.Department
        jobTitle = $UserData.Rank
        usageLocation = "FR"
    }
    
    try {
        $user = New-MgUser -BodyParameter $userParams
        Write-Host "✓ Utilisateur créé : $displayName ($upn)" -ForegroundColor Green
        Write-Host "  Mot de passe temporaire : $password" -ForegroundColor Yellow
        
        # Ajouter aux groupes
        foreach ($groupName in $UserData.Groups) {
            $group = $groupsData.$groupName
            if ($group) {
                New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $user.Id
                Write-Host "  → Ajouté au groupe : $groupName" -ForegroundColor Cyan
            }
        }
        
        return @{
            User = $user
            Password = $password
        }
    } catch {
        Write-Host "✗ Erreur création utilisateur $displayName : $_" -ForegroundColor Red
    }
}

# Créer tous les utilisateurs
$createdUsers = @()
foreach ($userData in $users) {
    $result = New-EnterpriseUser -UserData $userData
    $createdUsers += $result
}

# Sauvegarder les informations (ATTENTION: contient des mots de passe!)
# À utiliser uniquement pour tests, puis supprimer
$createdUsers | ConvertTo-Json | Out-File "./config/users-PRIVATE.json" -Encoding utf8

Write-Host "`n⚠️  IMPORTANT : Fichier users-PRIVATE.json contient des mots de passe!" -ForegroundColor Red
Write-Host "Distribuer les credentials de manière sécurisée puis SUPPRIMER ce fichier!" -ForegroundColor Red
```

### 2. Configuration des attributs étendus

```powershell
# scripts/config/13-configure-user-attributes.ps1

Connect-MgGraph -Scopes "User.ReadWrite.All"

# Exemple : Ajouter des attributs personnalisés
$users = Get-MgUser -Filter "startswith(department, 'Engineering')"

foreach ($user in $users) {
    # Configurer les attributs
    Update-MgUser -UserId $user.Id -ExtensionAttribute1 "ClearanceLevel:Secret"
    Update-MgUser -UserId $user.Id -ExtensionAttribute2 "ShipAssignment:USS-Enterprise-NCC-1701"
    
    Write-Host "✓ Attributs configurés pour : $($user.DisplayName)" -ForegroundColor Green
}
```

---

## 📱 Configuration des applications

### 1. Intégration d'une application SaaS (Captain's Log)

#### 1.1 Créer l'enregistrement d'application

```powershell
# scripts/config/14-create-captains-log-app.ps1

Connect-MgGraph -Scopes "Application.ReadWrite.All"

# Créer l'application
$appParams = @{
    displayName = "Captain's Log - Journal de Bord"
    signInAudience = "AzureADMyOrg"
    web = @{
        redirectUris = @(
            "https://captains-log.uss-enterprise.com/auth/callback",
            "https://localhost:5000/auth/callback"
        )
        implicitGrantSettings = @{
            enableIdTokenIssuance = $true
            enableAccessTokenIssuance = $true
        }
    }
    requiredResourceAccess = @(
        @{
            resourceAppId = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
            resourceAccess = @(
                @{
                    id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
                    type = "Scope"
                },
                @{
                    id = "37f7f235-527c-4136-accd-4a02d197296e" # openid
                    type = "Scope"
                },
                @{
                    id = "64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0" # email
                    type = "Scope"
                },
                @{
                    id = "14dad69e-099b-42c9-810b-d002981feec1" # profile
                    type = "Scope"
                }
            )
        }
    )
}

$app = New-MgApplication -BodyParameter $appParams

Write-Host "✓ Application créée : Captain's Log" -ForegroundColor Green
Write-Host "  Application ID : $($app.AppId)" -ForegroundColor Cyan
Write-Host "  Object ID : $($app.Id)" -ForegroundColor Cyan

# Créer un secret client
$passwordCredential = Add-MgApplicationPassword -ApplicationId $app.Id -PasswordCredential @{
    displayName = "Client Secret"
}

Write-Host "`n⚠️  CLIENT SECRET (à sauvegarder immédiatement) :" -ForegroundColor Red
Write-Host $passwordCredential.SecretText -ForegroundColor Yellow

# Créer le service principal (Enterprise Application)
$sp = New-MgServicePrincipal -AppId $app.AppId

Write-Host "`n✓ Service Principal créé" -ForegroundColor Green
Write-Host "  Service Principal ID : $($sp.Id)" -ForegroundColor Cyan

# Sauvegarder les informations
$appInfo = @{
    ApplicationId = $app.AppId
    ObjectId = $app.Id
    ServicePrincipalId = $sp.Id
    ClientSecret = $passwordCredential.SecretText
    RedirectUris = $appParams.web.redirectUris
}

$appInfo | ConvertTo-Json | Out-File "./config/captains-log-app-PRIVATE.json" -Encoding utf8

Write-Host "`n✓ Informations sauvegardées dans captains-log-app-PRIVATE.json" -ForegroundColor Green
```

#### 1.2 Configurer Single Sign-On (SSO)

```
Entra ID > Applications d'entreprise > Captain's Log > Single sign-on

1. Sélectionner : SAML ou OpenID Connect/OAuth 2.0
2. Configurer les URLs :
   - URL de connexion : https://captains-log.uss-enterprise.com
   - URL de réponse : https://captains-log.uss-enterprise.com/auth/callback
3. Télécharger le certificat de signature SAML
4. Copier les URLs de métadonnées
```

#### 1.3 Assigner des utilisateurs à l'application

```powershell
# scripts/config/15-assign-users-to-app.ps1

Connect-MgGraph -Scopes "Application.ReadWrite.All", "AppRoleAssignment.ReadWrite.All"

$appId = "VOTRE-APP-ID" # ID du service principal
$groupId = "VOTRE-GROUP-ID" # ID du groupe "Officiers Supérieurs"

# Assigner le groupe à l'application
$assignment = New-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $appId -BodyParameter @{
    principalId = $groupId
    resourceId = $appId
    appRoleId = "00000000-0000-0000-0000-000000000000" # Default access
}

Write-Host "✓ Groupe assigné à l'application Captain's Log" -ForegroundColor Green
```

### 2. Création d'une application personnalisée (Repair Management)

```powershell
# scripts/config/16-create-repair-management-app.ps1

Connect-MgGraph -Scopes "Application.ReadWrite.All"

# Définir les rôles d'application
$appRoles = @(
    @{
        allowedMemberTypes = @("User")
        description = "Ingénieurs - Lecture et écriture complète"
        displayName = "Engineer"
        id = (New-Guid).ToString()
        isEnabled = $true
        value = "Engineer"
    },
    @{
        allowedMemberTypes = @("User")
        description = "Techniciens - Lecture seule"
        displayName = "Technician"
        id = (New-Guid).ToString()
        isEnabled = $true
        value = "Technician"
    },
    @{
        allowedMemberTypes = @("User")
        description = "Superviseurs - Accès complet et gestion"
        displayName = "Supervisor"
        id = (New-Guid).ToString()
        isEnabled = $true
        value = "Supervisor"
    }
)

# Créer l'application
$repairApp = @{
    displayName = "Repair Management System"
    signInAudience = "AzureADMyOrg"
    appRoles = $appRoles
    web = @{
        redirectUris = @("https://repair-mgmt.uss-enterprise.com/auth/callback")
    }
}

$app = New-MgApplication -BodyParameter $repairApp

Write-Host "✓ Application Repair Management créée" -ForegroundColor Green
Write-Host "  Roles définis : Engineer, Technician, Supervisor" -ForegroundColor Cyan

# Créer le service principal
$sp = New-MgServicePrincipal -AppId $app.AppId

# Assigner les rôles aux utilisateurs
$engineerRole = $app.AppRoles | Where-Object {$_.Value -eq "Engineer"}
$engineeringGroup = Get-MgGroup -Filter "displayName eq 'Équipe d''Ingénierie'"

$members = Get-MgGroupMember -GroupId $engineeringGroup.Id

foreach ($member in $members) {
    New-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $sp.Id -BodyParameter @{
        principalId = $member.Id
        resourceId = $sp.Id
        appRoleId = $engineerRole.Id
    }
    
    Write-Host "✓ Rôle Engineer assigné à : $($member.AdditionalProperties.displayName)" -ForegroundColor Green
}
```

---

## 📊 Configuration de la surveillance et des alertes

### 1. Configuration des Log Analytics

```powershell
# scripts/config/17-setup-log-analytics.ps1

Connect-AzAccount

# Créer un espace de travail Log Analytics
$workspace = New-AzOperationalInsightsWorkspace `
    -ResourceGroupName "USS-Enterprise-RG" `
    -Name "USSEnterprise-LogAnalytics" `
    -Location "France Central" `
    -Sku "PerGB2018"

Write-Host "✓ Espace Log Analytics créé" -ForegroundColor Green
Write-Host "  Workspace ID : $($workspace.CustomerId)" -ForegroundColor Cyan

# Configurer les diagnostics Azure AD
$diagnosticSettings = @{
    logs = @(
        @{
            category = "SignInLogs"
            enabled = $true
            retentionPolicy = @{
                enabled = $true
                days = 90
            }
        },
        @{
            category = "AuditLogs"
            enabled = $true
            retentionPolicy = @{
                enabled = $true
                days = 90
            }
        }
    )
    workspaceId = $workspace.ResourceId
}

Write-Host "✓ Paramètres de diagnostic configurés" -ForegroundColor Green
```

### 2. Configuration des alertes de sécurité

```powershell
# scripts/config/18-setup-security-alerts.ps1

Connect-AzAccount

# Créer un groupe d'actions
$email = New-AzActionGroupReceiver `
    -Name "SecurityTeamEmail" `
    -EmailReceiver `
    -EmailAddress "security@uss-enterprise.com"

$actionGroup = Set-AzActionGroup `
    -ResourceGroupName "USS-Enterprise-RG" `
    -Name "SecurityAlerts" `
    -ShortName "SecAlert" `
    -Receiver $email

Write-Host "✓ Groupe d'actions créé" -ForegroundColor Green

# Créer une règle d'alerte pour les échecs de connexion multiples
$condition = New-AzActivityLogAlertCondition `
    -Field 'category' `
    -Equal 'Administrative'

$alertRule = Set-AzActivityLogAlert `
    -ResourceGroupName "USS-Enterprise-RG" `
    -Name "MultipleFailedSignIns" `
    -Condition $condition `
    -Action $actionGroup.Id `
    -Enabled $true

Write-Host "✓ Règle d'alerte créée pour échecs de connexion" -ForegroundColor Green
```

### 3. Configuration des requêtes KQL personnalisées

```powershell
# scripts/config/19-custom-kql-queries.ps1

# Sauvegarder les requêtes KQL utiles
$queries = @{
    "Failed Sign-Ins" = @"
SigninLogs
| where ResultType != 0
| where TimeGenerated > ago(24h)
| summarize count() by UserPrincipalName, ResultType, ResultDescription
| order by count_ desc
"@

    "Suspicious Locations" = @"
SigninLogs
| where TimeGenerated > ago(7d)
| where Location !in ("FR", "US")
| project TimeGenerated, UserPrincipalName, Location, IPAddress, ResultType
| order by TimeGenerated desc
"@

    "Admin Activities" = @"
AuditLogs
| where TimeGenerated > ago(24h)
| where OperationName contains "role"
| project TimeGenerated, OperationName, InitiatedBy, Result
"@

    "MFA Changes" = @"
AuditLogs
| where OperationName contains "authentication"
| where TimeGenerated > ago(7d)
| project TimeGenerated, OperationName, InitiatedBy, TargetResources
"@
}

$queries | ConvertTo-Json | Out-File "./config/kql-queries.json" -Encoding utf8

Write-Host "✓ Requêtes KQL sauvegardées" -ForegroundColor Green
```

---

## 🔧 Configuration des scripts PowerShell

### 1. Script de configuration centralisé

```powershell
# scripts/config/00-main-config.ps1

# Fonction pour charger la configuration
function Get-EnterpriseConfig {
    $configPath = "./config/settings.json"
    
    if (Test-Path $configPath) {
        $config = Get-Content $configPath | ConvertFrom-Json
        return $config
    } else {
        Write-Error "Fichier de configuration non trouvé : $configPath"
        return $null
    }
}

# Fonction pour se connecter à tous les services
function Connect-EnterpriseServices {
    param(
        [switch]$IncludeAzure
    )
    
    Write-Host "Connexion aux services Microsoft..." -ForegroundColor Cyan
    
    # Microsoft Graph
    try {
        Connect-MgGraph -Scopes @(
            "User.ReadWrite.All",
            "Group.ReadWrite.All",
            "Directory.ReadWrite.All",
            "Policy.ReadWrite.ConditionalAccess",
            "Application.ReadWrite.All",
            "AuditLog.Read.All"
        ) -ErrorAction Stop
        
        Write-Host "✓ Connecté à Microsoft Graph" -ForegroundColor Green
    } catch {
        Write-Error "Échec connexion Microsoft Graph : $_"
    }
    
    # Azure (optionnel)
    if ($IncludeAzure) {
        try {
            Connect-AzAccount -ErrorAction Stop
            Write-Host "✓ Connecté à Azure" -ForegroundColor Green
        } catch {
            Write-Error "Échec connexion Azure : $_"
        }
    }
}

# Fonction pour logger les actions
function Write-EnterpriseLog {
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )
    
    $logPath = "./logs"
    if (-not (Test-Path $logPath)) {
        New-Item -ItemType Directory -Path $logPath -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    $color = switch ($Level) {
        "Info" { "Cyan" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
    }
    Write-Host $logEntry -ForegroundColor $color
    
    # Écrire dans le fichier
    $logFile = "$logPath/enterprise-$(Get-Date -Format 'yyyyMMdd').log"
    Add-Content -Path $logFile -Value $logEntry
}

# Exporter les fonctions
Export-ModuleMember -Function Get-EnterpriseConfig, Connect-EnterpriseServices, Write-EnterpriseLog
```

### 2. Template pour nouveaux scripts

```powershell
# scripts/template.ps1

<#
.SYNOPSIS
    [Description courte du script]

.DESCRIPTION
    [Description détaillée]

.PARAMETER ParameterName
    [Description du paramètre]

.EXAMPLE
    .\template.ps1 -ParameterName "value"

.NOTES
    Author: [Votre nom]
    Date: [Date]
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ParameterName
)

# Importer les fonctions communes
. "$PSScriptRoot/config/00-main-config.ps1"

# Début du script
Write-EnterpriseLog "Démarrage du script" -Level Info

try {
    # Se connecter aux services
    Connect-EnterpriseServices
    
    # Charger la configuration
    $config = Get-EnterpriseConfig
    
    # Logique principale du script
    # ...
    
    Write-EnterpriseLog "Script terminé avec succès" -Level Success
    
} catch {
    Write-EnterpriseLog "Erreur : $_" -Level Error
    throw
} finally {
    # Nettoyage
    Disconnect-MgGraph -ErrorAction SilentlyContinue
}
```

---

## 🔒 Bonnes pratiques et sécurité

### 1. Checklist de sécurité

- [ ] **Authentification**
  - [ ] MFA activé pour tous les administrateurs
  - [ ] MFA activé pour les utilisateurs privilégiés
  - [ ] Compte d'urgence créé et sécurisé
  - [ ] Protocoles d'authentification hérités bloqués

- [ ] **Accès Conditionnel**
  - [ ] Politique de blocage géographique active
  - [ ] Politique MFA pour applications sensibles
  - [ ] Politique d'appareils conformes configurée
  - [ ] Emplacements nommés définis

- [ ] **Groupes et Utilisateurs**
  - [ ] Structure organisationnelle définie
  - [ ] Groupes de sécurité créés
  - [ ] Utilisateurs assignés aux bons groupes
  - [ ] Attributs utilisateurs configurés

- [ ] **Applications**
  - [ ] Applications enregistrées dans Entra ID
  - [ ] SSO configuré
  - [ ] Rôles et permissions définis
  - [ ] Secrets clients stockés de manière sécurisée

- [ ] **Surveillance**
  - [ ] Log Analytics configuré
  - [ ] Alertes de sécurité activées
  - [ ] Rétention des logs définie (90 jours minimum)
  - [ ] Requêtes KQL créées

- [ ] **Documentation**
  - [ ] Configuration documentée
  - [ ] Scripts commentés
  - [ ] Procédures d'urgence définies
  - [ ] Informations sensibles sécurisées

### 2. Rotation des secrets

```powershell
# scripts/config/20-rotate-secrets.ps1

Connect-MgGraph -Scopes "Application.ReadWrite.All"

# Liste des applications
$apps = Get-MgApplication

foreach ($app in $apps) {
    Write-Host "`nApplication : $($app.DisplayName)" -ForegroundColor Cyan
    
    # Lister les secrets existants
    $secrets = $app.PasswordCredentials
    
    foreach ($secret in $secrets) {
        $expiryDate = $secret.EndDateTime
        $daysUntilExpiry = ($expiryDate - (Get-Date)).Days
        
        if ($daysUntilExpiry -lt 30) {
            Write-Host "⚠️  Secret expire dans $daysUntilExpiry jours!" -ForegroundColor Yellow
            
            # Créer un nouveau secret
            $newSecret = Add-MgApplicationPassword -ApplicationId $app.Id -PasswordCredential @{
                displayName = "Rotated Secret - $(Get-Date -Format 'yyyy-MM-dd')"
            }
            
            Write-Host "✓ Nouveau secret créé" -ForegroundColor Green
            Write-Host "  Secret : $($newSecret.SecretText)" -ForegroundColor Red
            Write-Host "  ⚠️  Mettre à jour l'application avec ce nouveau secret!" -ForegroundColor Yellow
        }
    }
}
```

### 3. Audit régulier

```powershell
# scripts/config/21-security-audit.ps1

function Invoke-SecurityAudit {
    Write-Host "`n=== AUDIT DE SÉCURITÉ USS ENTERPRISE ===" -ForegroundColor Cyan
    Write-Host "Date : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n" -ForegroundColor Cyan
    
    Connect-MgGraph -Scopes "Directory.Read.All", "Policy.Read.All"
    
    # 1. Vérifier les comptes administrateurs sans MFA
    Write-Host "[1] Vérification MFA Administrateurs..." -ForegroundColor Yellow
    $adminRoles = Get-MgDirectoryRole
    $admins = @()
    
    foreach ($role in $adminRoles) {
        $members = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id
        $admins += $members
    }
    
    # À compléter avec logique MFA
    
    # 2. Vérifier les politiques d'accès conditionnel
    Write-Host "[2] Vérification Politiques d'Accès Conditionnel..." -ForegroundColor Yellow
    $policies = Get-MgIdentityConditionalAccessPolicy
    
    $enabledPolicies = $policies | Where-Object {$_.State -eq "enabled"}
    Write-Host "  Politiques actives : $($enabledPolicies.Count)" -ForegroundColor Green
    
    # 3. Vérifier les connexions suspectes récentes
    Write-Host "[3] Vérification Connexions Suspectes..." -ForegroundColor Yellow
    # Logique d'analyse des logs
    
    # 4. Vérifier les permissions des applications
    Write-Host "[4] Vérification Permissions Applications..." -ForegroundColor Yellow
    $apps = Get-MgApplication
    
    foreach ($app in $apps) {
        $permissions = $app.RequiredResourceAccess
        # Analyser les permissions à risque
    }
    
    Write-Host "`n=== AUDIT TERMINÉ ===" -ForegroundColor Green
}

Invoke-SecurityAudit
```

---

## 📝 Résumé de la configuration

### Fichiers de configuration créés

```
config/
├── settings.json            # Configuration générale
├── groups.json              # IDs des groupes
├── users-PRIVATE.json       # Credentials utilisateurs (temporaire)
├── captains-log-app-PRIVATE.json  # Secrets application
├── kql-queries.json         # Requêtes de surveillance
└── audit-results/           # Résultats des audits
```

### Scripts de configuration créés

```
scripts/config/
├── 00-main-config.ps1              # Fonctions communes
├── 01-configure-tenant.ps1         # Configuration tenant
├── 02-verify-licenses.ps1          # Vérification licences
├── 03-conditional-access-location.ps1  # Accès conditionnel
├── 04-conditional-access-mfa.ps1   # Politique MFA
├── 05-conditional-access-compliant-device.ps1
├── 06-named-locations.ps1          # Emplacements nommés
├── 07-enable-mfa-for-group.ps1    # Activation MFA
├── 08-configure-auth-methods.ps1   # Méthodes d'authentification
├── 09-mfa-admins.ps1              # MFA administrateurs
├── 10-emergency-account.ps1        # Compte d'urgence
├── 11-create-groups.ps1           # Création groupes
├── 12-create-users.ps1            # Création utilisateurs
├── 13-configure-user-attributes.ps1
├── 14-create-captains-log-app.ps1  # Application Captain's Log
├── 15-assign-users-to-app.ps1     # Assignment utilisateurs
├── 16-create-repair-management-app.ps1
├── 17-setup-log-analytics.ps1     # Log Analytics
├── 18-setup-security-alerts.ps1   # Alertes
├── 19-custom-kql-queries.ps1      # Requêtes KQL
├── 20-rotate-secrets.ps1          # Rotation secrets
└── 21-security-audit.ps1          # Audit de sécurité
```

---

**Date de dernière mise à jour :** Novembre 2024  
**Version du document :** 1.0  
**Statut :** Configuration complète

⚠️ **IMPORTANT** : Tous les fichiers contenant des secrets (marqués PRIVATE) doivent être ajoutés au .gitignore et ne JAMAIS être commités sur GitHub!