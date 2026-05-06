# Chrome GenAI Hardening

Toolkit PowerShell de durcissement pour Google Chrome sous Windows.

Ce projet permet de désactiver le téléchargement du modèle IA local utilisé par certaines fonctionnalités GenAI de Chrome, notamment Gemini Nano ou les modèles embarqués, via les règles locales Chrome Enterprise.

L'objectif est simple : reprendre le contrôle sur les fonctionnalités IA locales de Chrome, réduire les téléchargements automatiques non souhaités, supprimer les fichiers de modèle déjà présents, et générer un rapport de vérification exploitable dans une démarche Privacy Hardening.

## Pourquoi ce projet existe

Ce projet a été créé après la lecture de l'article suivant :

https://www.thatprivacyguy.com/blog/chrome-silent-nano-install/

L'article explique que Chrome peut télécharger localement un modèle IA de grande taille lié à Gemini Nano / GenAI. Ce dépôt propose une réponse défensive, documentée et réversible : utiliser les policies Chrome Enterprise disponibles sous Windows pour empêcher le téléchargement du modèle local, puis nettoyer les artefacts déjà présents.

Ce projet ne cherche pas à modifier Chrome ni à contourner ses protections. Il applique uniquement des règles de configuration administrateur.

## Objectifs du projet

Ce script permet de :

- désactiver le téléchargement du modèle IA local GenAI de Chrome.
- appliquer des policies Chrome Enterprise via le registre Windows.
- supprimer les dossiers locaux liés aux modèles IA déjà téléchargés.
- générer un rapport de vérification.
- fournir une base propre pour l'audit, le hardening et la documentation sécurité.

## Contexte

Certaines versions récentes de Chrome peuvent télécharger des composants locaux liés aux fonctionnalités d'intelligence artificielle, comme Gemini Nano ou des modèles utilisés par les API IA intégrées.

Ces fonctionnalités peuvent être utiles pour certains usages, mais elles peuvent aussi poser des questions de :

- confidentialité.
- contrôle utilisateurices.
- surface d'attaque.
- consommation disque.
- gouvernance des fonctionnalités IA.
- conformité dans un environnement professionnel ou personnel durci.

Ce projet propose une approche défensive et transparente pour désactiver ces fonctionnalités via des mécanismes documentés de configuration locale.

## Avertissement

Ce projet est destiné au durcissement de la vie privée, à l'administration système et à un usage défensif.

Il ne modifie pas les binaires de Chrome, ne contourne pas de mécanisme de sécurité, et n'effectue aucune action offensive.

Le script applique uniquement des règles locales Windows / Chrome Enterprise et supprime des fichiers de modèle locaux lorsque ceux-ci sont présents.

Utilise ce script uniquement sur une machine dont tu es propriétaire ou que tu es autorisé à administrer.

## Arborescence

```text
chrome-genai-hardening/
├── README.md
├── LICENSE (MIT)
├── .gitignore
├── scripts/
│   ├── Disable-Chrome-GenAI.ps1
│   └── Restore-Chrome-GenAI.ps1
├── docs/
│   ├── policy-explanation.md
└── reports/
    └── example-report.md
```

## Fonctionnement

Le script principal applique les policies suivantes dans le registre Windows :

```text
HKLM:\SOFTWARE\Policies\Google\Chrome
```

Policy principale :

```text
GenAILocalFoundationalModelSettings = 1
```

Cette règle indique à Chrome de ne pas télécharger le modèle IA local.

Policy complémentaire :

```text
GenAiDefaultSettings = 2
```

Cette règle sert à désactiver par défaut certaines fonctionnalités GenAI couvertes par les policies Chrome.

## Prérequis

- Windows 10 ou Windows 11.
- Google Chrome installé.
- PowerShell.
- Droits administrateur.
- Accès au registre Windows.

## Installation

Clone le dépôt :

```powershell
git clone https://github.com/PotiteBulle/chrome-genai-hardening
cd chrome-genai-hardening
```

Ou télécharge simplement le fichier :

```text
scripts/Disable-Chrome-GenAI.ps1
```

## Utilisation

Ouvre PowerShell en administrateur, puis exécute :

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\scripts\Disable-Chrome-GenAI.ps1
```

Le script va :

1. Vérifier les droits administrateur.
2. Créer la clé de policy Chrome si elle n'existe pas.
3. Appliquer les règles de désactivation GenAI.
4. Rechercher les dossiers locaux liés aux modèles IA.
5. Supprimer les dossiers trouvés.
6. Générer un rapport de vérification.

## Vérification dans Chrome

Après l'exécution du script, ouvre Chrome et va sur :

```text
chrome://policy/
```

Clique ensuite sur :

```text
Reload policies
```

Tu dois voir les policies suivantes :

```text
GenAILocalFoundationalModelSettings    1
GenAiDefaultSettings                   2
```

Tu peux aussi vérifier l'état des modèles locaux via :

```text
chrome://on-device-internals/
```

Si un modèle local était déjà présent, il devrait avoir été supprimé par le script.

## Rapport généré

Par défaut, le script génère un rapport dans :

```text
.\reports\chrome-genai-policy-check.txt
```

Ce rapport contient :

- La date d'exécution.
- Les policies appliquées.
- Les chemins vérifiés.
- Les actions effectuées.
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

## Chemins vérifiés par le script

Le script recherche et supprime les dossiers suivants s'ils sont présents :

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

## Améliorations possibles

Idées d'améliorations possibles :

- Ajout d'un mode WhatIf.
- Génération d'un rapport Markdown.
- Export JSON des résultats.
- Détection de Chrome, Edge, Brave et Chromium.
- Vérification automatique des policies après application.
- Ajout d'un mode non destructif.
- Ajout d'un système de sauvegarde du registre avant modification.

## Limites

Ce script :

- Ne bloque pas toutes les fonctionnalités IA côté serveur.
- Ne remplace pas une configuration complète de confidentialité Chrome.
- Dépend du support des policies par la version de Chrome installée.
- Nécessite des droits administrateur.
- Peut devoir être adapté si Google modifie les noms ou chemins des composants.

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
- Gemini
- GenAI
- Nano
- Prompt API
- Summarization
- Writer
- Rewriter
- Proofreader
```

Et désactiver les flags IA expérimentaux si nécessaire.

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

## Licence

Projet sous licence MIT.

## Auteurice

Projet créé par Potate_bulle dans une démarche de privacy hardening et d'administration Windows défensive.

## Résumé rapide

```text
But      : désactiver le modèle IA local GenAI/Gemini Nano de Chrome
Système  : Windows
Langage  : PowerShell
Niveau   : Privacy Hardening
Action   : policies registre + suppression des modèles locaux + rapport
```
