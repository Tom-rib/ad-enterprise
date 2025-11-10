# 📚 INDEX - Parcours Complet USS Enterprise

## 🎯 Parcours dans le BON ORDRE LOGIQUE

Suivez cet ordre pour créer votre infrastructure USS Enterprise du début à la fin.

**Temps total : 7h30**

---

## 📋 RÉSUMÉ - Ordre complet

```
01. Créer le tenant (1h) ← COMMENCER ICI !
    ↓
02. Se connecter PowerShell (30 min)
    ↓
03. Comprendre l'architecture (20 min - lecture)
    ↓
04. Créer les utilisateurs (1h)
    ↓
05. Créer les groupes (1h)
    ↓
06. Assigner les rôles (1h)
    ↓
07. Configurer la sécurité (2h)
    ↓
INFRASTRUCTURE COMPLÈTE ! 🎉
```

---

## 🏢 ÉTAPE 1 : CRÉER LE TENANT (1h)

### [Guide 01 - Création du Tenant](./01-Creation-Tenant.md)
**➡️ COMMENCEZ ICI - Obligatoire avant tout !**

#### Ce que vous allez faire
- Créer un tenant avec Azure for Students (gratuit, pas de CB)
- Ou avec M365 Developer Program (gratuit)
- Configurer les informations de base du tenant
- Créer le compte d'urgence (Break Glass)
- Activer Azure AD Premium P2 (essai 30 jours)
- Initialiser la structure de base

#### Scripts clés
```powershell
# Après création via portail web
Initialize-USSEnterpriseTenant
```

#### Résultat
✅ Tenant "USS Enterprise" créé et configuré  
✅ Compte d'urgence sécurisé  
✅ Structure de base initialisée

#### ➡️ Ensuite : Guide 02

---

## 🔌 ÉTAPE 2 : SE CONNECTER (30 min)

### [Guide 02 - Connexion PowerShell](./02-Connexion-PowerShell.md)
**Installer PowerShell et se connecter au tenant**

#### Ce que vous allez faire
- Installer PowerShell 7+
- Installer les modules Microsoft.Graph
- Se connecter au tenant créé à l'étape 1
- Tester la connexion
- Comprendre les scopes et permissions

#### Commandes clés
```powershell
# Installation
Install-Module -Name Microsoft.Graph -Force

# Connexion
Connect-MgGraph -Scopes "User.ReadWrite.All", "Group.ReadWrite.All", "Directory.ReadWrite.All"

# Vérification
Get-MgContext
Get-MgOrganization
```

#### Résultat
✅ PowerShell 7+ installé  
✅ Modules Graph installés  
✅ Connecté au tenant

#### ➡️ Ensuite : Guide 03

---

## 📐 ÉTAPE 3 : COMPRENDRE L'ARCHITECTURE (20 min)

### [Guide 03 - Architecture Sans OU](./03-Architecture-Sans-OU.md)
**⚠️ IMPORTANT : Pas d'OU dans Azure AD !**

#### Ce que vous allez apprendre
- ⚠️ Il n'y a PAS d'Unités d'Organisation (OU) dans Azure AD
- Comment organiser SANS hiérarchie OU
- Utiliser les groupes pour organiser
- Utiliser les attributs pour classifier
- Créer des groupes dynamiques

#### Concepts clés
```
Azure AD ≠ Active Directory traditionnel

Pas d'OU → Utiliser des GROUPES
Pas de GPO → Utiliser ACCÈS CONDITIONNEL
Structure PLATE → Pas de hiérarchie
```

#### Résultat
✅ Compréhension de l'architecture Azure AD  
✅ Stratégie d'organisation définie

#### ➡️ Ensuite : Guide 04

---

## 👤 ÉTAPE 4 : CRÉER LES UTILISATEURS (1h)

### [Guide 04 - Gestion des Utilisateurs](./04-Gestion-Utilisateurs.md)
**Créer les membres d'équipage**

#### Ce que vous allez faire
- Créer les utilisateurs principaux (Kirk, Spock, McCoy, Scott)
- Configurer leurs propriétés (département, titre)
- Générer des mots de passe sécurisés
- Automatiser la création en masse

#### Scripts clés
```powershell
# Créer un utilisateur
New-EnterpriseCrewMember -FirstName "James" -LastName "Kirk" `
    -Rank "Captain" -Department "Command"

# Créer plusieurs utilisateurs
$crew = @(
    @{First="James"; Last="Kirk"; Rank="Captain"; Dept="Command"},
    @{First="Spock"; Last=""; Rank="Commander"; Dept="Science"},
    @{First="Leonard"; Last="McCoy"; Rank="Doctor"; Dept="Medical"},
    @{First="Montgomery"; Last="Scott"; Rank="Commander"; Dept="Engineering"}
)

foreach ($member in $crew) {
    New-EnterpriseCrewMember @member
}
```

#### Résultat
✅ 4+ utilisateurs créés :
- Captain James Kirk (Command)
- Commander Spock (Science)
- Dr. Leonard McCoy (Medical)
- Commander Montgomery Scott (Engineering)

#### ➡️ Ensuite : Guide 05

---

## 👥 ÉTAPE 5 : CRÉER LES GROUPES (1h)

### [Guide 05 - Gestion des Groupes](./05-Gestion-Groupes.md)
**Organiser la structure en équipes**

#### Ce que vous allez faire
- Créer les groupes de sécurité
- Organiser selon le modèle Tier (0, 1, 2)
- Ajouter les membres aux groupes appropriés
- Créer des groupes dynamiques (optionnel)

#### Scripts clés
```powershell
# Créer la structure complète
Initialize-EnterpriseGroupStructure

# Ou créer manuellement
New-MgGroup -DisplayName "Command Team" `
    -SecurityEnabled:$true `
    -MailNickname "command"

# Ajouter des membres
New-MgGroupMember -GroupId $groupId -DirectoryObjectId $userId
```

#### Structure créée
```
Tier 0 - Administration
├── Global Administrators
└── Security Administrators

Tier 1 - Opérationnel
├── Command Team
├── Engineering Team
├── Medical Team
└── Science Team

Tier 2 - Support
├── Senior Officers
└── Technical Support
```

#### Résultat
✅ 6+ groupes créés  
✅ Utilisateurs organisés par équipe

#### ➡️ Ensuite : Guide 06

---

## 🎭 ÉTAPE 6 : ASSIGNER LES RÔLES (1h)

### [Guide 06 - Gestion des Rôles](./06-Gestion-Roles.md)
**Déléguer les permissions administratives**

#### Ce que vous allez faire
- Comprendre les rôles Azure AD
- Assigner des rôles aux administrateurs
- Créer des rôles d'application personnalisés
- Auditer les accès privilégiés

#### Scripts clés
```powershell
# Assigner un rôle
Add-EnterpriseRoleAssignment -UserEmail "james.kirk@domain.com" `
    -RoleName "Global Administrator"

# Configuration complète
# Kirk → Global Administrator
# Spock → Security Administrator
# McCoy → User Administrator
# Scott → Groups Administrator
```

#### Résultat
✅ Rôles administratifs assignés  
✅ Principe du moindre privilège respecté  
✅ Maximum 2-3 Global Administrators

#### ➡️ Ensuite : Guide 07

---

## 🔐 ÉTAPE 7 : CONFIGURER LA SÉCURITÉ (2h)

### [Guide 07 - Sécurité MFA et Accès Conditionnel](./07-Securite-MFA-ConditionalAccess.md)
**Implémenter la sécurité Zero Trust**

#### Ce que vous allez faire
- Activer MFA pour les administrateurs
- Activer MFA pour les officiers supérieurs
- Créer des emplacements nommés (France, USA)
- Bloquer les connexions non autorisées
- Exiger des appareils conformes
- Bloquer l'authentification héritée

#### Scripts clés
```powershell
# Configuration sécurité complète
$emergencyAccountId = "VOTRE-EMERGENCY-ACCOUNT-ID"
Initialize-EnterpriseSecurityPolicies -EmergencyAccountId $emergencyAccountId
```

#### Politiques créées
1. ✅ MFA obligatoire pour administrateurs
2. ✅ Blocage géographique (sauf FR et US)
3. ✅ Appareils conformes requis
4. ✅ Authentification héritée bloquée
5. ✅ MFA depuis emplacements non approuvés

#### Résultat
✅ Infrastructure sécurisée Zero Trust  
✅ MFA activé  
✅ Politiques d'accès conditionnel actives

---

## ✅ CHECKLIST COMPLÈTE

### □ Étape 1 : Tenant (1h)
- [ ] Tenant créé via Azure for Students ou M365 Dev
- [ ] Compte d'urgence créé et sauvegardé
- [ ] Azure AD Premium P2 activé
- [ ] Configuration initiale terminée

### □ Étape 2 : Connexion (30 min)
- [ ] PowerShell 7+ installé
- [ ] Module Microsoft.Graph installé
- [ ] Connexion testée avec `Get-MgContext`
- [ ] Scopes vérifiés

### □ Étape 3 : Architecture (20 min)
- [ ] Guide lu et compris
- [ ] Concept "pas d'OU" assimilé
- [ ] Stratégie d'organisation définie

### □ Étape 4 : Utilisateurs (1h)
- [ ] Kirk, Spock, McCoy, Scott créés
- [ ] Propriétés configurées
- [ ] Mots de passe distribués
- [ ] Vérification avec `Get-MgUser`

### □ Étape 5 : Groupes (1h)
- [ ] Structure Tier 0, 1, 2 créée
- [ ] Utilisateurs ajoutés aux groupes
- [ ] Vérification avec `Get-MgGroup`

### □ Étape 6 : Rôles (1h)
- [ ] Rôles administratifs assignés
- [ ] Maximum 2-3 Global Admins
- [ ] Audit effectué

### □ Étape 7 : Sécurité (2h)
- [ ] MFA activé pour admins
- [ ] Emplacements nommés créés
- [ ] 5 politiques de sécurité créées
- [ ] Tests avec What-If effectués
- [ ] Compte d'urgence exclu de TOUTES les politiques

---

## 📊 TEMPS TOTAL PAR PHASE

| Étape | Guide | Temps |
|-------|-------|-------|
| 1 | Créer tenant | 1h |
| 2 | Se connecter | 30 min |
| 3 | Comprendre architecture | 20 min |
| 4 | Créer utilisateurs | 1h |
| 5 | Créer groupes | 1h |
| 6 | Assigner rôles | 1h |
| 7 | Configurer sécurité | 2h |
| **TOTAL** | | **7h30** |

---

## 💡 CONSEILS IMPORTANTS

### ⚠️ ORDRE CRITIQUE
1. **Le tenant DOIT être créé EN PREMIER** (Guide 01)
2. Vous ne pouvez rien faire sans tenant
3. Suivez l'ordre exact : 01 → 02 → 03 → 04 → 05 → 06 → 07

### ✅ À FAIRE
- Créer le tenant AVANT TOUT (Guide 01)
- Tester chaque étape avant de passer à la suivante
- Sauvegarder le compte d'urgence immédiatement
- Utiliser Azure for Students (gratuit)
- Vérifier après chaque commande

### ❌ À ÉVITER
- Essayer de se connecter sans avoir créé le tenant
- Sauter l'étape de création du tenant
- Oublier de sauvegarder le compte d'urgence
- Tester en production
- Ignorer le Guide 03 (architecture)

---

## 🆘 PROBLÈMES COURANTS

| Problème | Cause | Solution |
|----------|-------|----------|
| "Tenant not found" | Pas de tenant créé | Faire le Guide 01 d'abord |
| "Insufficient privileges" | Pas assez de scopes | Reconnecter avec plus de scopes |
| "User already exists" | Utilisateur existe déjà | Changer le nom ou vérifier |
| Module non trouvé | Pas installé | `Install-Module Microsoft.Graph` |

---

## 🎯 COMMANDES DE VÉRIFICATION

```powershell
# Après chaque étape, vérifier :

# Étape 1 : Tenant créé ?
Get-MgOrganization | Select-Object DisplayName, Id

# Étape 2 : Connecté ?
Get-MgContext

# Étape 4 : Utilisateurs créés ?
Get-MgUser | Select-Object DisplayName, Department

# Étape 5 : Groupes créés ?
Get-MgGroup | Select-Object DisplayName

# Étape 6 : Rôles assignés ?
Get-MgDirectoryRole

# Étape 7 : Politiques actives ?
Get-MgIdentityConditionalAccessPolicy | Select-Object DisplayName, State
```

---

## 🎉 INFRASTRUCTURE COMPLÈTE

À la fin du parcours, vous aurez :

✅ 1 Tenant Azure AD configuré  
✅ 1 Compte d'urgence sécurisé  
✅ 4+ utilisateurs (Kirk, Spock, McCoy, Scott)  
✅ 6+ groupes organisationnels  
✅ Rôles administratifs assignés  
✅ MFA activé  
✅ 5+ politiques de sécurité  
✅ Blocage géographique configuré  
✅ Infrastructure Zero Trust complète

---

## 📚 RESSOURCES

- [Azure for Students](https://azure.microsoft.com/fr-fr/free/students/)
- [M365 Developer Program](https://developer.microsoft.com/microsoft-365/dev-program)
- [Microsoft Graph](https://learn.microsoft.com/graph/)
- [Azure AD Documentation](https://learn.microsoft.com/azure/active-directory/)

---

## 🚀 COMMENCER MAINTENANT

**[➡️ Ouvrir le Guide 01 - Création du Tenant](./01-Creation-Tenant.md)**

---

**Projet** : USS Enterprise - Entra ID Security  
**Parcours** : 7 étapes - 7h30  
**Version** : 6.0 - Ordre Logique  
**Date** : Novembre 2024

*"To boldly go where no one has gone before..."* 🚀