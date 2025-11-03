# scripts/06-manage-groups.ps1

# Fonction pour créer un groupe
function New-EnterpriseTeam {
    param(
        [string]$TeamName,
        [string]$Description
    )
    
    $group = New-MgGroup -DisplayName $TeamName `
        -Description $Description `
        -MailEnabled:$false `
        -SecurityEnabled:$true `
        -MailNickname ($TeamName -replace '\s','')
    
    Write-Host "Groupe créé : $TeamName" -ForegroundColor Green
    return $group
}

# Créer les équipes
$explorationTeam = New-EnterpriseTeam -TeamName "Équipe d'Exploration" -Description "Membres des missions d'exploration"
$medicalTeam = New-EnterpriseTeam -TeamName "Équipe Médicale" -Description "Personnel médical du vaisseau"
$engineeringTeam = New-EnterpriseTeam -TeamName "Équipe d'Ingénierie" -Description "Ingénieurs et techniciens"

# Fonction pour ajouter un membre à un groupe
function Add-EnterpriseTeamMember {
    param(
        [string]$GroupId,
        [string]$UserPrincipalName
    )
    
    $user = Get-MgUser -Filter "userPrincipalName eq '$UserPrincipalName'"
    
    New-MgGroupMember -GroupId $GroupId -DirectoryObjectId $user.Id
    
    Write-Host "Utilisateur $UserPrincipalName ajouté au groupe" -ForegroundColor Green
}

# Exemples d'ajout de membres
Add-EnterpriseTeamMember -GroupId $medicalTeam.Id -UserPrincipalName "leonard.mccoy@uss-enterprise.com"
Add-EnterpriseTeamMember -GroupId $engineeringTeam.Id -UserPrincipalName "montgomery.scott@uss-enterprise.com"