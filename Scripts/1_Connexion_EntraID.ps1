# scripts/01-connect-entraid.ps1

# Connexion à Azure AD
Connect-AzureAD

# Ou avec Microsoft Graph (méthode moderne)
Connect-MgGraph -Scopes "User.ReadWrite.All", "Group.ReadWrite.All", "Policy.ReadWrite.ConditionalAccess"