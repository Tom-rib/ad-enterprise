# scripts/07-apply-security-policies.ps1

# Fonction pour appliquer une politique à un groupe
function Set-MissionSecurityPolicy {
    param(
        [string]$GroupId,
        [string]$PolicyName
    )
    
    # Créer une politique spécifique pour missions sensibles
    $policy = @{
        displayName = $PolicyName
        state = "enabled"
        conditions = @{
            users = @{
                includeGroups = @($GroupId)
            }
            applications = @{
                includeApplications = @("All")
            }
        }
        grantControls = @{
            operator = "AND"
            builtInControls = @("mfa", "compliantDevice")
        }
    }
    
    New-MgIdentityConditionalAccessPolicy -BodyParameter $policy
    
    Write-Host "Politique de sécurité appliquée : $PolicyName" -ForegroundColor Green
}

# Appliquer aux équipes sensibles
Set-MissionSecurityPolicy -GroupId $explorationTeam.Id -PolicyName "Sécurité Mission Exploration"