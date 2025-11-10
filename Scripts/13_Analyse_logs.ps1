# scripts/13-analyze-logs.ps1

# Recuperer les logs de connexion des dernieres 24h
$startDate = (Get-Date).AddDays(-1)
$signInLogs = Get-MgAuditLogSignIn -Filter "createdDateTime ge $($startDate.ToString('yyyy-MM-ddTHH:mm:ssZ'))"

# Identifier les activites suspectes
$suspiciousActivity = $signInLogs | Where-Object {
    $_.Status.ErrorCode -ne 0 -or  # echecs de connexion
    $_.Location.CountryOrRegion -notin @("United States", "France") # Connexions depuis des pays non autorises
}

# Afficher les resultats
Write-Host "`n=== ACTIVITeS SUSPECTES DeTECTeES ===" -ForegroundColor Red
foreach ($activity in $suspiciousActivity) {
    Write-Host "`nUtilisateur : $($activity.UserPrincipalName)" -ForegroundColor Yellow
    Write-Host "Date : $($activity.CreatedDateTime)" -ForegroundColor Yellow
    Write-Host "Emplacement : $($activity.Location.City), $($activity.Location.CountryOrRegion)" -ForegroundColor Yellow
    Write-Host "IP : $($activity.IpAddress)" -ForegroundColor Yellow
    Write-Host "Statut : $($activity.Status.FailureReason)" -ForegroundColor Yellow
}

# Exporter dans un fichier
$suspiciousActivity | Export-Csv -Path "./logs/suspicious-activity.csv" -NoTypeInformation