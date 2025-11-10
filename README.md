# Projet AD Enterprise - USS Enterprise Infrastructure Security

## 📖 Description
Projet de sécurisation de l'infrastructure de l'USS Enterprise utilisant Microsoft Entra ID pour la gestion des identités et des accès.

## 🎯 Objectifs
- Renforcer la sécurité avec des politiques avancées
- Automatiser la gestion via PowerShell
- Intégrer et sécuriser des applications
- Détecter et répondre aux incidents

## 🏗️ Architecture

### Modèle en tiers (Tier Model)
- **Tier 0** (1%) : Domain Admin, Cloud Admin
- **Tier 1** (98%) : Dev, Test, Stage, Prod
- **Tier 2** (1%) : Shared Privileged, Personal Privileged, Service Accounts

## 📂 Structure du projet
```
ad-enterprise/
├── scripts/
│   ├── 01-connect-entraid.ps1
│   ├── 02-enable-mfa.ps1
│   ├── 03-conditional-access-policy.ps1
│   └── ...
├── documentation/
│   ├── installation.md
│   ├── configuration.md
├───├── mémo_commandes.md /
│           ├── 00_index.md
│           ├── 00_quickstart.md
│           ├── 01_création_tenant.md
│           ├── 02_connexion_powershell.md
│           └── ...
│ 
└── README.md
```

## 🚀 Installation

### Prérequis
- Azure Subscription
- PowerShell 7+
- Modules : AzureAD, Microsoft.Graph

### Installation des modules
```powershell
Install-Module -Name AzureAD -Force
Install-Module -Name Microsoft.Graph -Force
```

## 📋 Utilisation

### 1. Connexion
```powershell
.\scripts\01-connect-entraid.ps1
```

### 2. Créer des utilisateurs
```powershell
.\scripts\05-create-users.ps1
```

## 🧪 Tests

Voir le dossier `tests/` pour les procédures de test détaillées.

## 👥 Contributeurs

- Tom Ribero 

## 📄 Licence
MIT