# SCRIPT (14 min)

[SLIDE 1 - 10s]
Bonjour, projet de sécurisation de l'infrastructure 
USS Enterprise avec Microsoft Entra ID.

[SLIDE 2 - 1min]
Le projet s'articule autour de 4 objectifs principaux :
1. Sécurité avancée avec politiques de détection
2. Automatisation complète via PowerShell
3. Intégration d'applications avec SSO
4. Surveillance et réponse aux incidents

[SLIDE 3 - 1min]
Pour structurer tout cela, j'ai utilisé un modèle 
en 3 tiers pour séparer les niveaux de privilèges...

[SLIDE 4 - 2min]
OBJECTIF 1 : Sécurité avancée.
J'ai mis en place 3 politiques principales :
- Détection et blocage des attaques
- MFA obligatoire pour 100% des officiers supérieurs
- Restriction géographique : seules France et USA autorisées

Exemple concret : J'ai testé avec un VPN au Japon, 
la connexion a été immédiatement bloquée.

[SLIDE 5 - 1min]
OBJECTIF 2 : Automatisation PowerShell.
J'ai créé 15 scripts pour automatiser toute la gestion.
7 utilisateurs et 7 groupes créés automatiquement.
Ce qui prenait 30 minutes manuellement prend maintenant 
3 minutes avec mes scripts. Gain de 90%.

[SLIDE 6 - 1min]
OBJECTIF 3 : Intégration des applications.
Deux applications intégrées :
- Captain's Log avec SSO, connexion en un clic
- Repair Management personnalisée avec 3 rôles différents
  Les ingénieurs peuvent modifier, les techniciens 
  seulement consulter.

[SLIDE 7 - 2min]
OBJECTIF 4 : Surveillance et incidents.
J'ai configuré Azure Log Analytics pour surveiller 
tous les accès. 4 alertes configurées pour détecter 
les activités suspectes.

J'ai simulé un incident : compte compromis détecté 
et neutralisé en moins de 2 minutes avec révocation 
des sessions et mise en quarantaine.

[SLIDE 8 - 3min]
DÉMONSTRATION : [Suivre le script démo]
Je vais vous montrer les 4 objectifs en action...

[SLIDE 9 - 1min]
Résultats : Tous les objectifs sont atteints.
Sécurité, automatisation, applications, surveillance : 
tout est opérationnel et testé.

[SLIDE 10 - 1min]
En conclusion, l'infrastructure USS Enterprise est 
maintenant sécurisée selon les 4 axes demandés.
Tout est documenté et disponible sur GitHub.

Merci ! Des questions ?
```

---

## ✅ CHECKLIST ALIGNEMENT CAHIER DES CHARGES
```
OBJECTIF 1 : SÉCURITÉ AVANCÉE
─────────────────────────────────────────
□ Politiques détection/blocage attaques → Slide 4
□ MFA officiers supérieurs → Slide 4
□ Restriction emplacements → Slide 4
□ Tests avec VPN → Slide 4 + Démo

OBJECTIF 2 : AUTOMATISATION POWERSHELL
─────────────────────────────────────────
□ Scripts gestion utilisateurs → Slide 5
□ Scripts gestion groupes → Slide 5
□ Application auto politiques → Slide 5
□ Montrer les scripts → Démo

OBJECTIF 3 : INTÉGRATION APPLICATIONS
─────────────────────────────────────────
□ Captain's Log + SSO → Slide 6
□ Repair Management + rôles → Slide 6
□ Tests permissions → Slide 6
□ Montrer dans portail → Démo

OBJECTIF 4 : SURVEILLANCE & INCIDENTS
─────────────────────────────────────────
□ Surveillance accès → Slide 7
□ Analyse logs → Slide 7
□ Alertes configurées → Slide 7
□ Simulation incident → Slide 7
□ Montrer Log Analytics → Démo