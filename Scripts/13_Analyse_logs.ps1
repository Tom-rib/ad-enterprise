# scripts/13-analyze-logs.ps1

# Récupérer les logs de connexion des dernières 24h
$startDate = (Get-Date).AddDays(-1)
$signInLogs = Get-MgAuditLogSignIn -Filter "createdDateTime ge $($startDate.ToString('yyyy-MM-ddTHH:mm:ssZ'))"

# Identifier les activités suspectes
$suspiciousActivity = $signInLogs | Where-Object {
    $_.Status.ErrorCode -ne 0 -or  # Échecs de connexion
    $_.Location.CountryOrRegion -notin @("United States", "France") # Connexions depuis des pays non autorisés
}

# Afficher les résultats
Write-Host "`n=== ACTIVITÉS SUSPECTES DÉTECTÉES ===" -ForegroundColor Red
foreach ($activity in $suspiciousActivity) {
    Write-Host "`nUtilisateur : $($activity.UserPrincipalName)" -ForegroundColor Yellow
    Write-Host "Date : $($activity.CreatedDateTime)" -ForegroundColor Yellow
    Write-Host "Emplacement : $($activity.Location.City), $($activity.Location.CountryOrRegion)" -ForegroundColor Yellow
    Write-Host "IP : $($activity.IpAddress)" -ForegroundColor Yellow
    Write-Host "Statut : $($activity.Status.FailureReason)" -ForegroundColor Yellow
}

# Exporter dans un fichier
$suspiciousActivity | Export-Csv -Path "./logs/suspicious-activity.csv" -NoTypeInformation