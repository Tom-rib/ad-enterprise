# scripts/07-apply-security-policies.ps1

# Fonction pour appliquer une politique a un groupe
function Set-MissionSecurityPolicy {
    param(
        [string]$GroupId,
        [string]$PolicyName
    )
    
    # Creer une politique specifique pour missions sensibles
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
    
    Write-Host "Politique de securite appliquee : $PolicyName" -ForegroundColor Green
}

# Appliquer aux equipes sensibles
Set-MissionSecurityPolicy -GroupId $explorationTeam.Id -PolicyName "Securite Mission Exploration"