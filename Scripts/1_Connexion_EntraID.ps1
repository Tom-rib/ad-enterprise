# scripts/01-connect-entraid.ps1

# Connexion a Azure AD
Connect-AzureAD

# Ou avec Microsoft Graph (methode moderne)
Connect-MgGraph -Scopes "User.ReadWrite.All", "Group.ReadWrite.All", "Policy.ReadWrite.ConditionalAccess"