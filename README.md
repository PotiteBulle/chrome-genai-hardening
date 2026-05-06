# Chrome GenAI Hardening

Toolkit PowerShell de durcissement pour Google Chrome sous Windows.

Ce projet permet de désactiver le téléchargement du modèle IA local utilisé par certaines fonctionnalités GenAI de Chrome, notamment Gemini Nano ou les modèles embarqués. Il permet aussi de désactiver plusieurs intégrations IA de Chrome via les règles locales Chrome Enterprise.

L'objectif est simple : reprendre le contrôle sur les fonctionnalités IA de Chrome, réduire les téléchargements automatiques non souhaités, limiter les intégrations IA côté navigateur, supprimer les fichiers de modèle déjà présents et générer un rapport de vérification exploitable dans une démarche Privacy Hardening.

## Pourquoi ce projet existe

Ce projet a été créé après la lecture de l'article suivant :

https://www.thatprivacyguy.com/blog/chrome-silent-nano-install/

L'article explique que Chrome peut télécharger localement un modèle IA de grande taille lié à Gemini Nano / GenAI. Ce dépôt propose une réponse défensive, documentée et réversible : utiliser les policies Chrome Enterprise disponibles sous Windows pour empêcher le téléchargement du modèle local, puis nettoyer les artefacts déjà présents.

Le projet a ensuite été étendu pour désactiver d'autres fonctionnalités IA intégrées à Chrome, comme Gemini, AI Mode, Help Me Write, History Search, Create Themes, DevTools GenAI et certaines fonctions de partage de contenu avec les services IA.

Ce projet ne cherche pas à modifier Chrome ni à contourner ses protections. Il applique uniquement des règles de configuration administrateurice.

## Objectifs du projet

Ce toolkit permet de :

- Désactiver le téléchargement du modèle IA local GenAI / Gemini Nano de Chrome.
- Désactiver plusieurs fonctionnalités IA intégrées à Chrome.
- Appliquer des policies Chrome Enterprise via le registre Windows.
- Supprimer les dossiers locaux liés aux modèles IA déjà téléchargés.
- Nettoyer certaines anciennes règles pouvant provoquer des erreurs dans `chrome://policy/`.
- Générer un rapport de vérification.
- Fournir une base propre pour l'audit, le hardening et la documentation sécurité.

## Contexte

Certaines versions récentes de Chrome peuvent télécharger des composants locaux liés aux fonctionnalités d'intelligence artificielle, comme Gemini Nano ou des modèles utilisés par les API IA intégrées.

Ces fonctionnalités peuvent être utiles pour certains usages, mais elles peuvent aussi poser des questions de :

- Confidentialité.
- Contrôle utilisateur.
- Surface d'attaque.
- Consommation disque.
- Gouvernance des fonctionnalités IA.
- Conformité dans un environnement professionnel ou personnel durci.

Ce projet propose une approche défensive et transparente pour désactiver ces fonctionnalités via des mécanismes documentés de configuration locale.

## Avertissement

Ce projet est destiné au durcissement de la vie privée, à l'administration système et à un usage défensif.

Il ne modifie pas les binaires de Chrome, ne contourne pas de mécanisme de sécurité et n'effectue aucune action offensive.

Le script applique uniquement des règles locales Windows / Chrome Enterprise et supprime des fichiers de modèle locaux lorsque ceux-ci sont présents.

Utilise ce script uniquement sur une machine dont tu es propriétaire ou que tu es autorisé à administrer.

## Arborescence

```text
chrome-genai-hardening/
├── README.md
├── LICENSE
├── .gitignore
├── scripts/
│   ├── Disable-Chrome-GenAI.ps1
│   ├── Disable-Chrome-AI-Features.ps1
│   └── Restore-Chrome-GenAI.ps1
├── docs/
│   └── policy-explanation.md
└── reports/
    └── example-report.md
```

## Scripts disponibles

### Disable-Chrome-GenAI.ps1

Script ciblé sur le modèle IA local.

Il applique la policy suivante :

```text
GenAILocalFoundationalModelSettings = 1
```

Cette règle indique à Chrome de ne pas télécharger le modèle IA local utilisé par certaines fonctionnalités GenAI, notamment Gemini Nano.

Ce script supprime aussi certains dossiers locaux liés aux modèles IA si ceux-ci sont présents.

### Disable-Chrome-AI-Features.ps1

Script renforcé pour désactiver un maximum de fonctionnalités IA intégrées à Chrome.

Il applique plusieurs policies Chrome Enterprise locales, dont :

```text
AIModeSettings = 1
CreateThemesSettings = 2
DevToolsGenAiSettings = 2
GeminiActOnWebSettings = 1
GeminiSettings = 1
GenAILocalFoundationalModelSettings = 1
HelpMeWriteSettings = 2
HistorySearchSettings = 2
SearchContentSharingSettings = 1
```

Ce script est destiné aux personnes qui ne veulent pas d'intégrations IA dans Chrome côté navigateur.

### Restore-Chrome-GenAI.ps1

Script de restauration.

Il supprime les policies appliquées par les scripts de durcissement afin de revenir au comportement par défaut de Chrome.

## Fonctionnement

Les scripts appliquent des policies Chrome Enterprise locales dans le registre Windows :

```text
HKLM:\SOFTWARE\Policies\Google\Chrome
```

Ces règles sont ensuite visibles dans Chrome via :

```text
chrome://policy/
```

Après application, il faut cliquer sur :

```text
Reload policies
```

ou :

```text
Actualiser les règles
```

## Policies utilisées par le mode renforcé

Le mode renforcé applique les règles suivantes :

```text
AIModeSettings                       = 1
CreateThemesSettings                 = 2
DevToolsGenAiSettings                = 2
GeminiActOnWebSettings               = 1
GeminiSettings                       = 1
GenAILocalFoundationalModelSettings  = 1
HelpMeWriteSettings                  = 2
HistorySearchSettings                = 2
SearchContentSharingSettings         = 1
```

Sur une machine de test, ces policies ont été validées dans `chrome://policy/` avec l'état `OK`.

## Note concernant GenAiDefaultSettings

La policy suivante n'est pas utilisée par ce projet :

```text
GenAiDefaultSettings
```

Certaines installations de Chrome peuvent ignorer cette règle lorsqu'elle est configurée localement via le registre Windows. Dans ce cas, Chrome affiche une erreur dans `chrome://policy/` indiquant que la règle est ignorée, car elle n'est pas configurée par une source cloud.

Pour éviter cette erreur, le projet n'utilise pas `GenAiDefaultSettings`.

Les scripts peuvent toutefois supprimer cette ancienne règle si elle est déjà présente sur la machine.

## Prérequis

- Windows 10 ou Windows 11.
- Google Chrome installé.
- PowerShell.
- Droits administrateurice.
- Accès au registre Windows.

## Installation

Clone le dépôt :

```powershell
git clone https://github.com/PotiteBulle/chrome-genai-hardening
cd chrome-genai-hardening
```

Ou télécharge simplement les scripts depuis le dossier :

```text
scripts/
```

## Utilisation du mode ciblé

Ouvre PowerShell en administrateurice, puis exécute :

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\scripts\Disable-Chrome-GenAI.ps1
```

Ce mode cible principalement le modèle IA local GenAI / Gemini Nano.

## Utilisation du mode renforcé

Ouvre PowerShell en administrateurice, puis exécute :

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\scripts\Disable-Chrome-AI-Features.ps1
```

Ce mode désactive plusieurs fonctionnalités IA intégrées à Chrome.

Il est recommandé si l'objectif est de réduire au maximum les fonctionnalités IA côté navigateur.

## Ce que fait le mode renforcé

Le script renforcé va :

1. Vérifier les droits administrateurice.
2. Créer la clé de policy Chrome si elle n'existe pas.
3. Appliquer plusieurs policies IA Chrome Enterprise.
4. Appliquer `GenAILocalFoundationalModelSettings = 1`.
5. Supprimer l'ancienne règle `GenAiDefaultSettings` si elle existe.
6. Rechercher les dossiers locaux liés aux modèles IA.
7. Supprimer les dossiers trouvés.
8. Générer un rapport de vérification.

## Vérification dans Chrome

Après l'exécution du script, ouvre Chrome et va sur :

```text
chrome://policy/
```

Clique ensuite sur :

```text
Reload policies
```

ou :

```text
Actualiser les règles
```

Tu dois voir les policies du mode renforcé avec l'état `OK`, par exemple :

```text
AIModeSettings                       1    OK
CreateThemesSettings                 2    OK
DevToolsGenAiSettings                2    OK
GeminiActOnWebSettings               1    OK
GeminiSettings                       1    OK
GenAILocalFoundationalModelSettings  1    OK
HelpMeWriteSettings                  2    OK
HistorySearchSettings                2    OK
SearchContentSharingSettings         1    OK
```

Tu ne dois plus voir :

```text
GenAiDefaultSettings
```

## Vérification du modèle local

Tu peux aussi vérifier l'état du modèle local via :

```text
chrome://on-device-internals/
```

Après application du script, le modèle local peut apparaître comme :

```text
Foundational model state: Not Eligible
Folder size: 0 MiB
enabled by enterprise policy: false
```

Cela indique que le modèle GenAI local n'est pas utilisable par Chrome et que le durcissement est bien appliqué.

## Rapport généré

Par défaut, les scripts génèrent un rapport dans :

```text
.\reports\
```

Exemples de rapports possibles :

```text
.\reports\chrome-genai-policy-check.txt
.\reports\chrome-no-ai-hardening-report.txt
.\reports\chrome-genai-restore-report.txt
```

Les rapports peuvent contenir :

- La date d'exécution.
- Les policies appliquées.
- Les chemins vérifiés.
- Les actions effectuées.
- Les dossiers supprimés ou absents.
- Les étapes de vérification manuelle.

## Restauration

Si tu veux réactiver le comportement par défaut de Chrome, exécute PowerShell en administrateur puis lance :

```powershell
.\scripts\Restore-Chrome-GenAI.ps1
```

Tu peux ensuite redémarrer Chrome et vérifier à nouveau :

```text
chrome://policy/
```

Le script de restauration supprime les policies appliquées par le projet, notamment :

```text
AIModeSettings
CreateThemesSettings
DevToolsGenAiSettings
GeminiActOnWebSettings
GeminiSettings
GenAILocalFoundationalModelSettings
HelpMeWriteSettings
HistorySearchSettings
SearchContentSharingSettings
GenAiDefaultSettings
```

`GenAiDefaultSettings` est supprimée uniquement par nettoyage, au cas où elle serait encore présente depuis une ancienne version du script.

## Chemins vérifiés par les scripts

Les scripts peuvent rechercher et supprimer les dossiers suivants s'ils sont présents :

```text
%LOCALAPPDATA%\Google\Chrome\User Data\OptGuideOnDeviceModel
%LOCALAPPDATA%\Google\Chrome\OptGuideOnDeviceModel
%LOCALAPPDATA%\Google\Chrome\User Data\OptimizationGuideModelStore
%LOCALAPPDATA%\Google\Chrome\User Data\OptimizationGuidePredictionModels
```

Ces chemins peuvent évoluer selon les versions de Chrome.

## Pourquoi utiliser une policy plutôt qu'une simple suppression ?

Supprimer uniquement les fichiers locaux ne suffit pas forcément.

Chrome peut retélécharger certains composants si une fonctionnalité IA ou une API intégrée déclenche leur utilisation.

L'approche par policy est plus propre, car elle indique directement à Chrome que le téléchargement du modèle local n'est pas autorisé.

La suppression des fichiers est donc une étape complémentaire, mais la policy reste la partie principale du durcissement.

## Limites

Ce projet réduit fortement les fonctionnalités IA intégrées à Chrome côté navigateur, mais il ne peut pas garantir un blocage total de tous les contenus IA côté serveur.

Par exemple :

- Une page web peut afficher du contenu généré par IA.
- Un moteur de recherche peut afficher des résultats ou résumés IA côté serveur.
- Une extension installée peut utiliser ses propres fonctionnalités IA.
- Google peut modifier ou ajouter des policies dans de futures versions de Chrome.

Ce projet ne remplace pas une configuration complète de confidentialité du navigateur.

## Vérifications recommandées

Après l'exécution, vérifie :

```text
chrome://policy/
```

```text
chrome://on-device-internals/
```

```text
chrome://flags/
```

Dans `chrome://flags/`, tu peux rechercher manuellement :

```text
Gemini
GenAI
Nano
Prompt API
Summarization
Writer
Rewriter
Proofreader
```

Et désactiver les flags IA expérimentaux si nécessaire.

## Validation

Validation effectuée sur une machine personnelle : les policies Chrome liées aux fonctionnalités IA sont bien appliquées en état `OK` dans `chrome://policy/`.

Le script désactive le modèle GenAI local ainsi que plusieurs intégrations IA de Chrome, dont Gemini, AI Mode, Help Me Write, History Search, Create Themes, DevTools GenAI et Search Content Sharing.

Le modèle local peut également être vérifié dans `chrome://on-device-internals/`, où il doit apparaître comme inéligible ou absent.

## Améliorations possibles

Idées d'améliorations possibles :

- Ajout d'un mode WhatIf.
- Détection de Chrome, Edge, Brave et Chromium.
- Vérification automatique des policies après application.
- Ajout d'un mode non destructif.
- Ajout d'un système de sauvegarde du registre avant modification.

## Sources

- Article ayant motivé le projet : https://www.thatprivacyguy.com/blog/chrome-silent-nano-install/
- Documentation Chrome Enterprise Policies : https://chromeenterprise.google/policies/
- Documentation Chrome Built-in AI : https://developer.chrome.com/docs/ai/

## Contribution

Les contributions sont les bienvenues.

Tu peux proposer :

- De nouveaux chemins de détection.
- Des améliorations PowerShell.
- Une meilleure documentation.
- Des captures d'écran.
- Des rapports d'exemple.
- Une compatibilité avec d'autres navigateurs Chromium.
- Des tests sur différentes versions de Chrome.

## Licence

Projet sous licence MIT.

## Auteurice

Projet créé par Potate_bulle dans une démarche de privacy hardening et d'administration Windows défensive.

## Résumé rapide

```text
But      : désactiver les fonctionnalités IA intégrées à Chrome
Système  : Windows
Langage  : PowerShell
Niveau   : Privacy Hardening
Action   : policies registre + suppression des modèles locaux + rapport
```
