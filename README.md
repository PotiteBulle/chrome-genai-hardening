# Chrome GenAI Hardening

Toolkit de durcissement pour Google Chrome sur Windows, macOS et Linux.

Ce projet permet de désactiver le téléchargement du modèle IA local utilisé par certaines fonctionnalités GenAI de Chrome, notamment Gemini Nano ou les modèles embarqués. Il permet aussi de désactiver plusieurs intégrations IA de Chrome via les règles locales Chrome Enterprise disponibles selon le système d'exploitation.

L'objectif est simple : reprendre le contrôle sur les fonctionnalités IA de Chrome, réduire les téléchargements automatiques non souhaités, limiter les intégrations IA côté navigateur, supprimer les fichiers de modèles déjà présents et générer des rapports de vérification exploitables dans une démarche Privacy Hardening.

## Pourquoi ce projet existe

Ce projet a été créé après la lecture de l'article suivant :

https://www.thatprivacyguy.com/blog/chrome-silent-nano-install/

L'article explique que Chrome peut télécharger localement un modèle IA de grande taille lié à Gemini Nano / GenAI. Ce dépôt propose une réponse défensive, documentée et réversible : utiliser les policies Chrome Enterprise disponibles localement pour empêcher le téléchargement du modèle local, puis nettoyer les artefacts déjà présents.

Le projet a ensuite été étendu pour désactiver d'autres fonctionnalités IA intégrées à Chrome, comme Gemini, AI Mode, Help Me Write, History Search, Create Themes, DevTools GenAI et certaines fonctions de partage de contenu avec les services IA.

Ce projet ne cherche pas à modifier Chrome ni à contourner ses protections. Il applique uniquement des règles de configuration administrateurice.

## Objectifs du projet

Ce toolkit permet de :

- Désactiver le téléchargement du modèle IA local GenAI / Gemini Nano de Chrome.
- Désactiver plusieurs fonctionnalités IA intégrées à Chrome.
- Appliquer des policies Chrome Enterprise selon le système utilisé.
- Supprimer les dossiers locaux liés aux modèles IA déjà téléchargés.
- Nettoyer certaines anciennes règles pouvant provoquer des erreurs dans `chrome://policy/`.
- Générer des rapports de vérification.
- Fournir une base propre pour l'audit, le hardening et la documentation sécurité.

## Systèmes supportés

Le projet vise trois plateformes :

```text
Windows
macOS
Linux
```

Chaque système utilise une méthode différente pour appliquer les policies Chrome.

```text
Windows : registre Windows
macOS   : fichier plist
Linux   : fichier JSON de policies managed
```

## Avertissement

Ce projet est destiné au durcissement de la vie privée, à l'administration système et à un usage défensif.

Il ne modifie pas les binaires de Chrome, ne contourne pas de mécanisme de sécurité et n'effectue aucune action offensive.

Les scripts appliquent uniquement des règles locales Chrome Enterprise et suppriment des fichiers de modèle locaux lorsque ceux-ci sont présents.

Utilise ces scripts uniquement sur une machine dont tu es propriétaire ou que tu es autorisé à administrer.

## Arborescence recommandée

```text
chrome-genai-hardening/
├── README.md
├── LICENSE
├── .gitignore
├── scripts/
│   ├── windows/
│   │   ├── Disable-Chrome-GenAI.ps1
│   │   ├── Disable-Chrome-AI-Features.ps1
│   │   └── Restore-Chrome-GenAI.ps1
│   ├── macos/
│   │   ├── Disable-Chrome-GenAI-macOS.sh
│   │   ├── Disable-Chrome-AI-Features-macOS.sh
│   │   └── Restore-Chrome-GenAI-macOS.sh
│   └── linux/
│       ├── Disable-Chrome-GenAI-linux.sh
│       ├── Disable-Chrome-AI-Features-linux.sh
│       └── Restore-Chrome-GenAI-linux.sh
├── docs/
│   ├── policy-explanation.md
└── reports/
    └── example-report.md
```

## Scripts disponibles

### Mode ciblé

Le mode ciblé désactive principalement le modèle IA local GenAI / Gemini Nano.

Scripts concernés :

```text
scripts/windows/Disable-Chrome-GenAI.ps1
scripts/macos/Disable-Chrome-GenAI-macOS.sh
scripts/linux/Disable-Chrome-GenAI-linux.sh
```

Policy principale appliquée :

```text
GenAILocalFoundationalModelSettings = 1
```

Cette règle indique à Chrome de ne pas télécharger le modèle IA local utilisé par certaines fonctionnalités GenAI.

### Mode renforcé

Le mode renforcé désactive un maximum de fonctionnalités IA intégrées à Chrome côté navigateur.

Scripts concernés :

```text
scripts/windows/Disable-Chrome-AI-Features.ps1
scripts/macos/Disable-Chrome-AI-Features-macOS.sh
scripts/linux/Disable-Chrome-AI-Features-linux.sh
```

Policies appliquées par le mode renforcé :

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

### Mode restauration

Le mode restauration supprime les policies appliquées par le projet afin de revenir au comportement par défaut de Chrome.

Scripts concernés :

```text
scripts/windows/Restore-Chrome-GenAI.ps1
scripts/macos/Restore-Chrome-GenAI-macOS.sh
scripts/linux/Restore-Chrome-GenAI-linux.sh
```

## Fonctionnement par système

### Windows

Sur Windows, les policies sont appliquées dans le registre :

```text
HKLM:\SOFTWARE\Policies\Google\Chrome
```

Les scripts doivent être lancés dans PowerShell en administrateurice.

### macOS

Sur macOS, les policies sont appliquées via un fichier plist :

```text
/Library/Managed Preferences/com.google.Chrome.plist
```

Les scripts doivent être lancés avec `sudo`.

### Linux

Sur Linux, les policies sont appliquées via un fichier JSON dans le dossier des policies managed de Chrome :

```text
/etc/opt/chrome/policies/managed/chrome-genai-hardening.json
```

Les scripts doivent être lancés avec `sudo`.

Selon la distribution ou le type de paquet Chrome installé, certains chemins peuvent varier. Pour Google Chrome stable installé depuis le paquet officiel, le chemin recommandé est généralement :

```text
/etc/opt/chrome/policies/managed/
```

Pour Chromium, le chemin peut être différent, par exemple :

```text
/etc/chromium/policies/managed/
```

Ce projet cible prioritairement Google Chrome.

## Note concernant GenAiDefaultSettings

La policy suivante n'est pas utilisée par ce projet :

```text
GenAiDefaultSettings
```

Certaines installations de Chrome peuvent ignorer cette règle lorsqu'elle est configurée localement. Dans ce cas, Chrome peut afficher une erreur dans `chrome://policy/` indiquant que la règle est ignorée, car elle n'est pas configurée par une source cloud.

Pour éviter cette erreur, le projet n'utilise pas `GenAiDefaultSettings`.

Les scripts peuvent toutefois supprimer cette ancienne règle si elle est déjà présente sur la machine.

## Prérequis

### Windows

- Windows 10 ou Windows 11.
- Google Chrome installé.
- PowerShell.
- Droits administrateurice.

### macOS

- macOS.
- Google Chrome installé.
- Terminal.
- Droits administrateurice avec `sudo`.

### Linux

- Distribution Linux avec Google Chrome installé.
- Shell Bash.
- Droits administrateurice avec `sudo`.
- Accès au dossier `/etc/opt/chrome/policies/managed/`.

## Installation

Clone le dépôt :

```bash
git clone https://github.com/PotiteBulle/chrome-genai-hardening
cd chrome-genai-hardening
```

## Utilisation sur Windows

### Mode ciblé

Ouvre PowerShell en administrateurice, puis exécute :

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\scripts\windows\Disable-Chrome-GenAI.ps1
```

### Mode renforcé

Ouvre PowerShell en administrateurice, puis exécute :

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\scripts\windows\Disable-Chrome-AI-Features.ps1
```

### Restauration

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\scripts\windows\Restore-Chrome-GenAI.ps1
```

## Utilisation sur macOS

### Mode ciblé

```bash
chmod +x scripts/macos/Disable-Chrome-GenAI-macOS.sh
sudo ./scripts/macos/Disable-Chrome-GenAI-macOS.sh
```

### Mode renforcé

```bash
chmod +x scripts/macos/Disable-Chrome-AI-Features-macOS.sh
sudo ./scripts/macos/Disable-Chrome-AI-Features-macOS.sh
```

### Restauration

```bash
chmod +x scripts/macos/Restore-Chrome-GenAI-macOS.sh
sudo ./scripts/macos/Restore-Chrome-GenAI-macOS.sh
```

Après exécution, ferme complètement Chrome :

```bash
osascript -e 'quit app "Google Chrome"'
```

Puis relance Chrome.

## Utilisation sur Linux

### Mode ciblé

```bash
chmod +x scripts/linux/Disable-Chrome-GenAI-linux.sh
sudo ./scripts/linux/Disable-Chrome-GenAI-linux.sh
```

### Mode renforcé

```bash
chmod +x scripts/linux/Disable-Chrome-AI-Features-linux.sh
sudo ./scripts/linux/Disable-Chrome-AI-Features-linux.sh
```

### Restauration

```bash
chmod +x scripts/linux/Restore-Chrome-GenAI-linux.sh
sudo ./scripts/linux/Restore-Chrome-GenAI-linux.sh
```

Après exécution, ferme complètement Chrome puis relance-le.

## Ce que fait le mode renforcé

Le script renforcé va :

1. Vérifier les droits administrateurice.
2. Créer le dossier de policies si nécessaire.
3. Appliquer plusieurs policies IA Chrome Enterprise.
4. Appliquer `GenAILocalFoundationalModelSettings = 1`.
5. Supprimer ou éviter l'ancienne règle `GenAiDefaultSettings`.
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

## Rapports générés

Par défaut, les scripts génèrent des rapports dans :

```text
./reports/
```

Exemples :

```text
./reports/chrome-genai-policy-check.txt
./reports/chrome-no-ai-hardening-report.txt
./reports/chrome-genai-restore-report.txt
./reports/chrome-genai-policy-check-macos.txt
./reports/chrome-no-ai-hardening-report-macos.txt
./reports/chrome-genai-restore-report-macos.txt
./reports/chrome-genai-policy-check-linux.txt
./reports/chrome-no-ai-hardening-report-linux.txt
./reports/chrome-genai-restore-report-linux.txt
```

Les rapports peuvent contenir :

- La date d'exécution.
- Les policies appliquées.
- Les chemins vérifiés.
- Les actions effectuées.
- Les dossiers supprimés ou absents.
- Les étapes de vérification manuelle.

## Chemins de modèles vérifiés

### Windows

```text
%LOCALAPPDATA%\Google\Chrome\User Data\OptGuideOnDeviceModel
%LOCALAPPDATA%\Google\Chrome\OptGuideOnDeviceModel
%LOCALAPPDATA%\Google\Chrome\User Data\OptimizationGuideModelStore
%LOCALAPPDATA%\Google\Chrome\User Data\OptimizationGuidePredictionModels
```

### macOS

```text
~/Library/Application Support/Google/Chrome/OptGuideOnDeviceModel
~/Library/Application Support/Google/Chrome/OptimizationGuideModelStore
~/Library/Application Support/Google/Chrome/OptimizationGuidePredictionModels
~/Library/Application Support/Google/Chrome/User Data/OptGuideOnDeviceModel
~/Library/Application Support/Google/Chrome/User Data/OptimizationGuideModelStore
~/Library/Application Support/Google/Chrome/User Data/OptimizationGuidePredictionModels
```

### Linux

```text
~/.config/google-chrome/OptGuideOnDeviceModel
~/.config/google-chrome/OptimizationGuideModelStore
~/.config/google-chrome/OptimizationGuidePredictionModels
~/.config/google-chrome/User Data/OptGuideOnDeviceModel
~/.config/google-chrome/User Data/OptimizationGuideModelStore
~/.config/google-chrome/User Data/OptimizationGuidePredictionModels
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
- Certaines policies peuvent dépendre de la version de Chrome installée.

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

Validation effectuée sur une machine personnelle Windows : les policies Chrome liées aux fonctionnalités IA sont bien appliquées en état `OK` dans `chrome://policy/`.

Le script désactive le modèle GenAI local ainsi que plusieurs intégrations IA de Chrome, dont Gemini, AI Mode, Help Me Write, History Search, Create Themes, DevTools GenAI et Search Content Sharing.

Le modèle local peut également être vérifié dans `chrome://on-device-internals/`, où il doit apparaître comme inéligible ou absent.

Les versions macOS et Linux doivent être vérifiées de la même manière avec `chrome://policy/` et `chrome://on-device-internals/`.

## Améliorations possibles

Idées d'améliorations possibles :

- Ajout d'un mode WhatIf.
- Vérification automatique des policies après application.
- Ajout d'un système de sauvegarde avant modification.
- Ajout d'un tableau de compatibilité par version de Chrome.
- Ajout d'un support spécifique pour Chromium.

## Sources

- Article ayant motivé le projet : https://www.thatprivacyguy.com/blog/chrome-silent-nano-install/
- Documentation Chrome Enterprise Policies : https://chromeenterprise.google/policies/
- Documentation Chrome Built-in AI : https://developer.chrome.com/docs/ai/

## Contribution

Les contributions sont les bienvenues.

Tu peux proposer :

- De nouveaux chemins de détection.
- Des améliorations PowerShell.
- Des améliorations Bash.
- Une meilleure documentation.
- Des captures d'écran.
- Des rapports d'exemple.
- Une compatibilité avec d'autres navigateurs Chromium.
- Des tests sur différentes versions de Chrome.
- Des tests sur Windows, macOS et Linux.

## Licence

Projet sous licence MIT.

## Auteurice

Projet créé par Potate_bulle dans une démarche de privacy hardening et d'administration Windows, macOS et Linux défensive.

## Résumé rapide

```text
But      : désactiver les fonctionnalités IA intégrées à Chrome
Systèmes : Windows, macOS, Linux
Langages : PowerShell, Bash
Niveau   : Privacy Hardening
Action   : policies locales + suppression des modèles locaux + rapports
```
