# scripts/11-test-app-access.ps1

# Fonction pour tester l'accès d'un utilisateur
function Test-UserAppAccess {
    param(
        [string]$UserPrincipalName,
        [string]$AppId
    )
    
    $user = Get-MgUser -Filter "userPrincipalName eq '$UserPrincipalName'"
    $assignments = Get-MgUserAppRoleAssignment -UserId $user.Id
    
    $hasAccess = $assignments | Where-Object {$_.ResourceId -eq $AppId}
    
    if ($hasAccess) {
        Write-Host "✓ $UserPrincipalName a accès à l'application" -ForegroundColor Green
    } else {
        Write-Host "✗ $UserPrincipalName n'a PAS accès à l'application" -ForegroundColor Red
    }
}

# Tester les accès
Test-UserAppAccess -UserPrincipalName "montgomery.scott@uss-enterprise.com" -AppId $repairSP.Id
Test-UserAppAccess -UserPrincipalName "james.kirk@uss-enterprise.com" -AppId $repairSP.Id