# scripts/6_Creation_auto_groupes.ps1

<#
.SYNOPSIS
    Creation automatique des groupes USS Enterprise
.DESCRIPTION
    Cree les groupes de securite pour les differentes equipes du vaisseau
#>

Write-Host "`n=== Creation des Groupes USS Enterprise ===" -ForegroundColor Cyan

# Fonction pour creer un groupe
function New-EnterpriseTeam {
    param(
        [string]$TeamName,
        [string]$Description
    )
    
    try {
        $group = New-MgGroup -DisplayName $TeamName `
            -Description $Description `
            -MailEnabled:$false `
            -SecurityEnabled:$true `
            -MailNickname ($TeamName -replace '\s','').ToLower()
        
        Write-Host "OK Groupe cree: $TeamName (ID: $($group.Id))" -ForegroundColor Green
        return $group
    } catch {
        Write-Host "ERREUR Creation groupe $TeamName : $_" -ForegroundColor Red
        return $null
    }
}

# Definition des groupes
$groupsToCreate = @(
    @{
        Name = "Equipe de Commandement"
        Description = "Capitaine et officiers de commandement"
    },
    @{
        Name = "Officiers Superieurs"
        Description = "Tous les officiers de rang superieur"
    },
    @{
        Name = "Equipe d'Exploration"
        Description = "Membres des missions d'exploration"
    },
    @{
        Name = "Equipe Medicale"
        Description = "Personnel medical du vaisseau"
    },
    @{
        Name = "Equipe d'Ingenierie"
        Description = "Ingenieurs et techniciens"
    },
    @{
        Name = "Equipe de Securite"
        Description = "Personnel de securite"
    },
    @{
        Name = "Equipe Scientifique"
        Description = "Scientifiques et analystes"
    }
)

# Creer tous les groupes
Write-Host "`nCreation de $($groupsToCreate.Count) groupes...`n" -ForegroundColor Yellow

$createdGroups = @{}
$successCount = 0
$errorCount = 0

foreach ($groupDef in $groupsToCreate) {
    $group = New-EnterpriseTeam -TeamName $groupDef.Name -Description $groupDef.Description
    
    if ($group) {
        $createdGroups[$groupDef.Name] = @{
            Id = $group.Id
            DisplayName = $group.DisplayName
            Description = $groupDef.Description
        }
        $successCount++
    } else {
        $errorCount++
    }
    
    Start-Sleep -Milliseconds 500
}

# Sauvegarder les IDs des groupes
$configPath = "../config/groups.json"
if (Test-Path $configPath) {
    Write-Host "`nSauvegarde des informations des groupes..." -ForegroundColor Yellow
    $createdGroups | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding utf8
    Write-Host "OK Groupes sauvegardes dans: $configPath" -ForegroundColor Green
}

# Resume
Write-Host "`n=== Resume ===" -ForegroundColor Cyan
Write-Host "Groupes crees avec succes: $successCount" -ForegroundColor Green
Write-Host "Erreurs: $errorCount" -ForegroundColor $(if($errorCount -gt 0){"Red"}else{"Green"})

# Afficher la liste des groupes crees
Write-Host "`n=== Groupes crees ===" -ForegroundColor Cyan
foreach ($key in $createdGroups.Keys) {
    Write-Host "- $key" -ForegroundColor White
    Write-Host "  ID: $($createdGroups[$key].Id)" -ForegroundColor Gray
}

Write-Host "`n=== Prochaine etape ===" -ForegroundColor Cyan
Write-Host "Creer les utilisateurs: .\5_Creation_auto_utilisateurs.ps1`n" -ForegroundColor White