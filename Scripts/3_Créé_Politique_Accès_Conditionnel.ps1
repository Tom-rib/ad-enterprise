# scripts/03-conditional-access-policy.ps1

# Créer une politique d'accès conditionnel
$policy = @{
    displayName = "Restriction géographique - USS Enterprise"
    state = "enabled"
    conditions = @{
        locations = @{
            includeLocations = @("All")
            excludeLocations = @("AllTrusted")
        }
        users = @{
            includeUsers = @("All")
        }
    }
    grantControls = @{
        operator = "OR"
        builtInControls = @("block")
    }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $policy