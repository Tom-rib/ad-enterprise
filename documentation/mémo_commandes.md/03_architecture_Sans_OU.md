# Guide 03 - Unités d'Organisation (OU) et Azure AD

## ⚠️ IMPORTANT : Pas d'OU dans Azure AD / Entra ID

### Différence fondamentale

**Azure AD / Entra ID** est **différent** d'Active Directory traditionnel (AD DS) :

| Concept | Active Directory (AD DS) | Azure AD / Entra ID |
|---------|-------------------------|---------------------|
| **Unités d'Organisation (OU)** | ✅ Existe | ❌ N'existe PAS |
| **Groupes** | ✅ Existe | ✅ Existe |
| **Groupes de sécurité** | ✅ Existe | ✅ Existe |
| **GPO (Group Policy)** | ✅ Existe | ❌ N'existe PAS |
| **Structure hiérarchique** | ✅ OU imbriquées | ❌ Flat structure |

---

## 📚 Pourquoi pas d'OU dans Azure AD ?

### Azure AD est un annuaire cloud plat

Azure AD / Entra ID utilise une **architecture plate** (flat structure) plutôt qu'une structure hiérarchique :

- **Pas de conteneurs hiérarchiques** : Tous les objets (utilisateurs, groupes) sont au même niveau
- **Organisation par groupes** : L'organisation se fait via des groupes de sécurité
- **Attributs au lieu de conteneurs** : On utilise des attributs (département, titre, etc.) pour classifier
- **Politiques basées sur les groupes** : Au lieu des GPO, on utilise des politiques d'accès conditionnel

---

## 🔄 Comment organiser dans Azure AD ?

### 1. **Utiliser les Groupes** (Recommandé ✅)

Au lieu d'OU, créez des groupes pour organiser vos utilisateurs :

```powershell
# Au lieu d'une OU "Engineering"
# Créer un groupe "Équipe d'Ingénierie"
New-MgGroup -DisplayName "Équipe d'Ingénierie" `
    -Description "Tous les ingénieurs" `
    -MailEnabled:$false `
    -SecurityEnabled:$true `
    -MailNickname "engineering-team"
```

### 2. **Utiliser les Attributs** pour la classification

Utilisez les propriétés des utilisateurs pour les organiser :

```powershell
# Classifier par département
Update-MgUser -UserId "user@domain.com" `
    -Department "Engineering" `
    -CompanyName "USS Enterprise" `
    -OfficeLocation "Bridge"

# Attributs disponibles :
# - Department
# - JobTitle
# - CompanyName
# - OfficeLocation
# - EmployeeId
# - EmployeeType
# - City, State, Country
```

### 3. **Utiliser les Groupes Dynamiques**

Créez des groupes qui se peuplent automatiquement selon des règles :

```powershell
# Groupe dynamique basé sur le département
New-MgGroup -DisplayName "Tous les Ingénieurs (Dynamique)" `
    -Description "Tous les utilisateurs du département Engineering" `
    -MailEnabled:$false `
    -SecurityEnabled:$true `
    -MailNickname "all-engineers-dynamic" `
    -GroupTypes @("DynamicMembership") `
    -MembershipRule "(user.department -eq ""Engineering"")" `
    -MembershipRuleProcessingState "On"
```

### 4. **Utiliser les Unités Administratives (Administrative Units)**

Les **Unités Administratives** sont la fonctionnalité la plus proche des OU dans Azure AD :

```powershell
# Créer une unité administrative
$au = New-MgDirectoryAdministrativeUnit -DisplayName "Engineering Division" `
    -Description "Unité pour le département Engineering"

# Ajouter des utilisateurs
$user = Get-MgUser -Filter "department eq 'Engineering'"
New-MgDirectoryAdministrativeUnitMemberByRef -AdministrativeUnitId $au.Id `
    -BodyParameter @{ "@odata.id" = "https://graph.microsoft.com/v1.0/users/$($user.Id)" }

# Assigner un administrateur à l'unité
# Cet admin ne peut gérer QUE les utilisateurs de cette unité
```

---

## 🏗️ Structure organisationnelle recommandée pour USS Enterprise

### Modèle avec Groupes (Recommandé)

```
USS Enterprise (Tenant)
│
├── 📁 Tier 0 - Administration
│   ├── Global Administrators (Groupe)
│   └── Security Administrators (Groupe)
│
├── 📁 Tier 1 - Opérationnel
│   ├── Équipe de Commandement (Groupe)
│   ├── Équipe d'Exploration (Groupe)
│   ├── Équipe Médicale (Groupe)
│   ├── Équipe d'Ingénierie (Groupe)
│   └── Équipe Scientifique (Groupe)
│
└── 📁 Tier 2 - Support
    ├── Officiers Supérieurs (Groupe)
    └── Personnel Technique (Groupe)
```

### Script de création de la structure

```powershell
function Initialize-EnterpriseStructure {
    Write-Host "Création de la structure organisationnelle USS Enterprise..." -ForegroundColor Cyan
    
    $structure = @{
        "Tier 0 - Administration" = @(
            "Global Administrators",
            "Security Administrators"
        )
        "Tier 1 - Opérationnel" = @(
            "Équipe de Commandement",
            "Équipe d'Exploration",
            "Équipe Médicale",
            "Équipe d'Ingénierie",
            "Équipe Scientifique"
        )
        "Tier 2 - Support" = @(
            "Officiers Supérieurs",
            "Personnel Technique"
        )
    }
    
    foreach ($tier in $structure.Keys) {
        Write-Host "`n[$tier]" -ForegroundColor Yellow
        
        foreach ($groupName in $structure[$tier]) {
            $mailNickname = ($groupName -replace '[^a-zA-Z0-9]', '').ToLower()
            
            New-MgGroup -DisplayName $groupName `
                -Description "Groupe $tier - $groupName" `
                -MailEnabled:$false `
                -SecurityEnabled:$true `
                -MailNickname $mailNickname
            
            Write-Host "  ✓ Créé : $groupName" -ForegroundColor Green
        }
    }
}

Initialize-EnterpriseStructure
```

---

## 🔐 Appliquer des politiques sans GPO

### Dans Azure AD, utilisez :

#### 1. **Politiques d'Accès Conditionnel**

Au lieu des GPO, utilisez l'accès conditionnel :

```powershell
# Politique pour un groupe spécifique
$policy = @{
    DisplayName = "MFA pour Équipe d'Ingénierie"
    State = "enabled"
    Conditions = @{
        Users = @{
            IncludeGroups = @("GROUP-ID-ENGINEERING")
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

New-MgIdentityConditionalAccessPolicy -BodyParameter $policy
```

#### 2. **Politiques de Conformité des Appareils**

Pour gérer les appareils (comme les GPO de sécurité) :

- Configuration via Microsoft Endpoint Manager / Intune
- Politiques de conformité
- Profils de configuration

#### 3. **Politiques de Protection des Applications**

Pour les applications mobiles et cloud :

- Protection des données
- Restriction de copier/coller
- Chiffrement

---

## 📋 Tableau de correspondance AD DS ↔ Azure AD

| Besoin | AD DS (On-Premises) | Azure AD / Entra ID |
|--------|---------------------|---------------------|
| **Organiser les utilisateurs** | OU | Groupes + Attributs |
| **Appliquer des politiques** | GPO | Accès Conditionnel |
| **Déléguer l'administration** | Délégation sur OU | Unités Administratives + Rôles |
| **Structure hiérarchique** | OU imbriquées | Groupes imbriqués |
| **Filtrage et recherche** | Par OU | Par attributs/groupes |
| **Gestion des appareils** | GPO | Intune / Endpoint Manager |

---

## 🎯 Bonnes pratiques d'organisation Azure AD

### ✅ À FAIRE

1. **Utiliser les groupes comme base d'organisation**
   ```powershell
   # Créer des groupes logiques
   New-MgGroup -DisplayName "Engineering - Warp Drive Team"
   New-MgGroup -DisplayName "Engineering - Systems Team"
   ```

2. **Renseigner les attributs utilisateurs**
   ```powershell
   Update-MgUser -UserId "user@domain.com" `
       -Department "Engineering" `
       -JobTitle "Chief Engineer" `
       -OfficeLocation "Engineering Deck"
   ```

3. **Utiliser des groupes dynamiques**
   ```powershell
   # Auto-population basée sur les règles
   New-MgGroup -GroupTypes @("DynamicMembership") `
       -MembershipRule "(user.department -eq ""Engineering"")"
   ```

4. **Nommer de manière cohérente**
   ```
   Format : [Département] - [Fonction] - [Type]
   Exemple : "Engineering - Warp Drive - Project Team"
   ```

5. **Documenter la structure**
   ```json
   {
     "groups": {
       "engineering": {
         "purpose": "Ingénieurs du vaisseau",
         "owner": "Montgomery Scott",
         "members_count": 45
       }
     }
   }
   ```

### ❌ À ÉVITER

1. ❌ Chercher à recréer une structure OU dans Azure AD
2. ❌ Créer trop de niveaux de groupes imbriqués (max 3)
3. ❌ Ne pas renseigner les attributs utilisateurs
4. ❌ Créer des groupes sans propriétaire défini
5. ❌ Oublier de documenter la logique d'organisation

---

## 🔄 Migration d'AD DS vers Azure AD

### Si vous migrez depuis AD traditionnel :

```powershell
# 1. Mapper vos OU vers des groupes
$ouMapping = @{
    "OU=Engineering,DC=company,DC=com" = "Équipe d'Ingénierie"
    "OU=Medical,DC=company,DC=com" = "Équipe Médicale"
}

# 2. Créer les groupes correspondants
foreach ($ou in $ouMapping.Keys) {
    $groupName = $ouMapping[$ou]
    New-MgGroup -DisplayName $groupName `
        -MailEnabled:$false `
        -SecurityEnabled:$true `
        -MailNickname ($groupName -replace '\s', '').ToLower()
}

# 3. Azure AD Connect synchronisera automatiquement
# les utilisateurs et groupes
```

---

## 📝 Exemple complet : Organiser USS Enterprise

```powershell
<#
.SYNOPSIS
    Organisation complète du tenant USS Enterprise sans OU
#>

function Initialize-EnterpriseOrganization {
    Write-Host "`n=== Organisation USS Enterprise (Sans OU) ===" -ForegroundColor Cyan
    
    # 1. Créer les groupes principaux
    $groups = @{
        "Command" = "Équipe de Commandement"
        "Engineering" = "Équipe d'Ingénierie"
        "Medical" = "Équipe Médicale"
        "Science" = "Équipe Scientifique"
        "Security" = "Équipe de Sécurité"
    }
    
    Write-Host "`n[Création des groupes]" -ForegroundColor Yellow
    foreach ($key in $groups.Keys) {
        $groupName = $groups[$key]
        $group = New-MgGroup -DisplayName $groupName `
            -Description "Département $key" `
            -MailEnabled:$false `
            -SecurityEnabled:$true `
            -MailNickname $key.ToLower()
        
        Write-Host "✓ $groupName" -ForegroundColor Green
    }
    
    # 2. Configurer les attributs des utilisateurs existants
    Write-Host "`n[Configuration des attributs utilisateurs]" -ForegroundColor Yellow
    
    $users = @(
        @{Email="james.kirk@uss-enterprise.com"; Dept="Command"; Title="Captain"},
        @{Email="montgomery.scott@uss-enterprise.com"; Dept="Engineering"; Title="Chief Engineer"},
        @{Email="leonard.mccoy@uss-enterprise.com"; Dept="Medical"; Title="Chief Medical Officer"}
    )
    
    foreach ($userData in $users) {
        $user = Get-MgUser -Filter "userPrincipalName eq '$($userData.Email)'"
        if ($user) {
            Update-MgUser -UserId $user.Id `
                -Department $userData.Dept `
                -JobTitle $userData.Title `
                -CompanyName "USS Enterprise"
            
            Write-Host "✓ $($user.DisplayName) → $($userData.Dept)" -ForegroundColor Green
        }
    }
    
    # 3. Créer un groupe dynamique par département
    Write-Host "`n[Création des groupes dynamiques]" -ForegroundColor Yellow
    
    foreach ($dept in @("Command", "Engineering", "Medical", "Science")) {
        $dynamicGroup = New-MgGroup `
            -DisplayName "Tous $dept (Dynamique)" `
            -Description "Tous les membres du département $dept" `
            -MailEnabled:$false `
            -SecurityEnabled:$true `
            -MailNickname "all-$($dept.ToLower())-dynamic" `
            -GroupTypes @("DynamicMembership") `
            -MembershipRule "(user.department -eq ""$dept"")" `
            -MembershipRuleProcessingState "On"
        
        Write-Host "✓ Groupe dynamique : $dept" -ForegroundColor Green
    }
    
    Write-Host "`n✓ Organisation complète terminée!" -ForegroundColor Green
    Write-Host "  Structure basée sur : Groupes + Attributs + Groupes Dynamiques" -ForegroundColor Cyan
}

Initialize-EnterpriseOrganization
```

---

## 🎯 Résumé

### ❌ Ce qui N'EXISTE PAS dans Azure AD
- Unités d'Organisation (OU)
- Structure hiérarchique OU
- Group Policy Objects (GPO)
- Conteneurs AD traditionnels

### ✅ Alternatives dans Azure AD
- **Groupes** (Security Groups, M365 Groups)
- **Attributs utilisateurs** (Department, JobTitle, etc.)
- **Groupes dynamiques** (basés sur des règles)
- **Unités Administratives** (pour délégation)
- **Accès Conditionnel** (remplace GPO)
- **Politiques de conformité** (via Intune)

---

## 📚 Ressources complémentaires

- [Azure AD vs AD DS](https://learn.microsoft.com/en-us/azure/active-directory/fundamentals/active-directory-compare-azure-ad-to-ad)
- [Unités Administratives](https://learn.microsoft.com/en-us/azure/active-directory/roles/administrative-units)
- [Groupes dynamiques](https://learn.microsoft.com/en-us/azure/active-directory/enterprise-users/groups-dynamic-membership)
- [Accès Conditionnel](https://learn.microsoft.com/en-us/azure/active-directory/conditional-access/)

---

**Date de création** : Novembre 2024  
**Version** : 1.0  
**Projet** : USS Enterprise - Entra ID Security