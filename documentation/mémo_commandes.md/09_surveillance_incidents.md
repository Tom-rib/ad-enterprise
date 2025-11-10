# Guide 09 - Surveillance et Réponse aux Incidents

## 📚 À quoi ça sert ?

La **surveillance** et la **réponse aux incidents** permettent de détecter les activités suspectes, d'analyser les menaces et de réagir rapidement en cas d'attaque. C'est le système de défense en temps réel de votre infrastructure.

### Pourquoi surveiller ?
- **Détection précoce** : Identifier les attaques avant qu'elles ne causent des dégâts
- **Analyse** : Comprendre les patterns d'attaque
- **Conformité** : Répondre aux exigences réglementaires
- **Amélioration continue** : Ajuster les politiques de sécurité

---

## 📊 PARTIE 1 : ANALYSE DES LOGS

### Analyser les logs de connexion

```powershell
<#
.SYNOPSIS
    Analyser les logs de connexion pour détecter les activités suspectes
#>

# Se connecter avec les permissions nécessaires
Connect-MgGraph -Scopes "AuditLog.Read.All", "Directory.Read.All"

# Fonction pour analyser les logs
function Get-SuspiciousSignIns {
    param(
        [int]$DaysBack = 7
    )
    
    Write-Host "`n=== ANALYSE DES CONNEXIONS SUSPECTES ===" -ForegroundColor Cyan
    Write-Host "Période : Derniers $DaysBack jours`n" -ForegroundColor Yellow
    
    # Date de début
    $startDate = (Get-Date).AddDays(-$DaysBack).ToString("yyyy-MM-ddTHH:mm:ssZ")
    
    # Récupérer les logs de connexion
    $signIns = Get-MgAuditLogSignIn -Filter "createdDateTime ge $startDate" -All
    
    Write-Host "Total de connexions : $($signIns.Count)" -ForegroundColor Cyan
    
    # 1. Échecs de connexion
    $failedSignIns = $signIns | Where-Object { 
        $_.Status.ErrorCode -ne 0 -and $_.Status.ErrorCode -ne 50058
    }
    
    Write-Host "`n[1] Échecs de connexion : $($failedSignIns.Count)" -ForegroundColor Yellow
    
    if ($failedSignIns) {
        $topFailures = $failedSignIns | Group-Object UserPrincipalName | 
            Sort-Object Count -Descending | Select-Object -First 5
        
        Write-Host "Top 5 utilisateurs avec échecs :" -ForegroundColor Red
        foreach ($failure in $topFailures) {
            Write-Host "  - $($failure.Name) : $($failure.Count) échecs" -ForegroundColor White
        }
    }
    
    # 2. Connexions depuis des pays non autorisés
    $unauthorizedCountries = $signIns | Where-Object { 
        $_.Location.CountryOrRegion -and 
        $_.Location.CountryOrRegion -notin @("FR", "US", "France", "United States")
    }
    
    Write-Host "`n[2] Connexions depuis pays non autorisés : $($unauthorizedCountries.Count)" -ForegroundColor Yellow
    
    if ($unauthorizedCountries) {
        $countries = $unauthorizedCountries | Group-Object {$_.Location.CountryOrRegion} | 
            Sort-Object Count -Descending
        
        Write-Host "Pays détectés :" -ForegroundColor Red
        foreach ($country in $countries) {
            Write-Host "  - $($country.Name) : $($country.Count) tentatives" -ForegroundColor White
        }
    }
    
    # 3. Connexions multiples depuis différentes IP
    $suspiciousIPs = $signIns | Where-Object { $_.Status.ErrorCode -eq 0 } |
        Group-Object UserPrincipalName | Where-Object { $_.Count -gt 10 } |
        ForEach-Object {
            $user = $_.Name
            $ips = $_.Group | Select-Object -Unique IpAddress
            if ($ips.Count -gt 3) {
                [PSCustomObject]@{
                    User = $user
                    SignInCount = $_.Count
                    UniqueIPs = $ips.Count
                    IPs = ($ips.IpAddress -join ", ")
                }
            }
        }
    
    if ($suspiciousIPs) {
        Write-Host "`n[3] Utilisateurs avec connexions multiples (IP différentes) :" -ForegroundColor Yellow
        $suspiciousIPs | Format-Table User, SignInCount, UniqueIPs -AutoSize
    }
    
    # 4. Connexions administrateur
    $adminSignIns = $signIns | Where-Object { 
        $_.ResourceDisplayName -eq "Windows Azure Active Directory" -or
        $_.AppDisplayName -eq "Azure Portal"
    }
    
    Write-Host "`n[4] Connexions au portail Azure : $($adminSignIns.Count)" -ForegroundColor Yellow
    
    # 5. Connexions hors heures de travail
    $afterHours = $signIns | Where-Object {
        $hour = [datetime]::Parse($_.CreatedDateTime).Hour
        $hour -lt 7 -or $hour -gt 20  # Avant 7h ou après 20h
    }
    
    Write-Host "`n[5] Connexions hors heures (avant 7h ou après 20h) : $($afterHours.Count)" -ForegroundColor Yellow
    
    # Créer un rapport
    $report = @{
        AnalysisDate = Get-Date
        Period = "$DaysBack jours"
        TotalSignIns = $signIns.Count
        FailedSignIns = $failedSignIns.Count
        UnauthorizedCountries = $unauthorizedCountries.Count
        SuspiciousIPs = $suspiciousIPs.Count
        AdminSignIns = $adminSignIns.Count
        AfterHoursSignIns = $afterHours.Count
    }
    
    # Exporter les détails
    $failedSignIns | Select-Object CreatedDateTime, UserPrincipalName, @{
        Name='Location'; Expression={"$($_.Location.City), $($_.Location.CountryOrRegion)"}
    }, IpAddress, @{
        Name='Error'; Expression={$_.Status.FailureReason}
    } | Export-Csv "./logs/failed-signins-$(Get-Date -Format 'yyyyMMdd').csv" -NoTypeInformation -Encoding UTF8
    
    $unauthorizedCountries | Select-Object CreatedDateTime, UserPrincipalName, @{
        Name='Location'; Expression={"$($_.Location.City), $($_.Location.CountryOrRegion)"}
    }, IpAddress, AppDisplayName | Export-Csv "./logs/unauthorized-locations-$(Get-Date -Format 'yyyyMMdd').csv" -NoTypeInformation -Encoding UTF8
    
    Write-Host "`n✓ Rapports exportés dans ./logs/" -ForegroundColor Green
    
    return $report
}

# Exécuter l'analyse
$suspiciousActivity = Get-SuspiciousSignIns -DaysBack 7
```

### Analyser les logs d'audit

```powershell
<#
.SYNOPSIS
    Analyser les logs d'audit pour les changements sensibles
#>

function Get-SensitiveAuditChanges {
    param(
        [int]$DaysBack = 7
    )
    
    Write-Host "`n=== ANALYSE DES MODIFICATIONS SENSIBLES ===" -ForegroundColor Cyan
    
    $startDate = (Get-Date).AddDays(-$DaysBack).ToString("yyyy-MM-ddTHH:mm:ssZ")
    
    # Récupérer les logs d'audit
    $auditLogs = Get-MgAuditLogDirectoryAudit -Filter "activityDateTime ge $startDate" -All
    
    # 1. Modifications de rôles
    $roleChanges = $auditLogs | Where-Object { 
        $_.Category -eq "RoleManagement" 
    }
    
    Write-Host "`n[1] Modifications de rôles : $($roleChanges.Count)" -ForegroundColor Yellow
    
    if ($roleChanges) {
        foreach ($change in $roleChanges | Select-Object -First 10) {
            Write-Host "  $($change.ActivityDateTime) - $($change.OperationName)" -ForegroundColor White
            Write-Host "    Par : $($change.InitiatedBy.User.UserPrincipalName)" -ForegroundColor Gray
        }
    }
    
    # 2. Création/Suppression d'utilisateurs
    $userChanges = $auditLogs | Where-Object { 
        $_.OperationName -in @("Add user", "Delete user", "Update user")
    }
    
    Write-Host "`n[2] Modifications d'utilisateurs : $($userChanges.Count)" -ForegroundColor Yellow
    
    # 3. Modifications de politiques
    $policyChanges = $auditLogs | Where-Object { 
        $_.Category -eq "Policy" -or $_.OperationName -like "*policy*"
    }
    
    Write-Host "`n[3] Modifications de politiques : $($policyChanges.Count)" -ForegroundColor Yellow
    
    # 4. Modifications MFA
    $mfaChanges = $auditLogs | Where-Object { 
        $_.OperationName -like "*authentication*" -or
        $_.OperationName -like "*MFA*"
    }
    
    Write-Host "`n[4] Modifications MFA : $($mfaChanges.Count)" -ForegroundColor Yellow
    
    # Exporter
    $sensitiveChanges = @($roleChanges) + @($userChanges) + @($policyChanges) + @($mfaChanges)
    $sensitiveChanges | Select-Object ActivityDateTime, OperationName, Category, @{
        Name='InitiatedBy'; Expression={$_.InitiatedBy.User.UserPrincipalName}
    }, Result | Export-Csv "./logs/sensitive-changes-$(Get-Date -Format 'yyyyMMdd').csv" -NoTypeInformation -Encoding UTF8
    
    Write-Host "`n✓ Rapport exporté" -ForegroundColor Green
}

Get-SensitiveAuditChanges -DaysBack 7
```

---

## 🚨 PARTIE 2 : ALERTES EN TEMPS RÉEL

### Configurer Azure Monitor et Log Analytics

```powershell
<#
.SYNOPSIS
    Configurer Log Analytics et alertes
#>

# Nécessite le module Az
# Install-Module -Name Az -Force

Connect-AzAccount

# 1. Créer un workspace Log Analytics
$workspace = New-AzOperationalInsightsWorkspace `
    -ResourceGroupName "USS-Enterprise-RG" `
    -Name "USSEnterprise-LogAnalytics" `
    -Location "France Central" `
    -Sku "PerGB2018"

Write-Host "✓ Workspace Log Analytics créé" -ForegroundColor Green
Write-Host "  Workspace ID : $($workspace.CustomerId)" -ForegroundColor Cyan

# 2. Créer un groupe d'actions (pour les notifications)
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

# 3. Créer des alertes

# Alerte : Échecs de connexion multiples
$condition = New-AzActivityLogAlertCondition `
    -Field 'category' `
    -Equal 'Administrative'

$alertRule = Set-AzActivityLogAlert `
    -ResourceGroupName "USS-Enterprise-RG" `
    -Name "MultipleFailedSignIns" `
    -Condition $condition `
    -Action $actionGroup.Id `
    -Enabled $true `
    -Description "Alerte pour échecs de connexion multiples"

Write-Host "✓ Règle d'alerte créée" -ForegroundColor Green
```

### Requêtes KQL pour surveillance

```powershell
# Sauvegarder des requêtes KQL utiles

$kqlQueries = @{
    "Failed Sign-Ins Last 24h" = @"
SigninLogs
| where TimeGenerated > ago(24h)
| where ResultType != 0
| summarize count() by UserPrincipalName, ResultType, ResultDescription, bin(TimeGenerated, 1h)
| order by count_ desc
"@

    "Unauthorized Locations" = @"
SigninLogs
| where TimeGenerated > ago(7d)
| where Location !in ("FR", "US")
| project TimeGenerated, UserPrincipalName, Location, IPAddress, ResultType, AppDisplayName
| order by TimeGenerated desc
"@

    "Admin Activities" = @"
AuditLogs
| where TimeGenerated > ago(24h)
| where Category == "RoleManagement" or OperationName contains "role"
| project TimeGenerated, OperationName, InitiatedBy, TargetResources, Result
| order by TimeGenerated desc
"@

    "MFA Changes" = @"
AuditLogs
| where OperationName contains "authentication" or OperationName contains "MFA"
| where TimeGenerated > ago(7d)
| project TimeGenerated, OperationName, InitiatedBy, TargetResources
| order by TimeGenerated desc
"@

    "High-Risk Sign-Ins" = @"
SigninLogs
| where TimeGenerated > ago(24h)
| where RiskLevel == "high" or RiskState == "atRisk"
| project TimeGenerated, UserPrincipalName, RiskLevel, RiskDetail, Location, IPAddress
| order by TimeGenerated desc
"@
}

# Sauvegarder
$kqlQueries | ConvertTo-Json | Out-File "./config/kql-queries.json" -Encoding UTF8

Write-Host "✓ Requêtes KQL sauvegardées dans ./config/kql-queries.json" -ForegroundColor Green
```

---

## 🎭 PARTIE 3 : SIMULATION D'INCIDENTS

### Simuler une tentative de piratage

```powershell
<#
.SYNOPSIS
    Simuler un incident de sécurité et tester les procédures de réponse
#>

function Invoke-SecurityIncidentSimulation {
    param(
        [string]$CompromisedUserEmail = "test.user@uss-enterprise.com"
    )
    
    Write-Host "`n=== SIMULATION D'INCIDENT DE SÉCURITÉ ===" -ForegroundColor Red
    Write-Host "Scénario : Compte compromis détecté`n" -ForegroundColor Yellow
    
    Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"
    
    # ÉTAPE 1 : Détection
    Write-Host "[ÉTAPE 1/6] DÉTECTION de l'incident..." -ForegroundColor Cyan
    Start-Sleep -Seconds 2
    
    $compromisedUser = Get-MgUser -Filter "userPrincipalName eq '$CompromisedUserEmail'"
    
    if (-not $compromisedUser) {
        Write-Host "✗ Utilisateur non trouvé pour la simulation" -ForegroundColor Red
        return
    }
    
    Write-Host "✓ Activité suspecte détectée pour : $($compromisedUser.DisplayName)" -ForegroundColor Red
    Write-Host "  - Connexions depuis 5 pays différents en 2 heures" -ForegroundColor Yellow
    Write-Host "  - Tentatives d'accès à des données sensibles" -ForegroundColor Yellow
    Write-Host "  - Modification des paramètres MFA" -ForegroundColor Yellow
    
    # ÉTAPE 2 : Révocation des sessions
    Write-Host "`n[ÉTAPE 2/6] RÉVOCATION des sessions actives..." -ForegroundColor Cyan
    Start-Sleep -Seconds 1
    
    try {
        Revoke-MgUserSignInSession -UserId $compromisedUser.Id
        Write-Host "✓ Toutes les sessions révoquées" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Erreur lors de la révocation : $_" -ForegroundColor Yellow
    }
    
    # ÉTAPE 3 : Désactivation du compte
    Write-Host "`n[ÉTAPE 3/6] DÉSACTIVATION temporaire du compte..." -ForegroundColor Cyan
    Start-Sleep -Seconds 1
    
    Update-MgUser -UserId $compromisedUser.Id -AccountEnabled:$false
    Write-Host "✓ Compte désactivé temporairement" -ForegroundColor Green
    
    # ÉTAPE 4 : Forcer le changement de mot de passe
    Write-Host "`n[ÉTAPE 4/6] RÉINITIALISATION du mot de passe..." -ForegroundColor Cyan
    Start-Sleep -Seconds 1
    
    $newPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 16 | ForEach-Object {[char]$_})
    
    Update-MgUser -UserId $compromisedUser.Id -PasswordProfile @{
        Password = $newPassword
        ForceChangePasswordNextSignIn = $true
    }
    
    Write-Host "✓ Mot de passe réinitialisé" -ForegroundColor Green
    Write-Host "  Nouveau mot de passe temporaire : $newPassword" -ForegroundColor Yellow
    
    # ÉTAPE 5 : Notification
    Write-Host "`n[ÉTAPE 5/6] NOTIFICATION de l'équipe de sécurité..." -ForegroundColor Cyan
    Start-Sleep -Seconds 1
    
    $incident = @{
        IncidentId = "INC-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Timestamp = Get-Date
        User = $compromisedUser.UserPrincipalName
        DisplayName = $compromisedUser.DisplayName
        Actions = @(
            "Sessions révoquées",
            "Compte désactivé",
            "Mot de passe réinitialisé"
        )
        Status = "Contained - Awaiting Investigation"
        Severity = "High"
    }
    
    Write-Host "✓ Équipe sécurité notifiée" -ForegroundColor Green
    Write-Host "✓ Ticket créé : $($incident.IncidentId)" -ForegroundColor Green
    Write-Host "✓ Email envoyé à security@uss-enterprise.com" -ForegroundColor Green
    
    # ÉTAPE 6 : Rapport d'incident
    Write-Host "`n[ÉTAPE 6/6] GÉNÉRATION du rapport d'incident..." -ForegroundColor Cyan
    Start-Sleep -Seconds 1
    
    # Sauvegarder le rapport
    $incident | ConvertTo-Json | Out-File "./logs/incident-$($incident.IncidentId).json" -Encoding UTF8
    
    Write-Host "✓ Rapport sauvegardé : ./logs/incident-$($incident.IncidentId).json" -ForegroundColor Green
    
    # RÉSUMÉ
    Write-Host "`n=== INCIDENT MAÎTRISÉ ===" -ForegroundColor Green
    Write-Host "`nActions effectuées :" -ForegroundColor Cyan
    Write-Host "  ✓ Sessions utilisateur révoquées" -ForegroundColor White
    Write-Host "  ✓ Compte temporairement désactivé" -ForegroundColor White
    Write-Host "  ✓ Mot de passe réinitialisé" -ForegroundColor White
    Write-Host "  ✓ Équipe sécurité notifiée" -ForegroundColor White
    Write-Host "  ✓ Rapport d'incident créé" -ForegroundColor White
    
    Write-Host "`n⚠️  ACTIONS SUIVANTES :" -ForegroundColor Yellow
    Write-Host "1. Analyser les logs détaillés de connexion" -ForegroundColor White
    Write-Host "2. Identifier les ressources accédées" -ForegroundColor White
    Write-Host "3. Vérifier l'intégrité des données" -ForegroundColor White
    Write-Host "4. Contacter l'utilisateur pour validation" -ForegroundColor White
    Write-Host "5. Réactiver le compte après validation" -ForegroundColor White
    
    # Pour réactiver après investigation :
    Write-Host "`nPour réactiver le compte :" -ForegroundColor Cyan
    Write-Host "  Update-MgUser -UserId '$($compromisedUser.Id)' -AccountEnabled:`$true" -ForegroundColor Gray
    
    return $incident
}

# Exécuter la simulation
# Créer d'abord un utilisateur de test
$testUser = New-MgUser -DisplayName "Test User" `
    -UserPrincipalName "test.user@uss-enterprise.onmicrosoft.com" `
    -MailNickname "test.user" `
    -AccountEnabled:$true `
    -PasswordProfile @{Password="TempPassword123!"; ForceChangePasswordNextSignIn=$true} `
    -UsageLocation "FR"

# Simuler l'incident
$incident = Invoke-SecurityIncidentSimulation -CompromisedUserEmail $testUser.UserPrincipalName
```

### Procédure de réponse aux incidents

```powershell
<#
.SYNOPSIS
    Procédure complète de réponse aux incidents
#>

function Invoke-IncidentResponse {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("AccountCompromise", "UnauthorizedAccess", "DataBreach", "MalwareDetection")]
        [string]$IncidentType,
        
        [Parameter(Mandatory=$true)]
        [string]$TargetUser
    )
    
    Write-Host "`n=== PROCÉDURE DE RÉPONSE AUX INCIDENTS ===" -ForegroundColor Red
    Write-Host "Type : $IncidentType" -ForegroundColor Yellow
    Write-Host "Cible : $TargetUser`n" -ForegroundColor Yellow
    
    $user = Get-MgUser -Filter "userPrincipalName eq '$TargetUser'"
    
    if (-not $user) {
        Write-Host "✗ Utilisateur non trouvé" -ForegroundColor Red
        return
    }
    
    $actions = @()
    
    switch ($IncidentType) {
        "AccountCompromise" {
            # Compte compromis
            Write-Host "[1] Révocation des sessions..." -ForegroundColor Cyan
            Revoke-MgUserSignInSession -UserId $user.Id
            $actions += "Sessions révoquées"
            
            Write-Host "[2] Désactivation du compte..." -ForegroundColor Cyan
            Update-MgUser -UserId $user.Id -AccountEnabled:$false
            $actions += "Compte désactivé"
            
            Write-Host "[3] Réinitialisation MFA..." -ForegroundColor Cyan
            # Commande pour réinitialiser MFA (nécessite module MSOnline)
            $actions += "MFA à réinitialiser"
            
            Write-Host "[4] Changement de mot de passe..." -ForegroundColor Cyan
            $newPwd = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 20 | ForEach-Object {[char]$_})
            Update-MgUser -UserId $user.Id -PasswordProfile @{
                Password = $newPwd
                ForceChangePasswordNextSignIn = $true
            }
            $actions += "Mot de passe réinitialisé"
        }
        
        "UnauthorizedAccess" {
            # Accès non autorisé
            Write-Host "[1] Révocation des sessions..." -ForegroundColor Cyan
            Revoke-MgUserSignInSession -UserId $user.Id
            $actions += "Sessions révoquées"
            
            Write-Host "[2] Audit des accès..." -ForegroundColor Cyan
            $actions += "Audit des accès en cours"
        }
        
        "DataBreach" {
            # Fuite de données
            Write-Host "[1] Isolation du compte..." -ForegroundColor Cyan
            Update-MgUser -UserId $user.Id -AccountEnabled:$false
            $actions += "Compte isolé"
            
            Write-Host "[2] Révocation de tous les accès..." -ForegroundColor Cyan
            Revoke-MgUserSignInSession -UserId $user.Id
            $actions += "Accès révoqués"
            
            Write-Host "[3] Notification RGPD..." -ForegroundColor Cyan
            $actions += "Notification RGPD initiée"
        }
    }
    
    # Créer le rapport
    $report = @{
        IncidentId = "INC-$(Get-Date -Format 'yyyyMMddHHmmss')"
        Type = $IncidentType
        Timestamp = Get-Date
        TargetUser = $TargetUser
        ActionsPerformed = $actions
        Status = "Contained"
    }
    
    $report | ConvertTo-Json | Out-File "./logs/incident-response-$($report.IncidentId).json" -Encoding UTF8
    
    Write-Host "`n✓ Incident maîtrisé - Rapport : $($report.IncidentId)" -ForegroundColor Green
    
    return $report
}

# Exemple d'utilisation
# Invoke-IncidentResponse -IncidentType "AccountCompromise" -TargetUser "test.user@uss-enterprise.com"
```

---

## 📋 Dashboard de surveillance

```powershell
<#
.SYNOPSIS
    Dashboard de surveillance en temps réel
#>

function Show-SecurityDashboard {
    Connect-MgGraph -Scopes "AuditLog.Read.All", "Directory.Read.All"
    
    Clear-Host
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "       USS ENTERPRISE - SECURITY DASHBOARD               " -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Dernière mise à jour : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n" -ForegroundColor Gray
    
    # 1. Connexions dernières 24h
    $startDate = (Get-Date).AddHours(-24).ToString("yyyy-MM-ddTHH:mm:ssZ")
    $recent = Get-MgAuditLogSignIn -Filter "createdDateTime ge $startDate" -Top 1000
    
    Write-Host "CONNEXIONS (24h)" -ForegroundColor Yellow
    Write-Host "  Total : $($recent.Count)" -ForegroundColor White
    Write-Host "  Réussies : $(($recent | Where-Object {$_.Status.ErrorCode -eq 0}).Count)" -ForegroundColor Green
    Write-Host "  Échecs : $(($recent | Where-Object {$_.Status.ErrorCode -ne 0}).Count)" -ForegroundColor Red
    
    # 2. Emplacements
    $locations = $recent | Where-Object {$_.Location.CountryOrRegion} | 
        Group-Object {$_.Location.CountryOrRegion} | 
        Sort-Object Count -Descending | Select-Object -First 5
    
    Write-Host "`nTOP 5 EMPLACEMENTS" -ForegroundColor Yellow
    foreach ($loc in $locations) {
        Write-Host "  $($loc.Name) : $($loc.Count)" -ForegroundColor White
    }
    
    # 3. Applications les plus utilisées
    $apps = $recent | Group-Object AppDisplayName | 
        Sort-Object Count -Descending | Select-Object -First 5
    
    Write-Host "`nTOP 5 APPLICATIONS" -ForegroundColor Yellow
    foreach ($app in $apps) {
        Write-Host "  $($app.Name) : $($app.Count)" -ForegroundColor White
    }
    
    # 4. Alertes actives
    Write-Host "`nALERTES ACTIVES" -ForegroundColor Yellow
    
    $failed = $recent | Where-Object {$_.Status.ErrorCode -ne 0} | 
        Group-Object UserPrincipalName | 
        Where-Object {$_.Count -gt 5}
    
    if ($failed) {
        Write-Host "  ⚠️  $($failed.Count) utilisateurs avec >5 échecs" -ForegroundColor Red
    } else {
        Write-Host "  ✓ Aucune alerte" -ForegroundColor Green
    }
    
    Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
}

# Afficher le dashboard
Show-SecurityDashboard

# Pour rafraîchir automatiquement toutes les 5 minutes :
# while ($true) { Show-SecurityDashboard; Start-Sleep -Seconds 300 }
```

---

## 🎯 Résumé des commandes

| Action | Commande |
|--------|----------|
| **Analyser logs connexion** | `Get-MgAuditLogSignIn` |
| **Analyser logs audit** | `Get-MgAuditLogDirectoryAudit` |
| **Révoquer sessions** | `Revoke-MgUserSignInSession` |
| **Créer workspace** | `New-AzOperationalInsightsWorkspace` |
| **Créer alerte** | `Set-AzActivityLogAlert` |

---

## ✅ Checklist surveillance

- [ ] Log Analytics workspace créé
- [ ] Diagnostics Azure AD configurés (90 jours)
- [ ] Groupe d'actions email créé
- [ ] Alertes configurées (échecs, géo, admin)
- [ ] Requêtes KQL sauvegardées
- [ ] Script d'analyse des logs testé
- [ ] Procédure de réponse documentée
- [ ] Simulation d'incident effectuée
- [ ] Dashboard de surveillance créé

---

**Date de création** : Novembre 2024  
**Version** : 1.0  
**Projet** : USS Enterprise - Entra ID Security