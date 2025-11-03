# scripts/15-simulate-security-incident.ps1

function Invoke-SecurityIncidentSimulation {
    Write-Host "`n=== SIMULATION D'INCIDENT DE SÉCURITÉ ===" -ForegroundColor Red
    Write-Host "Scénario : Tentative de piratage des systèmes du vaisseau`n" -ForegroundColor Yellow
    
    # 1. Détecter l'incident
    Write-Host "[ÉTAPE 1] Détection de l'incident..." -ForegroundColor Cyan
    Start-Sleep -Seconds 2
    Write-Host "✓ Tentative d'accès non autorisé détectée sur le compte : compromised.user@uss-enterprise.com" -ForegroundColor Red
    
    # 2. Réinitialiser les accès
    Write-Host "`n[ÉTAPE 2] Réinitialisation des accès..." -ForegroundColor Cyan
    $compromisedUser = Get-MgUser -Filter "userPrincipalName eq 'compromised.user@uss-enterprise.com'"
    
    # Révoquer toutes les sessions
    Revoke-MgUserSignInSession -UserId $compromisedUser.Id
    Write-Host "✓ Sessions révoquées pour l'utilisateur compromis" -ForegroundColor Green
    
    # Forcer le changement de mot de passe
    Update-MgUser -UserId $compromisedUser.Id -PasswordProfile @{
        ForceChangePasswordNextSignIn = $true
    }
    Write-Host "✓ Changement de mot de passe obligatoire activé" -ForegroundColor Green
    
    # 3. Mise en quarantaine
    Write-Host "`n[ÉTAPE 3] Mise en quarantaine des systèmes..." -ForegroundColor Cyan
    
    # Désactiver temporairement le compte
    Update-MgUser -UserId $compromisedUser.Id -AccountEnabled:$false
    Write-Host "✓ Compte utilisateur désactivé temporairement" -ForegroundColor Green
    
    # 4. Notification
    Write-Host "`n[ÉTAPE 4] Notification de l'équipe de sécurité..." -ForegroundColor Cyan
    Write-Host "✓ Email envoyé à security@uss-enterprise.com" -ForegroundColor Green
    Write-Host "✓ Ticket d'incident créé : INC-2024-001" -ForegroundColor Green
    
    # 5. Génération du rapport
    Write-Host "`n[ÉTAPE 5] Génération du rapport d'incident..." -ForegroundColor Cyan
    $report = @{
        IncidentId = "INC-2024-001"
        DateTime = Get-Date
        User = $compromisedUser.UserPrincipalName
        Action = "Account compromised - Access revoked"
        Status = "Contained"
    }
    
    $report | ConvertTo-Json | Out-File "./logs/incident-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    Write-Host "✓ Rapport d'incident enregistré" -ForegroundColor Green
    
    Write-Host "`n=== INCIDENT MAÎTRISÉ ===" -ForegroundColor Green
}

# Lancer la simulation
Invoke-SecurityIncidentSimulation