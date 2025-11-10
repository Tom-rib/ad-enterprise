# scripts/11-test-app-access.ps1

# Fonction pour tester l'acces d'un utilisateur
function Test-UserAppAccess {
    param(
        [string]$UserPrincipalName,
        [string]$AppId
    )
    
    $user = Get-MgUser -Filter "userPrincipalName eq '$UserPrincipalName'"
    $assignments = Get-MgUserAppRoleAssignment -UserId $user.Id
    
    $hasAccess = $assignments | Where-Object {$_.ResourceId -eq $AppId}
    
    if ($hasAccess) {
        Write-Host "✓ $UserPrincipalName a acces a l'application" -ForegroundColor Green
    } else {
        Write-Host "✗ $UserPrincipalName n'a PAS acces a l'application" -ForegroundColor Red
    }
}

# Tester les acces
Test-UserAppAccess -UserPrincipalName "montgomery.scott@uss-enterprise.com" -AppId $repairSP.Id
Test-UserAppAccess -UserPrincipalName "james.kirk@uss-enterprise.com" -AppId $repairSP.Id