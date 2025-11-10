<#
.SYNOPSIS
    Script de configuration initiale de l'environnement USS Enterprise
.DESCRIPTION
    Ce script verifie et configure l'environnement de travail (Microsoft Graph uniquement)
#>

Write-Host "`n=== Configuration USS Enterprise ===" -ForegroundColor Cyan

# 1. Verifier PowerShell version
$psVersion = $PSVersionTable.PSVersion
Write-Host "`nPowerShell Version: $psVersion" -ForegroundColor Cyan

if ($psVersion.Major -lt 7) {
    Write-Warning "PowerShell 7+ recommande"
}

# 2. Verifier les modules
Write-Host "`n=== Modules ===" -ForegroundColor Yellow

$modules = @("Microsoft.Graph.Authentication", "Microsoft.Graph.Users", "Microsoft.Graph.Groups")

foreach ($module in $modules) {
    $installed = Get-Module -ListAvailable -Name $module
    if ($installed) {
        Write-Host "OK $module" -ForegroundColor Green
    } else {
        Write-Host "X $module - Installer: Install-Module $module" -ForegroundColor Red
    }
}

# 3. Verifier connexion Microsoft Graph
Write-Host "`n=== Connexion ===" -ForegroundColor Yellow

try {
    $context = Get-MgContext
    if ($context) {
        Write-Host "OK Microsoft Graph connecte" -ForegroundColor Green
        Write-Host "  Account: $($context.Account)" -ForegroundColor Cyan
        Write-Host "  TenantId: $($context.TenantId)" -ForegroundColor Cyan
        Write-Host "  Scopes: $($context.Scopes -join ', ')" -ForegroundColor Cyan
        
        # Obtenir les infos du tenant via Graph
        try {
            $org = Get-MgOrganization
            Write-Host "  Tenant Name: $($org.DisplayName)" -ForegroundColor Cyan
        } catch {
            Write-Host "  (Infos tenant non accessibles)" -ForegroundColor Gray
        }
    } else {
        Write-Host "X Microsoft Graph non connecte" -ForegroundColor Red
        Write-Host "  Lancer: Connect-MgGraph -Scopes 'User.ReadWrite.All','Group.ReadWrite.All'" -ForegroundColor Yellow
    }
} catch {
    Write-Host "X Microsoft Graph non connecte" -ForegroundColor Red
}

# 4. Creer les dossiers
Write-Host "`n=== Dossiers ===" -ForegroundColor Yellow

$folders = @("logs", "config", "tests/test-results")
foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        Write-Host "OK Cree: $folder" -ForegroundColor Green
    } else {
        Write-Host "OK Existe: $folder" -ForegroundColor Cyan
    }
}

# 5. Creer configuration par defaut
$configPath = "./config/settings.json"

if (-not (Test-Path $configPath)) {
    Write-Host "`n=== Configuration ===" -ForegroundColor Yellow
    
    $config = @{
        TenantSettings = @{
            TenantId = "f8cdef31-a31e-4b4a-93e4-5f571e91255a"
            TenantName = "uss-enterprise.onmicrosoft.com"
            DefaultDomain = "uss-enterprise.com"
        }
        Security = @{
            RequireMFA = $true
            AllowedLocations = @("France", "United States")
        }
        Groups = @{
            ExplorationTeam = "Equipe d'Exploration"
            MedicalTeam = "Equipe Medicale"
            EngineeringTeam = "Equipe d'Ingenierie"
            CommandTeam = "Equipe de Commandement"
        }
    }
    
    $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding utf8
    Write-Host "OK Configuration creee: $configPath" -ForegroundColor Green
} else {
    Write-Host "`nOK Configuration existe: $configPath" -ForegroundColor Cyan
}

# 6. Creer log
$logPath = "./logs/setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$logEntry = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Event = "Setup"
    Status = "Success"
    User = $env:USERNAME
}
$logEntry | ConvertTo-Json | Out-File -FilePath $logPath -Encoding utf8

Write-Host "`n=== Configuration terminee ===" -ForegroundColor Green
Write-Host "Log: $logPath" -ForegroundColor Cyan

Write-Host "`n=== NOTE IMPORTANTE ===" -ForegroundColor Yellow
Write-Host "Ton compte n'a pas les droits administrateur sur Azure AD legacy." -ForegroundColor Yellow
Write-Host "Nous utiliserons UNIQUEMENT Microsoft Graph pour ce projet." -ForegroundColor Yellow
Write-Host "C'est la methode moderne et recommandee par Microsoft !" -ForegroundColor Green

Write-Host "`n=== Prochaines etapes ===" -ForegroundColor Cyan
Write-Host "1. .\6_Creation_auto_groupes.ps1 (Microsoft Graph)" -ForegroundColor White
Write-Host "2. .\5_Creation_auto_utilisateurs.ps1 (Microsoft Graph)" -ForegroundColor White
Write-Host "3. .\3_Cree_Politique_Acces_Conditionnel.ps1 (Microsoft Graph)`n" -ForegroundColor White