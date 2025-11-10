# Guide 08 - Intégration et Sécurisation des Applications

## 📚 À quoi ça sert ?

L'**intégration d'applications** avec Entra ID permet de centraliser l'authentification et de sécuriser l'accès aux applications via **Single Sign-On (SSO)**. Les utilisateurs se connectent une seule fois avec leurs identifiants Starfleet pour accéder à toutes les applications.

### Pourquoi intégrer des applications ?
- **SSO** : Une seule connexion pour toutes les applications
- **Sécurité centralisée** : Contrôle des accès unifié
- **Audit** : Traçabilité complète des accès
- **Gestion simplifiée** : Attribution des permissions par groupes

---

## 🌐 PARTIE 1 : APPLICATIONS SAAS (Captain's Log)

### Créer et configurer l'application Captain's Log

```powershell
<#
.SYNOPSIS
    Intégrer l'application Captain's Log (Journal de Bord)
#>

# Se connecter avec les permissions nécessaires
Connect-MgGraph -Scopes "Application.ReadWrite.All", "AppRoleAssignment.ReadWrite.All"

# 1. Créer l'enregistrement d'application
$captainsLogApp = @{
    DisplayName = "Captain's Log - Journal de Bord"
    SignInAudience = "AzureADMyOrg"
    Web = @{
        RedirectUris = @(
            "https://captains-log.uss-enterprise.com/auth/callback",
            "https://captains-log.uss-enterprise.com/signin-oidc",
            "https://localhost:5001/signin-oidc"  # Pour tests locaux
        )
        ImplicitGrantSettings = @{
            EnableIdTokenIssuance = $true
            EnableAccessTokenIssuance = $false
        }
    }
    RequiredResourceAccess = @(
        @{
            ResourceAppId = "00000003-0000-0000-c000-000000000000"  # Microsoft Graph
            ResourceAccess = @(
                @{
                    Id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"  # User.Read
                    Type = "Scope"
                },
                @{
                    Id = "37f7f235-527c-4136-accd-4a02d197296e"  # openid
                    Type = "Scope"
                },
                @{
                    Id = "7427e0e9-2fba-42fe-b0c0-848c9e6a8182"  # offline_access
                    Type = "Scope"
                },
                @{
                    Id = "64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0"  # email
                    Type = "Scope"
                },
                @{
                    Id = "14dad69e-099b-42c9-810b-d002981feec1"  # profile
                    Type = "Scope"
                }
            )
        }
    )
}

$app = New-MgApplication -BodyParameter $captainsLogApp

Write-Host "✓ Application Captain's Log créée" -ForegroundColor Green
Write-Host "  Application ID : $($app.AppId)" -ForegroundColor Cyan
Write-Host "  Object ID : $($app.Id)" -ForegroundColor Cyan

# 2. Créer un secret client
$passwordCredential = @{
    DisplayName = "Client Secret - Production"
    EndDateTime = (Get-Date).AddYears(1)
}

$secret = Add-MgApplicationPassword -ApplicationId $app.Id -PasswordCredential $passwordCredential

Write-Host "`n⚠️  CLIENT SECRET (à sauvegarder immédiatement) :" -ForegroundColor Red
Write-Host "  $($secret.SecretText)" -ForegroundColor Yellow
Write-Host "  Expire le : $($secret.EndDateTime)" -ForegroundColor Gray

# 3. Créer le Service Principal (Enterprise Application)
$sp = New-MgServicePrincipal -AppId $app.AppId -DisplayName "Captain's Log"

Write-Host "`n✓ Service Principal créé" -ForegroundColor Green
Write-Host "  Service Principal ID : $($sp.Id)" -ForegroundColor Cyan

# 4. Configurer l'attribution utilisateur requise
Update-MgServicePrincipal -ServicePrincipalId $sp.Id -AppRoleAssignmentRequired:$true

Write-Host "✓ Attribution utilisateur requise activée" -ForegroundColor Green

# 5. Assigner des utilisateurs/groupes
$commandTeam = Get-MgGroup -Filter "displayName eq 'Command Team'"

# Assigner le groupe Command Team
$assignment = @{
    PrincipalId = $commandTeam.Id
    ResourceId = $sp.Id
    AppRoleId = "00000000-0000-0000-0000-000000000000"  # Default access
}

New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -BodyParameter $assignment

Write-Host "✓ Groupe 'Command Team' assigné à l'application" -ForegroundColor Green

# 6. Sauvegarder la configuration
$appConfig = @{
    ApplicationName = "Captain's Log"
    ApplicationId = $app.AppId
    TenantId = (Get-MgOrganization).Id
    ClientSecret = $secret.SecretText
    RedirectUris = $captainsLogApp.Web.RedirectUris
    ServicePrincipalId = $sp.Id
}

$appConfig | ConvertTo-Json -Depth 10 | Out-File "./config/captains-log-PRIVATE.json" -Encoding UTF8

Write-Host "`n✓ Configuration sauvegardée dans ./config/captains-log-PRIVATE.json" -ForegroundColor Green
Write-Host "⚠️  Ce fichier contient des secrets - Ne pas commiter sur GitHub!" -ForegroundColor Red
```

### Configuration SSO SAML (alternative)

```powershell
# Pour les applications qui utilisent SAML au lieu d'OAuth/OIDC

$samlApp = @{
    DisplayName = "Command Center - Centre de Commandement"
    SignInAudience = "AzureADMyOrg"
    Web = @{
        RedirectUris = @(
            "https://command-center.uss-enterprise.com/saml/acs"
        )
    }
    IdentifierUris = @(
        "https://command-center.uss-enterprise.com"
    )
}

$commandCenterApp = New-MgApplication -BodyParameter $samlApp
$commandCenterSP = New-MgServicePrincipal -AppId $commandCenterApp.AppId

Write-Host "✓ Application SAML 'Command Center' créée" -ForegroundColor Green
Write-Host "  Configurer le SSO SAML dans le portail Azure :" -ForegroundColor Yellow
Write-Host "  1. Entra ID > Applications d'entreprise > Command Center" -ForegroundColor White
Write-Host "  2. Single sign-on > SAML" -ForegroundColor White
Write-Host "  3. Télécharger le certificat et configurer les URLs" -ForegroundColor White
```

---

## 🔧 PARTIE 2 : APPLICATION PERSONNALISÉE (Repair Management)

### Créer l'application avec rôles personnalisés

```powershell
<#
.SYNOPSIS
    Créer l'application Repair Management avec rôles personnalisés
#>

# 1. Définir les rôles d'application
$appRoles = @(
    @{
        AllowedMemberTypes = @("User")
        Description = "Ingénieurs - Accès complet lecture/écriture"
        DisplayName = "Engineer"
        Id = (New-Guid).ToString()
        IsEnabled = $true
        Value = "Engineer"
    },
    @{
        AllowedMemberTypes = @("User")
        Description = "Techniciens - Lecture seule"
        DisplayName = "Technician"
        Id = (New-Guid).ToString()
        IsEnabled = $true
        Value = "Technician"
    },
    @{
        AllowedMemberTypes = @("User")
        Description = "Superviseurs - Accès complet + gestion"
        DisplayName = "Supervisor"
        Id = (New-Guid).ToString()
        IsEnabled = $true
        Value = "Supervisor"
    },
    @{
        AllowedMemberTypes = @("User")
        Description = "Lecture seule pour les rapports"
        DisplayName = "Reader"
        Id = (New-Guid).ToString()
        IsEnabled = $true
        Value = "Reader"
    }
)

# 2. Créer l'application
$repairApp = @{
    DisplayName = "Repair Management System"
    SignInAudience = "AzureADMyOrg"
    AppRoles = $appRoles
    Web = @{
        RedirectUris = @(
            "https://repair-mgmt.uss-enterprise.com/auth/callback",
            "https://localhost:5002/auth/callback"
        )
    }
    RequiredResourceAccess = @(
        @{
            ResourceAppId = "00000003-0000-0000-c000-000000000000"
            ResourceAccess = @(
                @{Id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"; Type = "Scope"}  # User.Read
            )
        }
    )
}

$repairMgmtApp = New-MgApplication -BodyParameter $repairApp

Write-Host "✓ Application 'Repair Management' créée avec rôles" -ForegroundColor Green
Write-Host "  Rôles disponibles :" -ForegroundColor Cyan
foreach ($role in $appRoles) {
    Write-Host "    - $($role.DisplayName) : $($role.Description)" -ForegroundColor White
}

# 3. Créer le Service Principal
$repairSP = New-MgServicePrincipal -AppId $repairMgmtApp.AppId

# 4. Assigner les rôles aux utilisateurs/groupes

# Obtenir les IDs des rôles créés
$engineerRole = $repairSP.AppRoles | Where-Object { $_.Value -eq "Engineer" }
$technicianRole = $repairSP.AppRoles | Where-Object { $_.Value -eq "Technician" }
$supervisorRole = $repairSP.AppRoles | Where-Object { $_.Value -eq "Supervisor" }

# Assigner le groupe Engineering Team au rôle Engineer
$engineeringTeam = Get-MgGroup -Filter "displayName eq 'Engineering Team'"
$engineeringMembers = Get-MgGroupMember -GroupId $engineeringTeam.Id

foreach ($member in $engineeringMembers) {
    try {
        $assignment = @{
            PrincipalId = $member.Id
            ResourceId = $repairSP.Id
            AppRoleId = $engineerRole.Id
        }
        
        New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $repairSP.Id -BodyParameter $assignment
        
        $user = Get-MgUser -UserId $member.Id
        Write-Host "✓ Rôle Engineer assigné à : $($user.DisplayName)" -ForegroundColor Green
    } catch {
        Write-Host "✗ Erreur pour $($member.Id)" -ForegroundColor Red
    }
}

# Assigner Montgomery Scott comme Supervisor
$scott = Get-MgUser -Filter "startswith(userPrincipalName, 'montgomery.scott')"

$supervisorAssignment = @{
    PrincipalId = $scott.Id
    ResourceId = $repairSP.Id
    AppRoleId = $supervisorRole.Id
}

New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $repairSP.Id -BodyParameter $supervisorAssignment

Write-Host "✓ Rôle Supervisor assigné à Montgomery Scott" -ForegroundColor Green
```

### Tester les accès

```powershell
<#
.SYNOPSIS
    Tester les permissions d'accès aux applications
#>

function Test-UserAppAccess {
    param(
        [string]$UserPrincipalName,
        [string]$AppDisplayName
    )
    
    Write-Host "`n=== Test d'accès pour $UserPrincipalName ===" -ForegroundColor Cyan
    
    # Obtenir l'utilisateur
    $user = Get-MgUser -Filter "userPrincipalName eq '$UserPrincipalName'"
    
    if (-not $user) {
        Write-Host "✗ Utilisateur non trouvé" -ForegroundColor Red
        return
    }
    
    # Obtenir l'application
    $sp = Get-MgServicePrincipal -Filter "displayName eq '$AppDisplayName'"
    
    if (-not $sp) {
        Write-Host "✗ Application non trouvée" -ForegroundColor Red
        return
    }
    
    # Obtenir les assignations de rôles
    $assignments = Get-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $sp.Id | 
        Where-Object { $_.PrincipalId -eq $user.Id }
    
    if ($assignments) {
        Write-Host "✓ $UserPrincipalName a accès à $AppDisplayName" -ForegroundColor Green
        
        foreach ($assignment in $assignments) {
            $role = $sp.AppRoles | Where-Object { $_.Id -eq $assignment.AppRoleId }
            if ($role) {
                Write-Host "  Rôle : $($role.DisplayName)" -ForegroundColor Cyan
            } else {
                Write-Host "  Rôle : Accès par défaut" -ForegroundColor Cyan
            }
        }
    } else {
        Write-Host "✗ $UserPrincipalName n'a PAS accès à $AppDisplayName" -ForegroundColor Red
    }
}

# Tests
Test-UserAppAccess -UserPrincipalName "montgomery.scott@uss-enterprise.com" `
    -AppDisplayName "Repair Management System"

Test-UserAppAccess -UserPrincipalName "james.kirk@uss-enterprise.com" `
    -AppDisplayName "Captain's Log"

Test-UserAppAccess -UserPrincipalName "leonard.mccoy@uss-enterprise.com" `
    -AppDisplayName "Repair Management System"
```

---

## 📋 PARTIE 3 : SCRIPT COMPLET D'INTÉGRATION

```powershell
<#
.SYNOPSIS
    Script complet d'intégration des applications USS Enterprise
#>

function Initialize-EnterpriseApplications {
    Write-Host "`n=== INTÉGRATION DES APPLICATIONS USS ENTERPRISE ===" -ForegroundColor Cyan
    
    Connect-MgGraph -Scopes "Application.ReadWrite.All", "AppRoleAssignment.ReadWrite.All"
    
    # 1. CAPTAIN'S LOG
    Write-Host "`n[1/3] Création de Captain's Log..." -ForegroundColor Yellow
    
    $captainsLog = New-MgApplication -BodyParameter @{
        DisplayName = "Captain's Log"
        SignInAudience = "AzureADMyOrg"
        Web = @{
            RedirectUris = @("https://captains-log.uss-enterprise.com/auth/callback")
        }
    }
    
    $captainsLogSP = New-MgServicePrincipal -AppId $captainsLog.AppId
    
    # Assigner Command Team
    $commandTeam = Get-MgGroup -Filter "displayName eq 'Command Team'"
    New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $captainsLogSP.Id -BodyParameter @{
        PrincipalId = $commandTeam.Id
        ResourceId = $captainsLogSP.Id
        AppRoleId = "00000000-0000-0000-0000-000000000000"
    }
    
    Write-Host "  ✓ Captain's Log créé et assigné au Command Team" -ForegroundColor Green
    
    # 2. COMMAND CENTER
    Write-Host "`n[2/3] Création de Command Center..." -ForegroundColor Yellow
    
    $commandCenter = New-MgApplication -BodyParameter @{
        DisplayName = "Command Center"
        SignInAudience = "AzureADMyOrg"
        Web = @{
            RedirectUris = @("https://command-center.uss-enterprise.com/saml/acs")
        }
    }
    
    $commandCenterSP = New-MgServicePrincipal -AppId $commandCenter.AppId
    
    # Assigner Senior Officers
    $seniorOfficers = Get-MgGroup -Filter "displayName eq 'Senior Officers'"
    New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $commandCenterSP.Id -BodyParameter @{
        PrincipalId = $seniorOfficers.Id
        ResourceId = $commandCenterSP.Id
        AppRoleId = "00000000-0000-0000-0000-000000000000"
    }
    
    Write-Host "  ✓ Command Center créé et assigné aux Senior Officers" -ForegroundColor Green
    
    # 3. REPAIR MANAGEMENT
    Write-Host "`n[3/3] Création de Repair Management..." -ForegroundColor Yellow
    
    $repairRoles = @(
        @{AllowedMemberTypes=@("User"); DisplayName="Engineer"; Id=(New-Guid).ToString(); IsEnabled=$true; Value="Engineer"; Description="Ingénieurs"},
        @{AllowedMemberTypes=@("User"); DisplayName="Supervisor"; Id=(New-Guid).ToString(); IsEnabled=$true; Value="Supervisor"; Description="Superviseurs"}
    )
    
    $repairMgmt = New-MgApplication -BodyParameter @{
        DisplayName = "Repair Management"
        SignInAudience = "AzureADMyOrg"
        AppRoles = $repairRoles
        Web = @{
            RedirectUris = @("https://repair-mgmt.uss-enterprise.com/auth/callback")
        }
    }
    
    $repairSP = New-MgServicePrincipal -AppId $repairMgmt.AppId
    
    # Assigner Engineering Team
    $engineerRole = $repairSP.AppRoles | Where-Object { $_.Value -eq "Engineer" }
    $engineeringTeam = Get-MgGroup -Filter "displayName eq 'Engineering Team'"
    $members = Get-MgGroupMember -GroupId $engineeringTeam.Id
    
    foreach ($member in $members) {
        New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $repairSP.Id -BodyParameter @{
            PrincipalId = $member.Id
            ResourceId = $repairSP.Id
            AppRoleId = $engineerRole.Id
        }
    }
    
    Write-Host "  ✓ Repair Management créé avec $($members.Count) ingénieurs assignés" -ForegroundColor Green
    
    # RÉSUMÉ
    Write-Host "`n=== RÉSUMÉ ===" -ForegroundColor Green
    Write-Host "✓ 3 applications intégrées" -ForegroundColor Cyan
    Write-Host "  - Captain's Log (Command Team)" -ForegroundColor White
    Write-Host "  - Command Center (Senior Officers)" -ForegroundColor White
    Write-Host "  - Repair Management (Engineering Team)" -ForegroundColor White
    
    Write-Host "`n⚠️  ACTIONS SUIVANTES :" -ForegroundColor Yellow
    Write-Host "1. Configurer les URLs de redirection dans les applications" -ForegroundColor White
    Write-Host "2. Distribuer les secrets clients aux développeurs" -ForegroundColor White
    Write-Host "3. Tester le SSO avec chaque application" -ForegroundColor White
    Write-Host "4. Configurer le SSO SAML pour Command Center (portail)" -ForegroundColor White
}

# Exécuter
Initialize-EnterpriseApplications
```

---

## 🎯 Résumé des commandes essentielles

| Action | Commande |
|--------|----------|
| **Créer application** | `New-MgApplication -BodyParameter @{...}` |
| **Créer service principal** | `New-MgServicePrincipal -AppId "app-id"` |
| **Créer secret client** | `Add-MgApplicationPassword -ApplicationId "id"` |
| **Assigner utilisateur** | `New-MgServicePrincipalAppRoleAssignment` |
| **Lister applications** | `Get-MgApplication` |
| **Tester accès** | `Get-MgServicePrincipalAppRoleAssignedTo` |

---

## ✅ Checklist d'intégration

- [ ] Captain's Log créé
- [ ] Command Center créé
- [ ] Repair Management créé avec rôles
- [ ] SSO configuré pour chaque application
- [ ] Groupes assignés aux applications
- [ ] Secrets clients sauvegardés de manière sécurisée
- [ ] Permissions testées
- [ ] URLs de redirection configurées
- [ ] Documentation fournie aux développeurs

---

**Date de création** : Novembre 2024  
**Version** : 1.0  
**Projet** : USS Enterprise - Entra ID Security