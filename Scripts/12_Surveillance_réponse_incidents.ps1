# scripts/12-setup-monitoring.ps1

# Se connecter à Azure Monitor
Connect-AzAccount

# Créer un groupe d'actions pour les alertes
$actionGroup = New-AzActionGroup `
    -ResourceGroupName "USS-Enterprise-RG" `
    -Name "SecurityAlerts" `
    -ShortName "SecAlert" `
    -EmailReceiver @{
        Name = "SecurityTeam"
        EmailAddress = "security@uss-enterprise.com"
    }

Write-Host "Groupe d'actions créé pour les alertes de sécurité" -ForegroundColor Green