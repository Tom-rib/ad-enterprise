# Guide 06 - Gestion des Rôles et Permissions

## 📚 À quoi ça sert ?

Les **rôles** dans Entra ID définissent ce qu'un utilisateur ou un groupe peut faire dans le tenant. C'est le système de **contrôle d'accès basé sur les rôles (RBAC - Role-Based Access Control)**.

### Pourquoi utiliser des rôles ?
- **Sécurité** : Appliquer le principe du moindre privilège
- **Délégation** : Permettre l'administration sans donner tous les droits
- **Audit** : Tracer qui peut faire quoi
- **Conformité** : Respecter les standards de sécurité

---

## 🎭 Types de rôles dans Entra ID

### 1. **Rôles intégrés (Built-in Roles)**
Rôles prédéfinis par Microsoft, impossibles à modifier mais assignables aux utilisateurs.

### 2. **Rôles personnalisés (Custom Roles)**
Rôles créés sur mesure avec des permissions spécifiques (nécessite Azure AD Premium P1/P2).

---

## 🔑 Rôles intégrés essentiels

### Rôles d'administration globale

| Rôle | Description | Usage |
|------|-------------|-------|
| **Global Administrator** | Accès complet à tout | Compte d'urgence uniquement |
| **Privileged Role Administrator** | Gérer les rôles | Administration des accès |
| **Security Administrator** | Gérer la sécurité | Politiques de sécurité |

### Rôles d'administration utilisateurs

| Rôle | Description | Usage |
|------|-------------|-------|
| **User Administrator** | Gérer les utilisateurs | Administration RH |
| **Groups Administrator** | Gérer les groupes | Organisation équipes |
| **Password Administrator** | Réinitialiser mots de passe | Support technique |

### Rôles d'administration applications

| Rôle | Description | Usage |
|------|-------------|-------|
| **Application Administrator** | Gérer toutes les applications | Administration apps |
| **Cloud Application Administrator** | Gérer apps cloud | Apps SaaS |

### Rôles de lecture seule

| Rôle | Description | Usage |
|------|-------------|-------|
| **Global Reader** | Lecture seule globale | Audit, reporting |
| **Security Reader** | Lecture sécurité | Analystes sécurité |
| **Reports Reader** | Lecture rapports | Business analysts |

---

## 🔍 Consulter les rôles

### Lister tous les rôles disponibles

```powershell
# Tous les rôles de répertoire
Get-MgDirectoryRoleTemplate | Select-Object DisplayName, Description | Sort-Object DisplayName

# Nombre total
$roles = Get-MgDirectoryRoleTemplate
Write-Host "Total de rôles disponibles : $($roles.Count)" -ForegroundColor Cyan
```

### Lister les rôles actifs (activés)

```powershell
# Rôles actuellement activés dans le tenant
Get-MgDirectoryRole | Select-Object DisplayName, Description
```

### Chercher un rôle spécifique

```powershell
# Par nom exact
Get-MgDirectoryRoleTemplate -Filter "displayName eq 'Global Administrator'"

# Recherche partielle
Get-MgDirectoryRoleTemplate | Where-Object { $_.DisplayName -like "*Admin*" }

# Obtenir l'ID d'un rôle
$role = Get-MgDirectoryRoleTemplate -Filter "displayName eq 'User Administrator'"
Write-Host "ID du rôle : $($role.Id)"
```

---

## 👥 Gérer les assignations de rôles

### Voir qui a un rôle spécifique

```powershell
# Obtenir le rôle activé
$role = Get-MgDirectoryRole -Filter "displayName eq 'Global Administrator'"

# Lister les membres
$members = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id

foreach ($member in $members) {
    $user = Get-MgUser -UserId $member.Id
    Write-Host "- $($user.DisplayName) ($($user.UserPrincipalName))"
}
```

### Assigner un rôle à un utilisateur

```powershell
# Étape 1 : Activer le rôle (si pas déjà activé)
$roleTemplate = Get-MgDirectoryRoleTemplate -Filter "displayName eq 'User Administrator'"

# Vérifier si le rôle est déjà activé
$activeRole = Get-MgDirectoryRole -Filter "roleTemplateId eq '$($roleTemplate.Id)'"

if (-not $activeRole) {
    # Activer le rôle
    $activeRole = New-MgDirectoryRole -RoleTemplateId $roleTemplate.Id
    Write-Host "✓ Rôle activé" -ForegroundColor Green
}

# Étape 2 : Obtenir l'utilisateur
$user = Get-MgUser -Filter "userPrincipalName eq 'james.kirk@uss-enterprise.com'"

# Étape 3 : Assigner le rôle
$memberRef = @{
    "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($user.Id)"
}

New-MgDirectoryRoleMemberByRef -DirectoryRoleId $activeRole.Id -BodyParameter $memberRef

Write-Host "✓ Rôle 'User Administrator' assigné à $($user.DisplayName)" -ForegroundColor Green
```

### Fonction réutilisable pour assigner un rôle

```powershell
function Add-EnterpriseRoleAssignment {
    <#
    .SYNOPSIS
        Assigne un rôle Entra ID à un utilisateur
    .PARAMETER UserEmail
        Email de l'utilisateur
    .PARAMETER RoleName
        Nom du rôle à assigner
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$UserEmail,
        
        [Parameter(Mandatory=$true)]
        [string]$RoleName
    )
    
    try {
        # Obtenir l'utilisateur
        $user = Get-MgUser -Filter "userPrincipalName eq '$UserEmail'"
        if (-not $user) {
            throw "Utilisateur non trouvé : $UserEmail"
        }
        
        # Obtenir le template du rôle
        $roleTemplate = Get-MgDirectoryRoleTemplate -Filter "displayName eq '$RoleName'"
        if (-not $roleTemplate) {
            throw "Rôle non trouvé : $RoleName"
        }
        
        # Vérifier/Activer le rôle
        $activeRole = Get-MgDirectoryRole -Filter "roleTemplateId eq '$($roleTemplate.Id)'"
        if (-not $activeRole) {
            $activeRole = New-MgDirectoryRole -RoleTemplateId $roleTemplate.Id
            Write-Host "✓ Rôle activé : $RoleName" -ForegroundColor Yellow
        }
        
        # Vérifier si déjà assigné
        $members = Get-MgDirectoryRoleMember -DirectoryRoleId $activeRole.Id
        if ($members.Id -contains $user.Id) {
            Write-Host "⚠️  L'utilisateur a déjà ce rôle" -ForegroundColor Yellow
            return
        }
        
        # Assigner le rôle
        $memberRef = @{
            "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($user.Id)"
        }
        
        New-MgDirectoryRoleMemberByRef -DirectoryRoleId $activeRole.Id -BodyParameter $memberRef
        
        Write-Host "✓ Rôle '$RoleName' assigné à $($user.DisplayName)" -ForegroundColor Green
        
    } catch {
        Write-Error "Erreur : $_"
        throw
    }
}

# Utilisation
Add-EnterpriseRoleAssignment -UserEmail "james.kirk@uss-enterprise.com" `
    -RoleName "User Administrator"
```

### Retirer un rôle

```powershell
# Obtenir le rôle
$role = Get-MgDirectoryRole -Filter "displayName eq 'User Administrator'"

# Obtenir l'utilisateur
$user = Get-MgUser -Filter "userPrincipalName eq 'james.kirk@uss-enterprise.com'"

# Retirer l'assignation
Remove-MgDirectoryRoleMemberByRef -DirectoryRoleId $role.Id -DirectoryObjectId $user.Id

Write-Host "✓ Rôle retiré" -ForegroundColor Yellow
```

---

## 🎭 Rôles personnalisés (Custom Roles)

**⚠️ Nécessite Azure AD Premium P1 ou P2**

### Créer un rôle personnalisé

```powershell
# Définir les permissions
$rolePermissions = @{
    allowedResourceActions = @(
        "microsoft.directory/users/basic/update",
        "microsoft.directory/users/password/update"
    )
}

# Créer le rôle
$customRole = New-MgRoleManagementDirectoryRoleDefinition -DisplayName "USS Enterprise - Password Reset Officer" `
    -Description "Peut réinitialiser les mots de passe uniquement" `
    -IsEnabled:$true `
    -RolePermissions $rolePermissions

Write-Host "✓ Rôle personnalisé créé" -ForegroundColor Green
```

### Exemples de permissions courantes

```powershell
# Lecture des utilisateurs
"microsoft.directory/users/standard/read"

# Mise à jour basique des utilisateurs
"microsoft.directory/users/basic/update"

# Réinitialisation de mot de passe
"microsoft.directory/users/password/update"

# Création d'utilisateurs
"microsoft.directory/users/create"

# Suppression d'utilisateurs
"microsoft.directory/users/delete"

# Gestion des groupes
"microsoft.directory/groups/create"
"microsoft.directory/groups/delete"
"microsoft.directory/groups/basic/update"
"microsoft.directory/groups/members/update"
```

---

## 🔐 Rôles d'application (App Roles)

Les rôles d'application sont définis au niveau des applications et contrôlent l'accès aux fonctionnalités.

### Créer un rôle d'application

```powershell
# Obtenir l'application
$app = Get-MgApplication -Filter "displayName eq 'Repair Management'"

# Définir les rôles
$appRoles = @(
    @{
        AllowedMemberTypes = @("User")
        Description = "Ingénieurs - Accès complet"
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
    }
)

# Mettre à jour l'application
Update-MgApplication -ApplicationId $app.Id -AppRoles $appRoles

Write-Host "✓ Rôles d'application créés" -ForegroundColor Green
```

### Assigner un rôle d'application à un utilisateur

```powershell
# Obtenir l'application et son service principal
$app = Get-MgApplication -Filter "displayName eq 'Repair Management'"
$sp = Get-MgServicePrincipal -Filter "appId eq '$($app.AppId)'"

# Obtenir le rôle Engineer
$engineerRole = $sp.AppRoles | Where-Object { $_.Value -eq "Engineer" }

# Obtenir l'utilisateur
$user = Get-MgUser -Filter "userPrincipalName eq 'montgomery.scott@uss-enterprise.com'"

# Assigner le rôle
New-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $sp.Id -BodyParameter @{
    PrincipalId = $user.Id
    ResourceId = $sp.Id
    AppRoleId = $engineerRole.Id
}

Write-Host "✓ Rôle 'Engineer' assigné à $($user.DisplayName)" -ForegroundColor Green
```

---

## 📊 Audit et rapports des rôles

### Rapport complet des assignations de rôles

```powershell
function Get-RoleAssignmentReport {
    Write-Host "Génération du rapport des rôles..." -ForegroundColor Cyan
    
    # Obtenir tous les rôles actifs
    $roles = Get-MgDirectoryRole
    
    $report = @()
    
    foreach ($role in $roles) {
        $members = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id
        
        foreach ($member in $members) {
            try {
                $user = Get-MgUser -UserId $member.Id -ErrorAction SilentlyContinue
                if ($user) {
                    $report += [PSCustomObject]@{
                        RoleName = $role.DisplayName
                        UserName = $user.DisplayName
                        UPN = $user.UserPrincipalName
                        AccountEnabled = $user.AccountEnabled
                        Department = $user.Department
                        JobTitle = $user.JobTitle
                    }
                }
            } catch {
                # Ignorer les membres qui ne sont pas des utilisateurs (groupes, etc.)
            }
        }
    }
    
    # Afficher
    $report | Format-Table -AutoSize
    
    # Exporter
    $report | Export-Csv -Path "./reports/role-assignments-$(Get-Date -Format 'yyyyMMdd').csv" `
        -NoTypeInformation -Encoding UTF8
    
    Write-Host "`n✓ Rapport exporté" -ForegroundColor Green
    
    # Statistiques
    Write-Host "`n=== Statistiques ===" -ForegroundColor Cyan
    Write-Host "Total assignations : $($report.Count)" -ForegroundColor Yellow
    Write-Host "Rôles uniques : $($roles.Count)" -ForegroundColor Yellow
}

Get-RoleAssignmentReport
```

### Trouver les administrateurs globaux

```powershell
function Get-GlobalAdmins {
    $role = Get-MgDirectoryRole -Filter "displayName eq 'Global Administrator'"
    $members = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id
    
    Write-Host "`n=== Administrateurs Globaux ===" -ForegroundColor Red
    Write-Host "⚠️  Ces comptes ont un accès complet au tenant`n" -ForegroundColor Yellow
    
    foreach ($member in $members) {
        $user = Get-MgUser -UserId $member.Id
        Write-Host "- $($user.DisplayName) ($($user.UserPrincipalName))" -ForegroundColor Cyan
        Write-Host "  Compte actif : $($user.AccountEnabled)" -ForegroundColor $(if ($user.AccountEnabled) { "Green" } else { "Red" })
        Write-Host "  Créé le : $($user.CreatedDateTime)" -ForegroundColor Gray
        Write-Host ""
    }
    
    Write-Host "Total : $($members.Count) administrateurs globaux" -ForegroundColor Yellow
    
    if ($members.Count -gt 5) {
        Write-Host "⚠️  AVERTISSEMENT : Plus de 5 admins globaux détectés!" -ForegroundColor Red
        Write-Host "   Bonnes pratiques : Limiter à 2-3 comptes maximum" -ForegroundColor Yellow
    }
}

Get-GlobalAdmins
```

### Audit des rôles privilégiés

```powershell
function Get-PrivilegedRolesAudit {
    $privilegedRoles = @(
        "Global Administrator",
        "Privileged Role Administrator",
        "Security Administrator",
        "Application Administrator",
        "Cloud Application Administrator",
        "User Administrator"
    )
    
    Write-Host "`n=== Audit des Rôles Privilégiés ===" -ForegroundColor Cyan
    
    $auditData = @()
    
    foreach ($roleName in $privilegedRoles) {
        $role = Get-MgDirectoryRole -Filter "displayName eq '$roleName'"
        
        if ($role) {
            $members = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id
            
            Write-Host "`n[$roleName] - $($members.Count) membres" -ForegroundColor Yellow
            
            foreach ($member in $members) {
                $user = Get-MgUser -UserId $member.Id -ErrorAction SilentlyContinue
                if ($user) {
                    Write-Host "  - $($user.DisplayName)" -ForegroundColor Cyan
                    
                    $auditData += [PSCustomObject]@{
                        Role = $roleName
                        User = $user.DisplayName
                        UPN = $user.UserPrincipalName
                        Enabled = $user.AccountEnabled
                        LastPasswordChange = $user.LastPasswordChangeDateTime
                    }
                }
            }
        }
    }
    
    # Exporter
    $auditData | Export-Csv -Path "./reports/privileged-roles-audit-$(Get-Date -Format 'yyyyMMdd').csv" `
        -NoTypeInformation -Encoding UTF8
    
    Write-Host "`n✓ Audit terminé et exporté" -ForegroundColor Green
}

Get-PrivilegedRolesAudit
```

---

## 🔒 Bonnes pratiques de sécurité

### Principe du moindre privilège

```powershell
# ❌ MAUVAIS : Donner Global Administrator à tout le monde
Add-EnterpriseRoleAssignment -UserEmail "support@company.com" -RoleName "Global Administrator"

# ✅ BON : Donner le rôle minimal nécessaire
Add-EnterpriseRoleAssignment -UserEmail "support@company.com" -RoleName "Password Administrator"
```

### Limiter les administrateurs globaux

```powershell
function Test-GlobalAdminCount {
    $role = Get-MgDirectoryRole -Filter "displayName eq 'Global Administrator'"
    $members = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id
    
    if ($members.Count -gt 3) {
        Write-Host "⚠️  ALERTE : $($members.Count) administrateurs globaux!" -ForegroundColor Red
        Write-Host "   Recommandation : Maximum 2-3 comptes" -ForegroundColor Yellow
        Write-Host "   Action : Revoir les assignations et utiliser des rôles moins privilégiés" -ForegroundColor Yellow
    } else {
        Write-Host "✓ Nombre d'administrateurs globaux acceptable : $($members.Count)" -ForegroundColor Green
    }
}

Test-GlobalAdminCount
```

### Créer un compte d'urgence (Break Glass)

```powershell
function New-EmergencyAdminAccount {
    # Créer le compte
    $password = "VotreMotDePasseTrèsSécurisé123!@#"
    
    $passwordProfile = @{
        Password = $password
        ForceChangePasswordNextSignIn = $false
    }
    
    $emergencyUser = New-MgUser -DisplayName "Emergency Admin - USS Enterprise" `
        -UserPrincipalName "emergency-admin@uss-enterprise.onmicrosoft.com" `
        -MailNickname "emergency-admin" `
        -AccountEnabled:$true `
        -PasswordProfile $passwordProfile `
        -UsageLocation "FR"
    
    # Assigner Global Administrator
    Add-EnterpriseRoleAssignment -UserEmail $emergencyUser.UserPrincipalName `
        -RoleName "Global Administrator"
    
    Write-Host "✓ Compte d'urgence créé" -ForegroundColor Green
    Write-Host "`n⚠️  INFORMATIONS CRITIQUES À SAUVEGARDER :" -ForegroundColor Red
    Write-Host "   UPN : $($emergencyUser.UserPrincipalName)" -ForegroundColor Yellow
    Write-Host "   Mot de passe : $password" -ForegroundColor Yellow
    Write-Host "`n⚠️  À conserver dans un coffre-fort sécurisé!" -ForegroundColor Red
    Write-Host "   Ce compte doit être EXCLU de toutes les politiques MFA" -ForegroundColor Yellow
}
```

---

## 📝 Script complet : Configuration des rôles USS Enterprise

```powershell
<#
.SYNOPSIS
    Configure les rôles pour le projet USS Enterprise
#>

function Initialize-EnterpriseRoles {
    Write-Host "`n=== Configuration des Rôles USS Enterprise ===" -ForegroundColor Cyan
    
    Connect-MgGraph -Scopes "RoleManagement.ReadWrite.Directory", "User.ReadWrite.All"
    
    # Définir la structure des rôles
    $roleStructure = @{
        "james.kirk@uss-enterprise.com" = @("Global Administrator")
        "spock@uss-enterprise.com" = @("Security Administrator", "User Administrator")
        "leonard.mccoy@uss-enterprise.com" = @("User Administrator")
        "montgomery.scott@uss-enterprise.com" = @("Groups Administrator")
    }
    
    Write-Host "`nAssignation des rôles..." -ForegroundColor Yellow
    
    foreach ($userEmail in $roleStructure.Keys) {
        Write-Host "`n[$userEmail]" -ForegroundColor Cyan
        
        foreach ($roleName in $roleStructure[$userEmail]) {
            try {
                Add-EnterpriseRoleAssignment -UserEmail $userEmail -RoleName $roleName
            } catch {
                Write-Host "  ✗ Erreur : $_" -ForegroundColor Red
            }
        }
    }
    
    Write-Host "`n✓ Configuration des rôles terminée" -ForegroundColor Green
    
    # Générer un rapport
    Get-RoleAssignmentReport
}

Initialize-EnterpriseRoles
```

---

## 🎯 Résumé des commandes essentielles

| Action | Commande |
|--------|----------|
| **Lister les rôles** | `Get-MgDirectoryRoleTemplate` |
| **Voir les membres d'un rôle** | `Get-MgDirectoryRoleMember -DirectoryRoleId "id"` |
| **Activer un rôle** | `New-MgDirectoryRole -RoleTemplateId "id"` |
| **Assigner un rôle** | `New-MgDirectoryRoleMemberByRef -DirectoryRoleId "id"` |
| **Retirer un rôle** | `Remove-MgDirectoryRoleMemberByRef -DirectoryRoleId "id"` |
| **Créer rôle personnalisé** | `New-MgRoleManagementDirectoryRoleDefinition` |

---

## ⚠️ Checklist de sécurité des rôles

- [ ] Maximum 2-3 administrateurs globaux
- [ ] Compte d'urgence (Break Glass) créé et sécurisé
- [ ] Compte d'urgence exclu des politiques MFA
- [ ] MFA activé pour tous les comptes privilégiés
- [ ] Audit régulier des assignations de rôles
- [ ] Documentation des rôles et responsabilités
- [ ] Révision trimestrielle des accès privilégiés
- [ ] Utilisation du principe du moindre privilège
- [ ] Rôles personnalisés pour besoins spécifiques
- [ ] Monitoring des changements de rôles

---

## 📚 Ressources complémentaires

- [Rôles intégrés Azure AD](https://learn.microsoft.com/en-us/azure/active-directory/roles/permissions-reference)
- [Rôles personnalisés](https://learn.microsoft.com/en-us/azure/active-directory/roles/custom-create)
- [Bonnes pratiques sécurité](https://learn.microsoft.com/en-us/azure/active-directory/roles/best-practices)

---

**Date de création** : Novembre 2024  
**Version** : 1.0  
**Projet** : USS Enterprise - Entra ID Security