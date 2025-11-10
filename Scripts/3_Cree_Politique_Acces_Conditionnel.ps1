# scripts/03-conditional-access-policy.ps1

# Creer une politique d'acces conditionnel
$policy = @{
    displayName = "Restriction geographique - USS Enterprise"
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