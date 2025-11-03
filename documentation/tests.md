# Procédures de Test

## Test 1 : Authentification Multi-Facteurs
**Objectif** : Vérifier que le MFA est actif pour les officiers

**Procédure** :
1. Se connecter avec un compte officier
2. Vérifier la demande de second facteur
3. Valider l'authentification

**Résultat attendu** : Authentification réussie après validation du second facteur

## Test 2 : Politique d'accès conditionnel
**Objectif** : Vérifier le blocage depuis des emplacements non autorisés

**Procédure** :
1. Utiliser un VPN pour simuler une connexion depuis un pays non autorisé
2. Tenter de se connecter
3. Vérifier le message de blocage

**Résultat attendu** : Accès refusé avec message explicite

## Test 3 : Permissions applicatives
...