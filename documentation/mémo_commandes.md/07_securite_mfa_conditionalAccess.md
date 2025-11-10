# Guide 07 - MFA et Accès Conditionnel

## 📚 À quoi ça sert ?

L'**authentification multi-facteurs (MFA)** et l'**accès conditionnel** sont les piliers de la sécurité Zero Trust dans Azure AD. Ils permettent de protéger les identités contre les attaques et de contrôler finement qui peut accéder à quoi, depuis où, et dans quelles conditions.

### Pourquoi utiliser MFA et l'accès conditionnel ?
- **Sécurité renforcée** : Bloquer 99,9% des attaques d'identité
- **Contrôle granulaire** : Politiques basées sur utilisateur, emplacement, appareil, application
- **Expérience utilisateur** : MFA uniquement quand nécessaire (risque élevé)
- **Conformité** : Respecter les exigences réglementaires

---

## 🔐 Authentification Multi-Facteurs (MFA)

### Concepts de base

**MFA = Quelque chose que vous savez + Quelque chose que vous avez + Quelque chose que vous êtes**

- **Facteur 1** : Mot de passe (ce que vous savez)
- **Facteur 2** : Code SMS, application authentificateur, clé de sécurité (ce que vous avez)
- **Facteur 3** : Biométrie - empreinte, visage (ce que vous êtes)

---

## 🚀 Activation du MFA

### Méthode 1 : MFA par politique d'accès conditionnel (Recommandé)

#### Activer MFA pour tous les administrateurs

```powershell
# Se connecter avec les bonnes permissions
Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess", "Application.Read.All"

# Créer une politique MFA pour les administrateurs
$adminMfaPolicy = @{
    DisplayName = "USS Enterprise - MFA Required for Administrators"
    State = "enabled"
    Conditions = @{
        Users = @{
            IncludeRoles = @(
                "62e90394-69f5-4237-9190-012177145e10",  # Global Administrator
                "194ae4cb-b126-40b2-bd5b-6091b380977d",  # Security Administrator
                "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3",  # Application Administrator
                "c4e39bd9-1100-46d3-8c65-fb160da0071f",  # Authentication Administrator
                "729827e3-9c14-49f7-bb1b-9608f156bbb8",  # Helpdesk Administrator
                "fe930be7-5e62-47db-91af-98c3a49a38b1"   # User Administrator
            )
            ExcludeUsers = @()  # Ajouter l'ID du compte d'urgence ici
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

$createdPolicy = New-MgIdentityConditionalAccessPolicy -BodyParameter $adminMfaPolicy

Write-Host "✓ Politique MFA créée pour les administrateurs" -ForegroundColor Green
Write-Host "  ID : $($createdPolicy.Id)" -ForegroundColor Cyan
```

#### Activer MFA pour un groupe spécifique

```powershell
# Obtenir l'ID du groupe "Officiers Supérieurs"
$group = Get-MgGroup -Filter "displayName eq 'Tier 2 - Senior Officers'"

# Créer la politique MFA
$officersMfaPolicy = @{
    DisplayName = "USS Enterprise - MFA Required for Senior Officers"
    State = "enabled"
    Conditions = @{
        Users = @{
            IncludeGroups = @($group.Id)
            ExcludeUsers = @()  # Ajouter l'ID du compte d'urgence
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

New-MgIdentityConditionalAccessPolicy -BodyParameter $officersMfaPolicy

Write-Host "✓ Politique MFA créée pour les officiers supérieurs" -ForegroundColor Green
```

### Méthode 2 : MFA par utilisateur (Legacy - Non recommandé)

```powershell
# Cette méthode est obsolète mais peut être nécessaire
# Nécessite le module MSOnline

# Connect-MsolService

# # Activer MFA pour un utilisateur
# Set-MsolUser -UserPrincipalName "james.kirk@uss-enterprise.com" `
#     -StrongAuthenticationRequirements @(
#         @{
#             RelyingParty = "*"
#             State = "Enabled"
#         }
#     )
```

---

## 🌍 Politiques d'Accès Conditionnel

### 1. Politique : Bloquer les emplacements non autorisés

#### Créer des emplacements nommés (Trusted Locations)

```powershell
# Créer un emplacement nommé pour la France
$franceLocation = @{
    "@odata.type" = "#microsoft.graph.countryNamedLocation"
    DisplayName = "France - Starfleet HQ"
    CountriesAndRegions = @("FR")
    IncludeUnknownCountriesAndRegions = $false
}

$france = New-MgIdentityConditionalAccessNamedLocation -BodyParameter $franceLocation

Write-Host "✓ Emplacement nommé créé : France" -ForegroundColor Green
Write-Host "  ID : $($france.Id)" -ForegroundColor Cyan

# Créer un emplacement pour les États-Unis
$usaLocation = @{
    "@odata.type" = "#microsoft.graph.countryNamedLocation"
    DisplayName = "United States - Starfleet Operations"
    CountriesAndRegions = @("US")
    IncludeUnknownCountriesAndRegions = $false
}

$usa = New-MgIdentityConditionalAccessNamedLocation -BodyParameter $usaLocation

Write-Host "✓ Emplacement nommé créé : USA" -ForegroundColor Green
```

#### Créer une politique de blocage géographique

```powershell
# Politique : Bloquer tous les pays sauf FR et US
$geoBlockPolicy = @{
    DisplayName = "USS Enterprise - Block Unauthorized Planets"
    State = "enabled"  # "enabledForReportingButNotEnforced" pour tester
    Conditions = @{
        Users = @{
            IncludeUsers = @("All")
            ExcludeUsers = @()  # Ajouter l'ID du compte d'urgence
            ExcludeGroups = @()
        }
        Applications = @{
            IncludeApplications = @("All")
        }
        Locations = @{
            IncludeLocations = @("All")
            ExcludeLocations = @($france.Id, $usa.Id, "AllTrusted")
        }
    }
    GrantControls = @{
        Operator = "OR"
        BuiltInControls = @("block")
    }
}

$geoPolicy = New-MgIdentityConditionalAccessPolicy -BodyParameter $geoBlockPolicy

Write-Host "✓ Politique de blocage géographique créée" -ForegroundColor Green
Write-Host "  Pays bloqués : Tous sauf France et USA" -ForegroundColor Cyan
```

### 2. Politique : Exiger des appareils conformes

```powershell
# Politique : Exiger appareil conforme ou joint au domaine
$deviceCompliancePolicy = @{
    DisplayName = "USS Enterprise - Require Compliant Devices"
    State = "enabled"
    Conditions = @{
        Users = @{
            IncludeUsers = @("All")
            ExcludeUsers = @()  # Compte d'urgence
        }
        Applications = @{
            IncludeApplications = @("All")
        }
    }
    GrantControls = @{
        Operator = "OR"
        BuiltInControls = @("compliantDevice", "domainJoinedDevice")
    }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $deviceCompliancePolicy

Write-Host "✓ Politique d'appareils conformes créée" -ForegroundColor Green
```

### 3. Politique : MFA pour applications sensibles

```powershell
# Obtenir les IDs des applications sensibles
# Pour une application spécifique, utilisez son App ID

$sensitiveAppsPolicy = @{
    DisplayName = "USS Enterprise - MFA for Sensitive Applications"
    State = "enabled"
    Conditions = @{
        Users = @{
            IncludeUsers = @("All")
            ExcludeUsers = @()  # Compte d'urgence
        }
        Applications = @{
            # Inclure des applications spécifiques ou utiliser "All"
            IncludeApplications = @("All")
            # Ou spécifier des applications :
            # IncludeApplications = @("APP-ID-1", "APP-ID-2")
        }
    }
    GrantControls = @{
        Operator = "AND"  # Exiger MFA ET appareil conforme
        BuiltInControls = @("mfa", "compliantDevice")
    }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $sensitiveAppsPolicy

Write-Host "✓ Politique MFA pour applications sensibles créée" -ForegroundColor Green
```

### 4. Politique : Bloquer les protocoles d'authentification hérités

```powershell
# Bloquer les protocoles comme POP3, IMAP, SMTP authentifié
$legacyAuthBlockPolicy = @{
    DisplayName = "USS Enterprise - Block Legacy Authentication"
    State = "enabled"
    Conditions = @{
        Users = @{
            IncludeUsers = @("All")
            ExcludeUsers = @()  # Compte d'urgence
        }
        Applications = @{
            IncludeApplications = @("All")
        }
        ClientAppTypes = @("exchangeActiveSync", "other")
    }
    GrantControls = @{
        Operator = "OR"
        BuiltInControls = @("block")
    }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $legacyAuthBlockPolicy

Write-Host "✓ Politique de blocage des protocoles hérités créée" -ForegroundColor Green
```

### 5. Politique : Exiger MFA depuis des emplacements non approuvés

```powershell
# MFA requis seulement depuis des emplacements non approuvés
$untrustedLocationPolicy = @{
    DisplayName = "USS Enterprise - MFA from Untrusted Locations"
    State = "enabled"
    Conditions = @{
        Users = @{
            IncludeUsers = @("All")
            ExcludeUsers = @()
        }
        Applications = @{
            IncludeApplications = @("All")
        }
        Locations = @{
            IncludeLocations = @("All")
            ExcludeLocations = @("AllTrusted")  # Exclure les emplacements de confiance
        }
    }
    GrantControls = @{
        Operator = "OR"
        BuiltInControls = @("mfa")
    }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $untrustedLocationPolicy

Write-Host "✓ Politique MFA pour emplacements non approuvés créée" -ForegroundColor Green
```

---

## 📊 Gestion des politiques existantes

### Lister toutes les politiques

```powershell
# Lister toutes les politiques d'accès conditionnel
$policies = Get-MgIdentityConditionalAccessPolicy

Write-Host "`n=== Politiques d'Accès Conditionnel ===" -ForegroundColor Cyan
foreach ($policy in $policies) {
    $stateColor = if ($policy.State -eq "enabled") { "Green" } else { "Yellow" }
    Write-Host "`n$($policy.DisplayName)" -ForegroundColor White
    Write-Host "  État : $($policy.State)" -ForegroundColor $stateColor
    Write-Host "  ID : $($policy.Id)" -ForegroundColor Gray
}
```

### Obtenir les détails d'une politique

```powershell
# Obtenir une politique spécifique
$policyId = "POLICY-ID"
$policy = Get-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $policyId

# Afficher les détails
$policy | ConvertTo-Json -Depth 10
```

### Modifier une politique

```powershell
# Désactiver temporairement une politique (pour tests)
$policyId = "POLICY-ID"

Update-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $policyId `
    -State "disabled"

Write-Host "✓ Politique désactivée" -ForegroundColor Yellow

# Réactiver
Update-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $policyId `
    -State "enabled"

Write-Host "✓ Politique réactivée" -ForegroundColor Green
```

### Supprimer une politique

```powershell
# Supprimer une politique
$policyId = "POLICY-ID"

Remove-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $policyId

Write-Host "✓ Politique supprimée" -ForegroundColor Yellow
```

---

## 🧪 Mode "Report-only" pour tester

```powershell
# Créer une politique en mode rapport uniquement (pas d'application)
$testPolicy = @{
    DisplayName = "TEST - USS Enterprise MFA Policy"
    State = "enabledForReportingButNotEnforced"  # Mode test
    Conditions = @{
        Users = @{
            IncludeUsers = @("All")
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

$testPol = New-MgIdentityConditionalAccessPolicy -BodyParameter $testPolicy

Write-Host "✓ Politique de test créée (mode rapport uniquement)" -ForegroundColor Yellow
Write-Host "  Surveiller les logs pour voir l'impact sans bloquer les utilisateurs" -ForegroundColor Cyan
```

---

## 🔍 Analyser l'impact des politiques

### Simuler l'accès conditionnel (What-If)

```powershell
# Utiliser l'outil What-If dans le portail Azure
# Entra ID > Accès conditionnel > What If

# Permet de tester :
# - Quel utilisateur ?
# - Quelle application ?
# - Quel emplacement ?
# - Quelle plateforme ?

# Résultat : Quelles politiques s'appliqueraient ?

Write-Host "Outil What-If disponible dans le portail Azure :" -ForegroundColor Cyan
Write-Host "  Entra ID > Sécurité > Accès conditionnel > What If" -ForegroundColor White
```

### Analyser les logs de connexion

```powershell
# Nécessite le scope AuditLog.Read.All
Connect-MgGraph -Scopes "AuditLog.Read.All"

# Obtenir les connexions des dernières 24h
$startDate = (Get-Date).AddDays(-1).ToString("yyyy-MM-ddTHH:mm:ssZ")
$signIns = Get-MgAuditLogSignIn -Filter "createdDateTime ge $startDate" -Top 100

# Analyser les résultats d'accès conditionnel
$caResults = $signIns | Where-Object { $_.ConditionalAccessStatus -ne "success" }

Write-Host "`n=== Résultats Accès Conditionnel (dernières 24h) ===" -ForegroundColor Cyan
foreach ($result in $caResults) {
    Write-Host "`nUtilisateur : $($result.UserPrincipalName)" -ForegroundColor Yellow
    Write-Host "Date : $($result.CreatedDateTime)" -ForegroundColor Gray
    Write-Host "Statut CA : $($result.ConditionalAccessStatus)" -ForegroundColor Red
    Write-Host "Application : $($result.AppDisplayName)" -ForegroundColor Gray
}
```

---

## 🎯 Script complet : Configuration de la sécurité USS Enterprise

```powershell
<#
.SYNOPSIS
    Configuration complète MFA et Accès Conditionnel pour USS Enterprise
#>

function Initialize-EnterpriseSecurityPolicies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$EmergencyAccountId  # ID du compte d'urgence à exclure
    )
    
    Write-Host "`n=== CONFIGURATION SÉCURITÉ USS ENTERPRISE ===" -ForegroundColor Cyan
    
    # Connexion
    Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess", "Directory.Read.All"
    
    # IDs des rôles administrateurs
    $adminRoles = @(
        "62e90394-69f5-4237-9190-012177145e10",  # Global Administrator
        "194ae4cb-b126-40b2-bd5b-6091b380977d",  # Security Administrator
        "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3"   # Application Administrator
    )
    
    # Préparer l'exclusion du compte d'urgence
    $excludedUsers = @()
    if ($EmergencyAccountId) {
        $excludedUsers = @($EmergencyAccountId)
        Write-Host "✓ Compte d'urgence sera exclu de toutes les politiques" -ForegroundColor Yellow
    }
    
    # 1. Emplacements nommés
    Write-Host "`n[1/6] Création des emplacements nommés..." -ForegroundColor Yellow
    
    $france = New-MgIdentityConditionalAccessNamedLocation -BodyParameter @{
        "@odata.type" = "#microsoft.graph.countryNamedLocation"
        DisplayName = "France - Starfleet HQ"
        CountriesAndRegions = @("FR")
        IncludeUnknownCountriesAndRegions = $false
    }
    Write-Host "  ✓ France" -ForegroundColor Green
    
    $usa = New-MgIdentityConditionalAccessNamedLocation -BodyParameter @{
        "@odata.type" = "#microsoft.graph.countryNamedLocation"
        DisplayName = "USA - Starfleet Operations"
        CountriesAndRegions = @("US")
        IncludeUnknownCountriesAndRegions = $false
    }
    Write-Host "  ✓ USA" -ForegroundColor Green
    
    # 2. MFA pour administrateurs
    Write-Host "`n[2/6] Politique MFA pour administrateurs..." -ForegroundColor Yellow
    
    $pol1 = New-MgIdentityConditionalAccessPolicy -BodyParameter @{
        DisplayName = "USS Enterprise - MFA Required for Administrators"
        State = "enabled"
        Conditions = @{
            Users = @{
                IncludeRoles = $adminRoles
                ExcludeUsers = $excludedUsers
            }
            Applications = @{ IncludeApplications = @("All") }
        }
        GrantControls = @{
            Operator = "OR"
            BuiltInControls = @("mfa")
        }
    }
    Write-Host "  ✓ Créée : MFA Administrateurs" -ForegroundColor Green
    
    # 3. Blocage géographique
    Write-Host "`n[3/6] Politique de blocage géographique..." -ForegroundColor Yellow
    
    $pol2 = New-MgIdentityConditionalAccessPolicy -BodyParameter @{
        DisplayName = "USS Enterprise - Block Unauthorized Planets"
        State = "enabled"
        Conditions = @{
            Users = @{
                IncludeUsers = @("All")
                ExcludeUsers = $excludedUsers
            }
            Applications = @{ IncludeApplications = @("All") }
            Locations = @{
                IncludeLocations = @("All")
                ExcludeLocations = @($france.Id, $usa.Id, "AllTrusted")
            }
        }
        GrantControls = @{
            Operator = "OR"
            BuiltInControls = @("block")
        }
    }
    Write-Host "  ✓ Créée : Blocage pays non autorisés" -ForegroundColor Green
    
    # 4. Appareils conformes
    Write-Host "`n[4/6] Politique appareils conformes..." -ForegroundColor Yellow
    
    $pol3 = New-MgIdentityConditionalAccessPolicy -BodyParameter @{
        DisplayName = "USS Enterprise - Require Compliant Devices"
        State = "enabledForReportingButNotEnforced"  # Mode test d'abord
        Conditions = @{
            Users = @{
                IncludeUsers = @("All")
                ExcludeUsers = $excludedUsers
            }
            Applications = @{ IncludeApplications = @("All") }
        }
        GrantControls = @{
            Operator = "OR"
            BuiltInControls = @("compliantDevice", "domainJoinedDevice")
        }
    }
    Write-Host "  ✓ Créée : Appareils conformes (mode test)" -ForegroundColor Yellow
    
    # 5. Blocage authentification héritée
    Write-Host "`n[5/6] Politique blocage auth héritée..." -ForegroundColor Yellow
    
    $pol4 = New-MgIdentityConditionalAccessPolicy -BodyParameter @{
        DisplayName = "USS Enterprise - Block Legacy Authentication"
        State = "enabled"
        Conditions = @{
            Users = @{
                IncludeUsers = @("All")
                ExcludeUsers = $excludedUsers
            }
            Applications = @{ IncludeApplications = @("All") }
            ClientAppTypes = @("exchangeActiveSync", "other")
        }
        GrantControls = @{
            Operator = "OR"
            BuiltInControls = @("block")
        }
    }
    Write-Host "  ✓ Créée : Blocage authentification héritée" -ForegroundColor Green
    
    # 6. MFA depuis emplacements non approuvés
    Write-Host "`n[6/6] Politique MFA emplacements non approuvés..." -ForegroundColor Yellow
    
    $pol5 = New-MgIdentityConditionalAccessPolicy -BodyParameter @{
        DisplayName = "USS Enterprise - MFA from Untrusted Locations"
        State = "enabled"
        Conditions = @{
            Users = @{
                IncludeUsers = @("All")
                ExcludeUsers = $excludedUsers
            }
            Applications = @{ IncludeApplications = @("All") }
            Locations = @{
                IncludeLocations = @("All")
                ExcludeLocations = @("AllTrusted")
            }
        }
        GrantControls = @{
            Operator = "OR"
            BuiltInControls = @("mfa")
        }
    }
    Write-Host "  ✓ Créée : MFA emplacements non approuvés" -ForegroundColor Green
    
    # Résumé
    Write-Host "`n=== CONFIGURATION TERMINÉE ===" -ForegroundColor Green
    Write-Host "`n5 politiques d'accès conditionnel créées :" -ForegroundColor Cyan
    Write-Host "  1. MFA pour administrateurs" -ForegroundColor White
    Write-Host "  2. Blocage géographique" -ForegroundColor White
    Write-Host "  3. Appareils conformes (mode test)" -ForegroundColor Yellow
    Write-Host "  4. Blocage authentification héritée" -ForegroundColor White
    Write-Host "  5. MFA depuis emplacements non approuvés" -ForegroundColor White
    
    Write-Host "`n⚠️  ACTIONS SUIVANTES :" -ForegroundColor Yellow
    Write-Host "1. Tester les politiques avec l'outil What-If" -ForegroundColor White
    Write-Host "2. Surveiller les logs de connexion" -ForegroundColor White
    Write-Host "3. Activer la politique 'Appareils conformes' après tests" -ForegroundColor White
    Write-Host "4. Configurer les méthodes MFA pour les utilisateurs" -ForegroundColor White
}

# Exécuter la configuration
# Remplacer par l'ID réel du compte d'urgence
$emergencyId = "EMERGENCY-ACCOUNT-ID"
Initialize-EnterpriseSecurityPolicies -EmergencyAccountId $emergencyId
```

---

## 🎯 Résumé des commandes essentielles

| Action | Commande |
|--------|----------|
| **Lister politiques CA** | `Get-MgIdentityConditionalAccessPolicy` |
| **Créer politique** | `New-MgIdentityConditionalAccessPolicy -BodyParameter @{}` |
| **Modifier politique** | `Update-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId "id"` |
| **Supprimer politique** | `Remove-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId "id"` |
| **Créer emplacement** | `New-MgIdentityConditionalAccessNamedLocation` |
| **Lister emplacements** | `Get-MgIdentityConditionalAccessNamedLocation` |

---

## ⚠️ Bonnes pratiques

### ✅ À FAIRE
- Toujours exclure le compte d'urgence de TOUTES les politiques
- Tester avec "enabledForReportingButNotEnforced" avant d'activer
- Utiliser l'outil What-If pour simuler l'impact
- Documenter chaque politique et sa raison d'être
- Revoir les politiques trimestriellement
- Configurer plusieurs emplacements de confiance

### ❌ À ÉVITER
- Activer toutes les politiques en même temps sans test
- Oublier d'exclure le compte d'urgence
- Bloquer tous les administrateurs par erreur
- Ne pas surveiller les logs après activation
- Utiliser MFA par utilisateur au lieu de l'accès conditionnel

---

## 📚 Ressources complémentaires

- [Accès Conditionnel](https://learn.microsoft.com/en-us/azure/active-directory/conditional-access/)
- [MFA Azure AD](https://learn.microsoft.com/en-us/azure/active-directory/authentication/concept-mfa-howitworks)
- [Bonnes pratiques CA](https://learn.microsoft.com/en-us/azure/active-directory/conditional-access/best-practices)

---

**Date de création** : Novembre 2024  
**Version** : 1.0  
**Projet** : USS Enterprise - Entra ID Security