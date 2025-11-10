# scripts/10-assign-app-roles.ps1

# Obtenir le rôle Engineer
$role = (Get-MgServicePrincipal -ServicePrincipalId $repairSP.Id).AppRoles | 
    Where-Object {$_.Value -eq "Engineer"}

# Assigner le rôle aux ingenieurs
$engineers = Get-MgGroupMember -GroupId $engineeringTeam.Id

foreach ($engineer in $engineers) {
    New-MgServicePrincipalAppRoleAssignment `
        -ServicePrincipalId $repairSP.Id `
        -PrincipalId $engineer.Id `
        -ResourceId $repairSP.Id `
        -AppRoleId $role.Id
    
    Write-Host "Rôle Engineer assigne a $($engineer.DisplayName)" -ForegroundColor Green
}