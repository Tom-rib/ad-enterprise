# Guide d'Installation - Projet AD Enterprise USS Enterprise

## 📋 Table des matières

1. [Prérequis](#prérequis)
2. [Installation de l'environnement](#installation-de-lenvironnement)
3. [Configuration Azure](#configuration-azure)
4. [Installation des modules PowerShell](#installation-des-modules-powershell)
5. [Configuration du projet local](#configuration-du-projet-local)
6. [Vérification de l'installation](#vérification-de-linstallation)
7. [Dépannage](#dépannage)

---

## 🔧 Prérequis

### Compte et Accès

- **Compte Microsoft Azure** (obligatoire)
  - Compte étudiant Azure for Students recommandé (gratuit)
  - Ou compte Azure avec abonnement actif
  - Droits d'administrateur global sur le tenant Azure AD

- **Compte GitHub** (obligatoire)
  - Pour héberger le projet public
  - Git installé localement

### Configuration Matérielle Minimale

- **Système d'exploitation** : Windows 10/11, macOS 10.15+, ou Linux
- **RAM** : 8 Go minimum, 16 Go recommandé
- **Espace disque** : 2 Go d'espace libre
- **Connexion Internet** : Stable et rapide

### Logiciels Requis

- **PowerShell 7.x** ou supérieur
- **Visual Studio Code** (recommandé) ou autre éditeur de code
- **Git** version 2.x ou supérieure
- **Navigateur Web** moderne (Chrome, Firefox, Edge)

---

## 💻 Installation de l'environnement

### 1. Installation de PowerShell 7

#### Windows
```powershell
# Télécharger et installer PowerShell 7
winget install --id Microsoft.Powershell --source winget

# Ou via le site officiel
# https://github.com/PowerShell/PowerShell/releases
```

#### macOS
```bash
# Via Homebrew
brew install --cask powershell

# Vérifier l'installation
pwsh --version
```

#### Linux (Ubuntu/Debian)
```bash
# Télécharger le package
wget https://github.com/PowerShell/PowerShell/releases/download/v7.4.0/powershell_7.4.0-1.deb_amd64.deb

# Installer
sudo dpkg -i powershell_7.4.0-1.deb_amd64.deb
sudo apt-get install -f

# Vérifier
pwsh --version
```

### 2. Installation de Visual Studio Code

#### Toutes plateformes
```bash
# Télécharger depuis : https://code.visualstudio.com/

# Extensions recommandées à installer :
# - PowerShell (ms-vscode.powershell)
# - Azure Account (ms-vscode.azure-account)
# - GitLens (eamodio.gitlens)
```

#### Installation des extensions VS Code
```bash
code --install-extension ms-vscode.powershell
code --install-extension ms-vscode.azure-account
code --install-extension eamodio.gitlens
```

### 3. Installation de Git

#### Windows
```powershell
# Via winget
winget install --id Git.Git -e --source winget

# Ou télécharger : https://git-scm.com/download/win
```

#### macOS
```bash
# Via Homebrew
brew install git
```

#### Linux
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install git

# Fedora
sudo dnf install git
```

#### Configuration Git
```bash
git config --global user.name "Votre Nom"
git config --global user.email "votre.email@example.com"
```

---

## ☁️ Configuration Azure

### 1. Création du compte Azure

1. **Accéder au portail Azure for Students**
   - URL : https://azure.microsoft.com/fr-fr/free/students/
   - Cliquer sur "Activer maintenant"
   - Se connecter avec votre email étudiant

2. **Vérification du compte**
   - Fournir les informations demandées
   - Vérifier votre statut étudiant
   - Accepter les conditions d'utilisation

3. **Vérifier l'accès**
   - Se connecter sur : https://portal.azure.com
   - Vérifier que vous avez un abonnement actif

### 2. Configuration du tenant Azure AD (Entra ID)

1. **Accéder à Entra ID**
   ```
   Portail Azure > Rechercher "Azure Active Directory" ou "Entra ID"
   ```

2. **Vérifier les informations du tenant**
   - Nom du tenant : `uss-enterprise.onmicrosoft.com` (exemple)
   - ID du tenant : Copier pour utilisation ultérieure
   - Domaine personnalisé (optionnel)

3. **Créer un groupe de ressources**
   ```
   Portail Azure > Groupes de ressources > Créer
   
   Nom : USS-Enterprise-RG
   Région : France Central (ou votre région préférée)
   ```

### 3. Attribution des rôles nécessaires

1. **Vérifier vos rôles actuels**
   ```
   Entra ID > Rôles et administrateurs
   ```

2. **Rôles requis pour le projet**
   - Administrateur global (Global Administrator)
   - Administrateur de la sécurité (Security Administrator)
   - Administrateur d'application (Application Administrator)

3. **Demander les rôles si nécessaire**
   - Contacter votre administrateur IT
   - Ou utiliser un tenant de test personnel

### 4. Activer les licences nécessaires

1. **Vérifier les licences disponibles**
   ```
   Entra ID > Licences > Tous les produits
   ```

2. **Licences requises pour le projet**
   - Azure AD Premium P1 (minimum)
   - Azure AD Premium P2 (recommandé pour l'accès conditionnel)
   - Microsoft 365 E5 (optionnel, pour fonctionnalités avancées)

3. **Activer un essai gratuit si nécessaire**
   ```
   Entra ID > Licences > Essayer/Acheter
   Activer l'essai de 30 jours Azure AD Premium P2
   ```

---

## 📦 Installation des modules PowerShell

### 1. Ouvrir PowerShell en mode administrateur

#### Windows
```powershell
# Clic droit sur PowerShell 7 > Exécuter en tant qu'administrateur
```

#### macOS/Linux
```bash
# Lancer pwsh avec sudo si nécessaire
sudo pwsh
```

### 2. Configuration de la politique d'exécution

```powershell
# Vérifier la politique actuelle
Get-ExecutionPolicy

# Définir la politique pour permettre l'exécution de scripts
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Confirmer avec 'Y' (Yes)
```

### 3. Installation du module Azure AD (Legacy)

```powershell
# Installer le module AzureAD
Install-Module -Name AzureAD -Force -AllowClobber -Scope CurrentUser

# Vérifier l'installation
Get-Module -ListAvailable -Name AzureAD

# Version attendue : 2.0.2.x ou supérieure
```

### 4. Installation du module Microsoft Graph (Recommandé)

```powershell
# Installer le module Microsoft Graph complet
Install-Module -Name Microsoft.Graph -Force -AllowClobber -Scope CurrentUser

# Ou installer uniquement les sous-modules nécessaires (plus rapide)
Install-Module -Name Microsoft.Graph.Authentication -Force -Scope CurrentUser
Install-Module -Name Microsoft.Graph.Users -Force -Scope CurrentUser
Install-Module -Name Microsoft.Graph.Groups -Force -Scope CurrentUser
Install-Module -Name Microsoft.Graph.Identity.SignIns -Force -Scope CurrentUser
Install-Module -Name Microsoft.Graph.Applications -Force -Scope CurrentUser
Install-Module -Name Microsoft.Graph.Identity.DirectoryManagement -Force -Scope CurrentUser

# Vérifier l'installation
Get-Module -ListAvailable -Name Microsoft.Graph*
```

### 5. Installation des modules Azure supplémentaires

```powershell
# Module Azure (pour Azure Monitor et alertes)
Install-Module -Name Az -Force -AllowClobber -Scope CurrentUser

# Module MSOnline (pour certaines fonctionnalités MFA)
Install-Module -Name MSOnline -Force -AllowClobber -Scope CurrentUser

# Vérifier toutes les installations
Get-InstalledModule | Where-Object { $_.Name -like "*Azure*" -or $_.Name -like "*Graph*" -or $_.Name -like "*MSOnline*" }
```

### 6. Mise à jour des modules

```powershell
# Mettre à jour tous les modules installés
Update-Module -Force

# Ou mettre à jour spécifiquement
Update-Module -Name Microsoft.Graph -Force
Update-Module -Name AzureAD -Force
```

---

## 🗂️ Configuration du projet local

### 1. Cloner ou créer le repository

#### Option A : Créer un nouveau repository

```bash
# Créer le dossier du projet
mkdir ad-enterprise
cd ad-enterprise

# Initialiser Git
git init

# Créer le fichier README
echo "# AD Enterprise - USS Enterprise Security Project" > README.md

# Premier commit
git add README.md
git commit -m "Initial commit"

# Créer le repository sur GitHub (via l'interface web)
# Puis lier au repository distant
git remote add origin https://github.com/votre-nom/ad-enterprise.git
git branch -M main
git push -u origin main
```

#### Option B : Cloner un repository existant

```bash
# Cloner le repository
git clone https://github.com/votre-nom/ad-enterprise.git
cd ad-enterprise
```

### 2. Créer la structure de dossiers

```bash
# Windows PowerShell
New-Item -ItemType Directory -Path scripts
New-Item -ItemType Directory -Path documentation
New-Item -ItemType Directory -Path tests
New-Item -ItemType Directory -Path tests/test-results
New-Item -ItemType Directory -Path logs
New-Item -ItemType Directory -Path config

# macOS/Linux bash
mkdir -p scripts documentation tests/test-results logs config
```

### 3. Créer les fichiers de configuration

#### Fichier .gitignore
```bash
# Créer le fichier .gitignore
cat > .gitignore << 'EOF'
# Fichiers de configuration sensibles
config/secrets.json
config/credentials.json
*.pfx
*.pem

# Logs
logs/*.log
logs/*.json
tests/test-results/*.xml

# Fichiers PowerShell temporaires
*.ps1~
*.swp

# Fichiers système
.DS_Store
Thumbs.db
desktop.ini

# Dossiers IDE
.vscode/
.idea/
*.code-workspace

# Modules PowerShell téléchargés
PSModules/

# Credentials
*credential*
*password*
*secret*
EOF
```

#### Fichier de configuration config/settings.json
```bash
# Créer le fichier de configuration
cat > config/settings.json << 'EOF'
{
  "TenantSettings": {
    "TenantId": "VOTRE-TENANT-ID",
    "TenantName": "uss-enterprise.onmicrosoft.com",
    "DefaultDomain": "uss-enterprise.com"
  },
  "Security": {
    "RequireMFA": true,
    "AllowedLocations": ["France", "United States"],
    "BlockedLocations": [],
    "PasswordComplexity": true
  },
  "Groups": {
    "ExplorationTeam": "Équipe d'Exploration",
    "MedicalTeam": "Équipe Médicale",
    "EngineeringTeam": "Équipe d'Ingénierie",
    "CommandTeam": "Équipe de Commandement"
  },
  "Logging": {
    "LogPath": "./logs",
    "LogLevel": "Information",
    "RetentionDays": 30
  }
}
EOF
```

### 4. Créer un script de configuration initial

```powershell
# Créer scripts/00-setup-environment.ps1
@'
<#
.SYNOPSIS
    Script de configuration initiale de l'environnement
.DESCRIPTION
    Ce script vérifie et configure l'environnement de travail
#>

# Vérifier PowerShell version
$psVersion = $PSVersionTable.PSVersion
Write-Host "PowerShell Version: $psVersion" -ForegroundColor Cyan

if ($psVersion.Major -lt 7) {
    Write-Warning "PowerShell 7 ou supérieur est recommandé"
}

# Vérifier les modules installés
$requiredModules = @(
    "AzureAD",
    "Microsoft.Graph.Authentication",
    "Microsoft.Graph.Users",
    "Microsoft.Graph.Groups"
)

Write-Host "`nVérification des modules requis:" -ForegroundColor Yellow

foreach ($module in $requiredModules) {
    $installed = Get-Module -ListAvailable -Name $module
    if ($installed) {
        Write-Host "✓ $module est installé (Version: $($installed.Version))" -ForegroundColor Green
    } else {
        Write-Host "✗ $module n'est PAS installé" -ForegroundColor Red
        Write-Host "  Installer avec: Install-Module -Name $module -Force" -ForegroundColor Yellow
    }
}

# Créer les dossiers nécessaires
$folders = @("logs", "tests/test-results", "config")
foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        Write-Host "✓ Dossier créé: $folder" -ForegroundColor Green
    }
}

# Charger la configuration
$configPath = "./config/settings.json"
if (Test-Path $configPath) {
    $config = Get-Content $configPath | ConvertFrom-Json
    Write-Host "`n✓ Configuration chargée depuis $configPath" -ForegroundColor Green
} else {
    Write-Warning "Fichier de configuration non trouvé: $configPath"
}

Write-Host "`n=== Configuration de l'environnement terminée ===" -ForegroundColor Green
'@ | Out-File -FilePath scripts/00-setup-environment.ps1 -Encoding utf8
```

### 5. Initialiser le fichier de logs

```powershell
# Créer un fichier de log initial
$logPath = "./logs"
if (-not (Test-Path $logPath)) {
    New-Item -ItemType Directory -Path $logPath -Force
}

$logEntry = @{
    Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Event = "Installation"
    Message = "Projet initialisé"
    Status = "Success"
}

$logEntry | ConvertTo-Json | Out-File -FilePath "$logPath/installation-$(Get-Date -Format 'yyyyMMdd').log" -Encoding utf8
```

---

## ✅ Vérification de l'installation

### 1. Test de connexion Azure AD

```powershell
# Créer scripts/test-connection.ps1
@'
# Test de connexion à Azure AD
Write-Host "Test de connexion à Azure AD..." -ForegroundColor Cyan

try {
    # Connexion avec Azure AD
    Connect-AzureAD
    $tenant = Get-AzureADTenantDetail
    
    Write-Host "`n✓ Connexion réussie!" -ForegroundColor Green
    Write-Host "Tenant: $($tenant.DisplayName)" -ForegroundColor Cyan
    Write-Host "ID: $($tenant.ObjectId)" -ForegroundColor Cyan
    
    # Déconnexion
    Disconnect-AzureAD
    
} catch {
    Write-Error "✗ Échec de connexion: $_"
}
'@ | Out-File -FilePath scripts/test-connection.ps1 -Encoding utf8

# Exécuter le test
pwsh scripts/test-connection.ps1
```

### 2. Test de connexion Microsoft Graph

```powershell
# Test avec Microsoft Graph
Write-Host "Test de connexion à Microsoft Graph..." -ForegroundColor Cyan

try {
    Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All"
    
    $context = Get-MgContext
    Write-Host "`n✓ Connexion Microsoft Graph réussie!" -ForegroundColor Green
    Write-Host "Account: $($context.Account)" -ForegroundColor Cyan
    Write-Host "Tenant: $($context.TenantId)" -ForegroundColor Cyan
    
    Disconnect-MgGraph
    
} catch {
    Write-Error "✗ Échec de connexion Graph: $_"
}
```

### 3. Vérification complète de l'environnement

```powershell
# Exécuter le script de configuration
pwsh scripts/00-setup-environment.ps1

# Vérifier que tout est OK
# Tous les modules doivent afficher ✓
```

### 4. Checklist d'installation

- [ ] PowerShell 7+ installé et fonctionnel
- [ ] Visual Studio Code installé avec extensions
- [ ] Git configuré avec nom et email
- [ ] Compte Azure actif et accessible
- [ ] Tenant Azure AD/Entra ID configuré
- [ ] Rôles administrateur assignés
- [ ] Module AzureAD installé
- [ ] Modules Microsoft.Graph installés
- [ ] Repository GitHub créé et cloné
- [ ] Structure de dossiers créée
- [ ] Fichier .gitignore configuré
- [ ] Fichier settings.json configuré
- [ ] Test de connexion Azure AD réussi
- [ ] Test de connexion Microsoft Graph réussi

---

## 🔧 Dépannage

### Problème : Erreur "running scripts is disabled"

**Solution :**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Problème : Module ne s'installe pas

**Solution :**
```powershell
# Essayer avec -Force et -AllowClobber
Install-Module -Name Microsoft.Graph -Force -AllowClobber -Scope CurrentUser

# Si toujours un problème, nettoyer le cache
Uninstall-Module -Name Microsoft.Graph -AllVersions -Force
Install-Module -Name Microsoft.Graph -Force -Scope CurrentUser
```

### Problème : Échec de connexion Azure AD

**Solutions possibles :**
1. Vérifier que vous êtes sur le bon tenant
2. Vérifier vos permissions (Administrateur global requis)
3. Désactiver temporairement le VPN si activé
4. Vider le cache des credentials :
   ```powershell
   Disconnect-AzureAD
   Clear-AzureAdTokenCache
   Connect-AzureAD
   ```

### Problème : "Insufficient privileges" lors de l'accès Graph

**Solution :**
```powershell
# Se reconnecter avec plus de scopes
Disconnect-MgGraph
Connect-MgGraph -Scopes "User.ReadWrite.All", "Group.ReadWrite.All", "Directory.ReadWrite.All", "Policy.ReadWrite.ConditionalAccess"
```

### Problème : Git push échoue

**Solutions :**
```bash
# Vérifier la connexion SSH/HTTPS
git remote -v

# Reconfigurer l'origine si nécessaire
git remote set-url origin https://github.com/votre-nom/ad-enterprise.git

# Authentification avec token personnel si HTTPS
# Créer un token sur : https://github.com/settings/tokens
```

### Problème : Modules Microsoft.Graph lents à charger

**Solution :**
```powershell
# N'installer que les sous-modules nécessaires au lieu du package complet
Uninstall-Module Microsoft.Graph -AllVersions -Force

# Installer uniquement les modules requis
$modules = @(
    "Microsoft.Graph.Authentication",
    "Microsoft.Graph.Users",
    "Microsoft.Graph.Groups",
    "Microsoft.Graph.Identity.SignIns"
)

foreach ($module in $modules) {
    Install-Module -Name $module -Force -Scope CurrentUser
}
```

---

## 📞 Support et Ressources

### Documentation officielle
- [Microsoft Graph PowerShell Documentation](https://learn.microsoft.com/en-us/powershell/microsoftgraph/)
- [Azure AD PowerShell Documentation](https://learn.microsoft.com/en-us/powershell/azure/active-directory/)
- [Entra ID Documentation](https://learn.microsoft.com/en-us/azure/active-directory/)

### Communauté
- [Microsoft Tech Community](https://techcommunity.microsoft.com/)
- [Stack Overflow - Azure AD](https://stackoverflow.com/questions/tagged/azure-active-directory)

### Contact
Pour toute question sur ce projet : [votre-email@example.com]

---

**Date de dernière mise à jour :** Novembre 2024  
**Version du document :** 1.0