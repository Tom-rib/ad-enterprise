# scripts/14-create-alerts.ps1

# Créer une alerte pour les connexions depuis des emplacements non reconnus
$alertRule = New-AzMetricAlertRuleV2 `
    -ResourceGroupName "USS-Enterprise-RG" `
    -Name "UnauthorizedLocationAlert" `
    -Description "Alerte pour connexions depuis des zones non reconnues" `
    -Severity 2 `
    -TargetResourceId "/subscriptions/{subscription-id}/resourceGroups/USS-Enterprise-RG" `
    -Condition $condition `
    -ActionGroupId $actionGroup.Id

Write-Host "Règle d'alerte créée : UnauthorizedLocationAlert" -ForegroundColor Green