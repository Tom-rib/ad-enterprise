# scripts/12-setup-monitoring.ps1

# Se connecter a Azure Monitor
Connect-AzAccount

# Creer un groupe d'actions pour les alertes
$actionGroup = New-AzActionGroup `
    -ResourceGroupName "USS-Enterprise-RG" `
    -Name "SecurityAlerts" `
    -ShortName "SecAlert" `
    -EmailReceiver @{
        Name = "SecurityTeam"
        EmailAddress = "security@uss-enterprise.com"
    }

Write-Host "Groupe d'actions cree pour les alertes de securite" -ForegroundColor Green