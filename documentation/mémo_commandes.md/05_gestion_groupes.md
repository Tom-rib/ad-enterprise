# Guide 05 - Gestion des Groupes (Groups)

## 📚 À quoi ça sert ?

Les **groupes** permettent de regrouper des utilisateurs pour simplifier la gestion des permissions, des accès et des politiques de sécurité.

### Pourquoi utiliser des groupes ?
- **Simplification** : Attribuer des permissions à un groupe plutôt qu'à chaque utilisateur individuellement
- **Organisation** : Structurer logiquement vos équipes et départements
- **Automatisation** : Appliquer des politiques de sécurité à un groupe entier
- **Collaboration** : Faciliter le partage de ressources entre membres

---

## 🔢 Types de groupes dans Entra ID

### 1. **Groupes de sécurité (Security Groups)**
- **Usage** : Gestion des accès et permissions
- **Membres** : Utilisateurs et autres groupes
- **Exemple** : "Équipe d'Ingénierie", "Administrateurs"

### 2. **Groupes Microsoft 365 (M365 Groups)**
- **Usage** : Collaboration (Teams, SharePoint, Outlook)
- **Membres** : Utilisateurs uniquement
- **Inclut** : Boîte mail partagée, calendrier, SharePoint
- **Exemple** : "Projet Warp Drive", "Mission Exploration"

### 3. **Groupes de distribution (Distribution Lists)**
- **Usage** : Envoi d'emails uniquement
- **Pas de gestion** : Ne peut pas être utilisé pour permissions
- **Exemple** : "Tous les employés", "Notifications"

---

## 🔍 Consulter les groupes existants

### Lister tous les groupes

```powershell
# Tous les groupes
Get-MgGroup

# Top 20 groupes
Get-MgGroup -Top 20

# Avec propriétés spécifiques
Get-MgGroup | Select-Object DisplayName, Id, GroupTypes, SecurityEnabled, MailEnabled
```

### Rechercher un groupe spécifique

```powershell
# Par nom
Get-MgGroup -Filter "displayName eq 'Équipe d''Ingénierie'"

# Recherche partielle
Get-MgGroup -Filter "startswith(displayName, 'Équipe')"

# Par description
Get-MgGroup -Filter "contains(description, 'Engineering')"

# Groupes de sécurité uniquement
Get-MgGroup -Filter "securityEnabled eq true"

# Groupes Microsoft 365 uniquement
Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')"
```

### Obtenir les détails d'un groupe

```powershell
# Par ID
Get-MgGroup -GroupId "GROUP-ID"

# Par nom (avec filtre)
$group = Get-MgGroup -Filter "displayName eq 'Équipe d''Ingénierie'"
$group | Format-List
```

---

## ➕ Créer des groupes

### Créer un groupe de sécurité simple

```powershell
# Groupe de sécurité basique
$group = New-MgGroup -DisplayName "Équipe d'Exploration" `
    -Description "Membres des missions d'exploration" `
    -MailEnabled:$false `
    -SecurityEnabled:$true `
    -MailNickname "exploration-team"

Write-Host "✓ Groupe créé : $($group.DisplayName)" -ForegroundColor Green
Write-Host "  ID : $($group.Id)" -ForegroundColor Cyan
```

### Créer un groupe Microsoft 365

```powershell
# Groupe M365 (avec email et collaboration)
$group = New-MgGroup -DisplayName "Projet Warp Drive" `
    -Description "Équipe du projet Warp Drive" `
    -MailEnabled:$true `
    -SecurityEnabled:$false `
    -MailNickname "warp-drive-project" `
    -GroupTypes @("Unified")  # "Unified" = Microsoft 365 Group

Write-Host "✓ Groupe Microsoft 365 créé" -ForegroundColor Green
```

### Fonction de création de groupe réutilisable

```powershell
function New-EnterpriseTeam {
    <#
    .SYNOPSIS
        Crée un nouveau groupe pour l'USS Enterprise
    .PARAMETER TeamName
        Nom du groupe
    .PARAMETER Description
        Description du groupe
    .PARAMETER Type
        Type : 'Security' ou 'Microsoft365'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TeamName,
        
        [Parameter(Mandatory=$true)]
        [string]$Description,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Security', 'Microsoft365')]
        [string]$Type = 'Security'
    )
    
    try {
        # Créer le mail nickname (sans espaces ni caractères spéciaux)
        $mailNickname = ($TeamName -replace '[^a-zA-Z0-9]', '').ToLower()
        
        # Paramètres selon le type
        if ($Type -eq 'Microsoft365') {
            $groupParams = @{
                DisplayName = $TeamName
                Description = $Description
                MailEnabled = $true
                SecurityEnabled = $false
                MailNickname = $mailNickname
                GroupTypes = @("Unified")
            }
        } else {
            $groupParams = @{
                DisplayName = $TeamName
                Description = $Description
                MailEnabled = $false
                SecurityEnabled = $true
                MailNickname = $mailNickname
                GroupTypes = @()
            }
        }
        
        $group = New-MgGroup @groupParams
        
        Write-Host "✓ Groupe créé : $TeamName" -ForegroundColor Green
        Write-Host "  Type : $Type" -ForegroundColor Cyan
        Write-Host "  ID : $($group.Id)" -ForegroundColor Cyan
        
        return $group
        
    } catch {
        Write-Error "Erreur lors de la création du groupe : $_"
        throw
    }
}

# Utilisation
New-EnterpriseTeam -TeamName "Équipe d'Ingénierie" `
    -Description "Ingénieurs et techniciens du vaisseau" `
    -Type "Security"
```

### Créer plusieurs groupes en masse

```powershell
# Définir la structure organisationnelle
$teams = @(
    @{Name="Équipe de Commandement"; Description="Capitaine et officiers de commandement"},
    @{Name="Officiers Supérieurs"; Description="Tous les officiers de rang supérieur"},
    @{Name="Équipe d'Exploration"; Description="Membres des missions d'exploration"},
    @{Name="Équipe Médicale"; Description="Personnel médical du vaisseau"},
    @{Name="Équipe d'Ingénierie"; Description="Ingénieurs et techniciens"},
    @{Name="Équipe de Sécurité"; Description="Personnel de sécurité"},
    @{Name="Équipe Scientifique"; Description="Scientifiques et analystes"}
)

# Créer tous les groupes
$createdGroups = @{}
foreach ($team in $teams) {
    $group = New-EnterpriseTeam -TeamName $team.Name `
        -Description $team.Description `
        -Type "Security"
    
    $createdGroups[$team.Name] = $group
    Start-Sleep -Seconds 1  # Éviter le throttling
}

# Sauvegarder les IDs
$groupsData = @{}
foreach ($key in $createdGroups.Keys) {
    $groupsData[$key] = @{
        Id = $createdGroups[$key].Id
        DisplayName = $createdGroups[$key].DisplayName
    }
}

$groupsData | ConvertTo-Json | Out-File "./config/groups.json" -Encoding UTF8

Write-Host "`n✓ Tous les groupes créés et sauvegardés" -ForegroundColor Green
```

---

## 👥 Gérer les membres des groupes

### Ajouter des membres

```powershell
# Ajouter un utilisateur à un groupe
$groupId = "GROUP-ID"
$userId = "USER-ID"

New-MgGroupMember -GroupId $groupId -DirectoryObjectId $userId

Write-Host "✓ Utilisateur ajouté au groupe" -ForegroundColor Green
```

### Ajouter plusieurs membres

```powershell
# Par UPN
$groupId = "GROUP-ID"
$userEmails = @(
    "james.kirk@uss-enterprise.com",
    "spock@uss-enterprise.com",
    "leonard.mccoy@uss-enterprise.com"
)

foreach ($email in $userEmails) {
    $user = Get-MgUser -Filter "userPrincipalName eq '$email'"
    if ($user) {
        New-MgGroupMember -GroupId $groupId -DirectoryObjectId $user.Id
        Write-Host "✓ Ajouté : $($user.DisplayName)" -ForegroundColor Green
    } else {
        Write-Host "✗ Utilisateur non trouvé : $email" -ForegroundColor Red
    }
}
```

### Lister les membres d'un groupe

```powershell
# Obtenir tous les membres
$groupId = "GROUP-ID"
$members = Get-MgGroupMember -GroupId $groupId

# Afficher les membres
$members | ForEach-Object {
    $user = Get-MgUser -UserId $_.Id
    Write-Host "- $($user.DisplayName) ($($user.UserPrincipalName))"
}

# Compter les membres
Write-Host "`nTotal : $($members.Count) membres" -ForegroundColor Cyan
```

### Vérifier si un utilisateur est membre

```powershell
$groupId = "GROUP-ID"
$userId = "USER-ID"

$members = Get-MgGroupMember -GroupId $groupId

if ($members.Id -contains $userId) {
    Write-Host "✓ L'utilisateur est membre du groupe" -ForegroundColor Green
} else {
    Write-Host "✗ L'utilisateur n'est PAS membre du groupe" -ForegroundColor Red
}
```

### Supprimer un membre

```powershell
# Retirer un utilisateur d'un groupe
$groupId = "GROUP-ID"
$userId = "USER-ID"

Remove-MgGroupMemberByRef -GroupId $groupId -DirectoryObjectId $userId

Write-Host "✓ Utilisateur retiré du groupe" -ForegroundColor Yellow
```

---

## 👤 Gérer les propriétaires (Owners)

### Ajouter un propriétaire

```powershell
# Les propriétaires peuvent gérer le groupe
$groupId = "GROUP-ID"
$userId = "USER-ID"

$ownerRef = @{
    "@odata.id" = "https://graph.microsoft.com/v1.0/users/$userId"
}

New-MgGroupOwnerByRef -GroupId $groupId -BodyParameter $ownerRef

Write-Host "✓ Propriétaire ajouté" -ForegroundColor Green
```

### Lister les propriétaires

```powershell
$groupId = "GROUP-ID"
$owners = Get-MgGroupOwner -GroupId $groupId

foreach ($owner in $owners) {
    $user = Get-MgUser -UserId $owner.Id
    Write-Host "- $($user.DisplayName) ($($user.UserPrincipalName))"
}
```

### Supprimer un propriétaire

```powershell
$groupId = "GROUP-ID"
$userId = "USER-ID"

Remove-MgGroupOwnerByRef -GroupId $groupId -DirectoryObjectId $userId

Write-Host "✓ Propriétaire retiré" -ForegroundColor Yellow
```

---

## ✏️ Modifier des groupes

### Modifier les propriétés d'un groupe

```powershell
# Modifier la description
Update-MgGroup -GroupId "GROUP-ID" -Description "Nouvelle description"

# Modifier plusieurs propriétés
Update-MgGroup -GroupId "GROUP-ID" `
    -DisplayName "Nouveau nom" `
    -Description "Nouvelle description"
```

### Renommer un groupe

```powershell
$groupId = "GROUP-ID"
$newName = "Équipe d'Exploration Avancée"

Update-MgGroup -GroupId $groupId -DisplayName $newName

Write-Host "✓ Groupe renommé : $newName" -ForegroundColor Green
```

---

## 🗑️ Supprimer des groupes

### Supprimer un groupe

```powershell
# Supprimer (soft delete - 30 jours de rétention)
Remove-MgGroup -GroupId "GROUP-ID"

Write-Host "✓ Groupe supprimé" -ForegroundColor Yellow
Write-Host "  Le groupe peut être restauré pendant 30 jours" -ForegroundColor Cyan
```

### Restaurer un groupe supprimé

```powershell
# Lister les groupes supprimés
Get-MgDirectoryDeletedItem

# Restaurer
Restore-MgDirectoryDeletedItem -DirectoryObjectId "GROUP-ID"

Write-Host "✓ Groupe restauré" -ForegroundColor Green
```

---

## 🔄 Groupes dynamiques

Les **groupes dynamiques** ajoutent/retirent automatiquement des membres selon des règles.

### Créer un groupe dynamique

```powershell
# Groupe dynamique basé sur le département
$group = New-MgGroup -DisplayName "Tous les Ingénieurs (Dynamique)" `
    -Description "Groupe dynamique pour tous les ingénieurs" `
    -MailEnabled:$false `
    -SecurityEnabled:$true `
    -MailNickname "all-engineers-dynamic" `
    -GroupTypes @("DynamicMembership") `
    -MembershipRule "(user.department -eq ""Engineering"")" `
    -MembershipRuleProcessingState "On"

Write-Host "✓ Groupe dynamique créé" -ForegroundColor Green
```

### Exemples de règles d'adhésion

```powershell
# Règle 1 : Tous les utilisateurs d'un département
$rule1 = "(user.department -eq ""Engineering"")"

# Règle 2 : Utilisateurs avec un titre spécifique
$rule2 = "(user.jobTitle -eq ""Captain"")"

# Règle 3 : Combinaison (ET)
$rule3 = "(user.department -eq ""Command"") -and (user.jobTitle -contains ""Officer"")"

# Règle 4 : Combinaison (OU)
$rule4 = "(user.department -eq ""Medical"") -or (user.department -eq ""Science"")"

# Règle 5 : Basé sur l'emplacement
$rule5 = "(user.city -eq ""Paris"")"

# Règle 6 : Basé sur le domaine email
$rule6 = "(user.userPrincipalName -contains ""@uss-enterprise.com"")"
```

### Modifier la règle d'un groupe dynamique

```powershell
$groupId = "GROUP-ID"
$newRule = "(user.department -eq ""Engineering"") -and (user.accountEnabled -eq true)"

Update-MgGroup -GroupId $groupId -MembershipRule $newRule

Write-Host "✓ Règle d'adhésion mise à jour" -ForegroundColor Green
```

---

## 📊 Statistiques et rapports

### Rapport sur tous les groupes

```powershell
function Get-GroupsReport {
    Write-Host "Génération du rapport des groupes..." -ForegroundColor Cyan
    
    $groups = Get-MgGroup -All
    
    $report = foreach ($group in $groups) {
        $members = Get-MgGroupMember -GroupId $group.Id
        $owners = Get-MgGroupOwner -GroupId $group.Id
        
        [PSCustomObject]@{
            DisplayName = $group.DisplayName
            Type = if ($group.SecurityEnabled) { "Sécurité" } else { "M365" }
            MembersCount = $members.Count
            OwnersCount = $owners.Count
            Description = $group.Description
            CreatedDateTime = $group.CreatedDateTime
        }
    }
    
    # Afficher
    $report | Format-Table -AutoSize
    
    # Exporter
    $report | Export-Csv -Path "./reports/groups-report-$(Get-Date -Format 'yyyyMMdd').csv" `
        -NoTypeInformation -Encoding UTF8
    
    Write-Host "`n✓ Rapport exporté" -ForegroundColor Green
    
    # Statistiques
    Write-Host "`n=== Statistiques ===" -ForegroundColor Cyan
    Write-Host "Total groupes : $($groups.Count)" -ForegroundColor Yellow
    Write-Host "Groupes de sécurité : $(($groups | Where-Object {$_.SecurityEnabled}).Count)" -ForegroundColor Green
    Write-Host "Groupes M365 : $(($groups | Where-Object {$_.GroupTypes -contains 'Unified'}).Count)" -ForegroundColor Green
}

Get-GroupsReport
```

### Trouver les groupes vides

```powershell
function Get-EmptyGroups {
    Write-Host "Recherche des groupes vides..." -ForegroundColor Cyan
    
    $groups = Get-MgGroup -All
    $emptyGroups = @()
    
    foreach ($group in $groups) {
        $members = Get-MgGroupMember -GroupId $group.Id
        
        if ($members.Count -eq 0) {
            $emptyGroups += [PSCustomObject]@{
                DisplayName = $group.DisplayName
                Id = $group.Id
                CreatedDateTime = $group.CreatedDateTime
            }
        }
    }
    
    Write-Host "`nGroupes vides trouvés : $($emptyGroups.Count)" -ForegroundColor Yellow
    $emptyGroups | Format-Table
    
    return $emptyGroups
}

Get-EmptyGroups
```

---

## 🔐 Groupes et sécurité

### Assigner un groupe à une application

```powershell
# Assigner un groupe à une application pour SSO
$servicePrincipalId = "APP-SERVICE-PRINCIPAL-ID"
$groupId = "GROUP-ID"

New-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $servicePrincipalId `
    -BodyParameter @{
        PrincipalId = $groupId
        ResourceId = $servicePrincipalId
        AppRoleId = "00000000-0000-0000-0000-000000000000"  # Default access
    }

Write-Host "✓ Groupe assigné à l'application" -ForegroundColor Green
```

### Utiliser un groupe dans une politique d'accès conditionnel

```powershell
# Créer une politique pour un groupe spécifique
$policyParams = @{
    DisplayName = "MFA pour Équipe d'Ingénierie"
    State = "enabled"
    Conditions = @{
        Users = @{
            IncludeGroups = @("GROUP-ID")
        }
        Applications = @{
            IncludeApplications = @("All")
        }
    }
    GrantControls = @{
        Operator = "OR"
        BuiltInControls = @("mfa")
    }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $policyParams

Write-Host "✓ Politique créée pour le groupe" -ForegroundColor Green
```

---

## 📝 Scripts complets

### Script : Créer la structure organisationnelle complète

```powershell
<#
.SYNOPSIS
    Crée toute la structure de groupes de l'USS Enterprise
#>

function Initialize-EnterpriseGroupStructure {
    Write-Host "`n=== Création de la structure de groupes USS Enterprise ===" -ForegroundColor Cyan
    
    # Se connecter
    Connect-MgGraph -Scopes "Group.ReadWrite.All"
    
    # Définir la hiérarchie
    $structure = @{
        "Tier 0 - Administration" = @(
            @{Name="Global Administrators"; Desc="Administrateurs globaux du tenant"}
            @{Name="Security Administrators"; Desc="Administrateurs de sécurité"}
        )
        "Tier 1 - Opérationnel" = @(
            @{Name="Équipe de Commandement"; Desc="Capitaine et officiers de commandement"}
            @{Name="Équipe d'Exploration"; Desc="Membres des missions d'exploration"}
            @{Name="Équipe Médicale"; Desc="Personnel médical"}
            @{Name="Équipe d'Ingénierie"; Desc="Ingénieurs et techniciens"}
            @{Name="Équipe Scientifique"; Desc="Scientifiques et analystes"}
            @{Name="Équipe de Sécurité"; Desc="Personnel de sécurité"}
        )
        "Tier 2 - Support" = @(
            @{Name="Officiers Supérieurs"; Desc="Tous les officiers de rang supérieur"}
            @{Name="Personnel Technique"; Desc="Support technique"}
        )
    }
    
    $allGroups = @{}
    
    foreach ($tier in $structure.Keys) {
        Write-Host "`n[$tier]" -ForegroundColor Yellow
        
        foreach ($groupDef in $structure[$tier]) {
            $group = New-EnterpriseTeam -TeamName $groupDef.Name `
                -Description $groupDef.Desc `
                -Type "Security"
            
            $allGroups[$groupDef.Name] = $group
            Start-Sleep -Milliseconds 500
        }
    }
    
    # Sauvegarder
    $groupsJson = @{}
    foreach ($key in $allGroups.Keys) {
        $groupsJson[$key] = @{
            Id = $allGroups[$key].Id
            DisplayName = $allGroups[$key].DisplayName
        }
    }
    
    $groupsJson | ConvertTo-Json | Out-File "./config/groups.json" -Encoding UTF8
    
    Write-Host "`n✓ Structure complète créée et sauvegardée" -ForegroundColor Green
    Write-Host "  Total groupes : $($allGroups.Count)" -ForegroundColor Cyan
}

Initialize-EnterpriseGroupStructure
```

---

## 🎯 Résumé des commandes essentielles

| Action | Commande |
|--------|----------|
| **Lister les groupes** | `Get-MgGroup` |
| **Chercher un groupe** | `Get-MgGroup -Filter "displayName eq 'Name'"` |
| **Créer un groupe sécurité** | `New-MgGroup -DisplayName "Name" -SecurityEnabled` |
| **Créer un groupe M365** | `New-MgGroup -DisplayName "Name" -GroupTypes @("Unified")` |
| **Ajouter un membre** | `New-MgGroupMember -GroupId "id" -DirectoryObjectId "userId"` |
| **Lister les membres** | `Get-MgGroupMember -GroupId "id"` |
| **Retirer un membre** | `Remove-MgGroupMemberByRef -GroupId "id" -DirectoryObjectId "userId"` |
| **Modifier un groupe** | `Update-MgGroup -GroupId "id" -DisplayName "NewName"` |
| **Supprimer un groupe** | `Remove-MgGroup -GroupId "id"` |

---

## ⚠️ Bonnes pratiques

### ✅ À FAIRE
- Nommer les groupes de manière cohérente et descriptive
- Documenter la raison d'être de chaque groupe
- Utiliser des groupes pour gérer les permissions plutôt que des utilisateurs individuels
- Définir des propriétaires pour chaque groupe
- Revoir régulièrement les membres des groupes
- Utiliser des groupes dynamiques quand c'est pertinent

### ❌ À ÉVITER
- Créer trop de groupes (complexité)
- Utiliser des groupes de distribution pour la sécurité
- Oublier de définir des propriétaires
- Laisser des groupes vides
- Ne pas documenter les groupes
- Imbriquer trop de groupes (maximum 3 niveaux)

---

## 📚 Ressources complémentaires

- [Microsoft Graph Group API](https://learn.microsoft.com/en-us/graph/api/resources/group)
- [Groupes dynamiques](https://learn.microsoft.com/en-us/azure/active-directory/enterprise-users/groups-dynamic-membership)
- [Règles d'adhésion](https://learn.microsoft.com/en-us/azure/active-directory/enterprise-users/groups-dynamic-membership-rule-syntax)

---

**Date de création** : Novembre 2024  
**Version** : 1.0  
**Projet** : USS Enterprise - Entra ID Security