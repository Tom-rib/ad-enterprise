# scripts/15-simulate-security-incident.ps1

function Invoke-SecurityIncidentSimulation {
    Write-Host "`n=== SIMULATION D'INCIDENT DE SeCURITe ===" -ForegroundColor Red
    Write-Host "Scenario : Tentative de piratage des systemes du vaisseau`n" -ForegroundColor Yellow
    
    # 1. Detecter l'incident
    Write-Host "[eTAPE 1] Detection de l'incident..." -ForegroundColor Cyan
    Start-Sleep -Seconds 2
    Write-Host "✓ Tentative d'acces non autorise detectee sur le compte : compromised.user@uss-enterprise.com" -ForegroundColor Red
    
    # 2. Reinitialiser les acces
    Write-Host "`n[eTAPE 2] Reinitialisation des acces..." -ForegroundColor Cyan
    $compromisedUser = Get-MgUser -Filter "userPrincipalName eq 'compromised.user@uss-enterprise.com'"
    
    # Revoquer toutes les sessions
    Revoke-MgUserSignInSession -UserId $compromisedUser.Id
    Write-Host "✓ Sessions revoquees pour l'utilisateur compromis" -ForegroundColor Green
    
    # Forcer le changement de mot de passe
    Update-MgUser -UserId $compromisedUser.Id -PasswordProfile @{
        ForceChangePasswordNextSignIn = $true
    }
    Write-Host "✓ Changement de mot de passe obligatoire active" -ForegroundColor Green
    
    # 3. Mise en quarantaine
    Write-Host "`n[eTAPE 3] Mise en quarantaine des systemes..." -ForegroundColor Cyan
    
    # Desactiver temporairement le compte
    Update-MgUser -UserId $compromisedUser.Id -AccountEnabled:$false
    Write-Host "✓ Compte utilisateur desactive temporairement" -ForegroundColor Green
    
    # 4. Notification
    Write-Host "`n[eTAPE 4] Notification de l'equipe de securite..." -ForegroundColor Cyan
    Write-Host "✓ Email envoye a security@uss-enterprise.com" -ForegroundColor Green
    Write-Host "✓ Ticket d'incident cree : INC-2024-001" -ForegroundColor Green
    
    # 5. Generation du rapport
    Write-Host "`n[eTAPE 5] Generation du rapport d'incident..." -ForegroundColor Cyan
    $report = @{
        IncidentId = "INC-2024-001"
        DateTime = Get-Date
        User = $compromisedUser.UserPrincipalName
        Action = "Account compromised - Access revoked"
        Status = "Contained"
    }
    
    $report | ConvertTo-Json | Out-File "./logs/incident-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    Write-Host "✓ Rapport d'incident enregistre" -ForegroundColor Green
    
    Write-Host "`n=== INCIDENT MAÎTRISe ===" -ForegroundColor Green
}

# Lancer la simulation
Invoke-SecurityIncidentSimulation