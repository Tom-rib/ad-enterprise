# Guide 02 - Connexion à Entra ID / Azure AD

## 📚 À quoi ça sert ?

La connexion à Entra ID (anciennement Azure AD) est la première étape obligatoire pour administrer votre tenant Azure AD. C'est comme ouvrir une session pour accéder à votre infrastructure cloud.

### Pourquoi se connecter ?
- **Authentification** : Prouver votre identité auprès d'Azure
- **Autorisation** : Obtenir les permissions nécessaires pour effectuer des actions
- **Sécurité** : Établir une session sécurisée pour toutes vos opérations

---

## 🔧 Modules PowerShell disponibles

Il existe **trois modules principaux** pour gérer Entra ID :

### 1. **AzureAD** (Legacy - Obsolète)
```powershell
# Installation
Install-Module -Name AzureAD -Force -Scope CurrentUser

# Connexion
Connect-AzureAD
```

**⚠️ Important** : Ce module est obsolète et sera déprécié. Microsoft recommande d'utiliser Microsoft Graph.

### 2. **Microsoft Graph** (Recommandé ✅)
```powershell
# Installation
Install-Module -Name Microsoft.Graph -Force -Scope CurrentUser

# Connexion
Connect-MgGraph
```

**✅ Avantages** :
- Module moderne et maintenu par Microsoft
- API unifiée pour tous les services Microsoft 365
- Plus de fonctionnalités et meilleures performances
- Compatible avec les futures mises à jour

### 3. **Azure CLI**
```bash
# Installation (Windows)
winget install -e --id Microsoft.AzureCLI

# Connexion
az login
az ad user list
```

---

## 🚀 Connexion avec Microsoft Graph (Méthode recommandée)

### Connexion simple (interactive)

```powershell
# Connexion de base
Connect-MgGraph

# Vous serez redirigé vers une page web pour vous authentifier
```

### Connexion avec des permissions spécifiques (Scopes)

```powershell
# Connexion avec des scopes spécifiques
Connect-MgGraph -Scopes "User.ReadWrite.All", "Group.ReadWrite.All"
```

**💡 Qu'est-ce qu'un Scope ?**
Un scope est une permission spécifique que vous demandez. Par exemple :
- `User.Read.All` : Lire les informations des utilisateurs
- `User.ReadWrite.All` : Lire ET modifier les utilisateurs
- `Group.ReadWrite.All` : Gérer les groupes
- `Directory.ReadWrite.All` : Accès complet au répertoire

### Connexion avec toutes les permissions nécessaires pour le projet

```powershell
# Connexion complète pour l'administration
Connect-MgGraph -Scopes @(
    "User.ReadWrite.All",           # Gestion des utilisateurs
    "Group.ReadWrite.All",          # Gestion des groupes
    "Directory.ReadWrite.All",      # Accès complet au répertoire
    "Policy.ReadWrite.ConditionalAccess", # Politiques d'accès conditionnel
    "Application.ReadWrite.All",    # Gestion des applications
    "AuditLog.Read.All",           # Lecture des logs d'audit
    "RoleManagement.ReadWrite.Directory" # Gestion des rôles
)
```

---

## 📋 Commandes de base après connexion

### Vérifier la connexion

```powershell
# Obtenir le contexte de connexion actuel
Get-MgContext

# Résultat attendu :
# ClientId              : ...
# TenantId              : ...
# Scopes                : {User.ReadWrite.All, Group.ReadWrite.All, ...}
# AuthType              : Delegated
# CertificateThumbprint : 
# Account               : votre.email@domaine.com
```

### Obtenir les informations du tenant

```powershell
# Obtenir les détails de votre organisation/tenant
Get-MgOrganization

# Affichage formaté
Get-MgOrganization | Select-Object DisplayName, Id, VerifiedDomains
```

**Exemple de résultat :**
```
DisplayName  : USS Enterprise
Id           : 12345678-1234-1234-1234-123456789012
VerifiedDomains : {@{Name=uss-enterprise.onmicrosoft.com; IsDefault=True}}
```

### Tester la connexion avec une commande simple

```powershell
# Lister les 5 premiers utilisateurs
Get-MgUser -Top 5 | Select-Object DisplayName, UserPrincipalName

# Si ça fonctionne, vous êtes bien connecté !
```

---

## 🔒 Connexion pour les scripts automatisés (Service Principal)

Pour automatiser des tâches, vous pouvez utiliser un **Service Principal** (équivalent d'un compte de service).

### Étape 1 : Créer un Service Principal

```powershell
# Se connecter de manière interactive d'abord
Connect-MgGraph

# Créer une application
$app = New-MgApplication -DisplayName "USS-Enterprise-Automation"

# Créer le Service Principal
$sp = New-MgServicePrincipal -AppId $app.AppId

# Créer un secret (mot de passe)
$secret = Add-MgApplicationPassword -ApplicationId $app.Id

# SAUVEGARDER LE SECRET IMMÉDIATEMENT (ne peut être récupéré qu'une fois!)
Write-Host "Client ID: $($app.AppId)"
Write-Host "Tenant ID: (votre-tenant-id)"
Write-Host "Client Secret: $($secret.SecretText)"
```

### Étape 2 : Se connecter avec le Service Principal

```powershell
# Méthode 1 : Avec secret
$tenantId = "VOTRE-TENANT-ID"
$clientId = "VOTRE-CLIENT-ID"
$clientSecret = "VOTRE-CLIENT-SECRET"

$securePassword = ConvertTo-SecureString -String $clientSecret -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $clientId, $securePassword

Connect-MgGraph -TenantId $tenantId -ClientSecretCredential $credential
```

---

## 🔓 Déconnexion

### Se déconnecter de Microsoft Graph

```powershell
# Déconnexion simple
Disconnect-MgGraph

# Vérifier que vous êtes déconnecté
Get-MgContext
# Devrait retourner : null ou une erreur
```

### Nettoyer les sessions

```powershell
# Forcer la déconnexion et nettoyer le cache
Disconnect-MgGraph
Clear-MgGraphCache  # Si disponible

# Redémarrer PowerShell si nécessaire
exit
```

---

## ⚠️ Résolution des problèmes courants

### Problème 1 : "Insufficient privileges"

**Cause** : Vous n'avez pas les permissions nécessaires.

**Solution** :
```powershell
# Se déconnecter
Disconnect-MgGraph

# Se reconnecter avec plus de scopes
Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"
```

### Problème 2 : "AADSTS50076: Due to a configuration change made by your administrator..."

**Cause** : MFA est requis mais pas configuré.

**Solution** :
- Configurer MFA sur votre compte
- Utiliser un compte avec MFA déjà configuré
- Exclure temporairement votre compte de la politique MFA (pour tests uniquement)

### Problème 3 : Module non trouvé

**Cause** : Module Microsoft.Graph pas installé.

**Solution** :
```powershell
# Installer le module
Install-Module -Name Microsoft.Graph -Force -Scope CurrentUser

# Vérifier l'installation
Get-Module -ListAvailable -Name Microsoft.Graph*

# Importer le module
Import-Module Microsoft.Graph
```

### Problème 4 : Scripts désactivés

**Cause** : Politique d'exécution des scripts trop restrictive.

**Solution** :
```powershell
# Vérifier la politique actuelle
Get-ExecutionPolicy

# Modifier la politique
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Confirmer avec 'Y'
```

---

## 📝 Script de connexion complet

```powershell
# Script : connect-enterprise.ps1
# Description : Script de connexion pour le projet USS Enterprise

<#
.SYNOPSIS
    Script de connexion à Entra ID pour le projet USS Enterprise
.DESCRIPTION
    Se connecte à Microsoft Graph avec toutes les permissions nécessaires
#>

function Connect-EnterpriseGraph {
    [CmdletBinding()]
    param()
    
    try {
        Write-Host "`n=== Connexion à USS Enterprise Entra ID ===" -ForegroundColor Cyan
        
        # Vérifier si déjà connecté
        $context = Get-MgContext -ErrorAction SilentlyContinue
        if ($context) {
            Write-Host "✓ Déjà connecté en tant que : $($context.Account)" -ForegroundColor Green
            return
        }
        
        # Liste des scopes nécessaires
        $scopes = @(
            "User.ReadWrite.All",
            "Group.ReadWrite.All",
            "Directory.ReadWrite.All",
            "Policy.ReadWrite.ConditionalAccess",
            "Application.ReadWrite.All",
            "AuditLog.Read.All",
            "RoleManagement.ReadWrite.Directory"
        )
        
        Write-Host "Connexion en cours..." -ForegroundColor Yellow
        
        # Se connecter
        Connect-MgGraph -Scopes $scopes -ErrorAction Stop
        
        # Vérifier la connexion
        $context = Get-MgContext
        Write-Host "`n✓ Connexion réussie!" -ForegroundColor Green
        Write-Host "  Compte : $($context.Account)" -ForegroundColor Cyan
        Write-Host "  Tenant : $($context.TenantId)" -ForegroundColor Cyan
        
        # Afficher les infos du tenant
        $org = Get-MgOrganization
        Write-Host "  Organisation : $($org.DisplayName)" -ForegroundColor Cyan
        
    } catch {
        Write-Error "Échec de connexion : $_"
        throw
    }
}

# Exécuter la connexion
Connect-EnterpriseGraph
```

**Utilisation** :
```powershell
# Exécuter le script
.\connect-enterprise.ps1
```

---

## 🎯 Résumé des commandes essentielles

| Action | Commande |
|--------|----------|
| **Installer le module** | `Install-Module -Name Microsoft.Graph -Force` |
| **Se connecter (simple)** | `Connect-MgGraph` |
| **Se connecter (avec scopes)** | `Connect-MgGraph -Scopes "User.ReadWrite.All"` |
| **Vérifier la connexion** | `Get-MgContext` |
| **Info organisation** | `Get-MgOrganization` |
| **Se déconnecter** | `Disconnect-MgGraph` |
| **Lister les utilisateurs** | `Get-MgUser` |

---

## 📚 Ressources complémentaires

- [Microsoft Graph PowerShell SDK](https://learn.microsoft.com/en-us/powershell/microsoftgraph/)
- [Liste complète des scopes](https://learn.microsoft.com/en-us/graph/permissions-reference)
- [Microsoft Graph Explorer](https://developer.microsoft.com/en-us/graph/graph-explorer) - Tester les API en ligne

---

## ✅ Checklist de connexion

- [ ] Module Microsoft.Graph installé
- [ ] Politique d'exécution configurée (RemoteSigned)
- [ ] Compte Azure avec droits administrateur
- [ ] MFA configuré sur le compte
- [ ] Connexion testée avec `Get-MgContext`
- [ ] Informations du tenant récupérées avec `Get-MgOrganization`

---

**Date de création** : Novembre 2024  
**Version** : 1.0  
**Projet** : USS Enterprise - Entra ID Security