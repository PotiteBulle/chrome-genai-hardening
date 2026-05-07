# Chrome GenAI Hardening

Toolkit de durcissement pour Google Chrome sur Windows, macOS et Linux.

Ce projet permet de désactiver le téléchargement du modèle IA local utilisé par certaines fonctionnalités GenAI de Chrome, notamment Gemini Nano ou les modèles embarqués. Il permet aussi de désactiver plusieurs intégrations IA de Chrome via les règles locales Chrome Enterprise disponibles selon le système d'exploitation.

Le projet nettoie également certains artefacts IA locaux connus, notamment les dossiers liés aux modèles GenAI / OptimizationGuide et le dossier local `screen_ai`, associé à des composants Chrome Screen AI / OCR.

L'objectif est simple : reprendre le contrôle sur les fonctionnalités IA de Chrome, réduire les téléchargements automatiques non souhaités, limiter les intégrations IA côté navigateur, supprimer les fichiers de modèles déjà présents, nettoyer certains composants IA locaux et générer des rapports de vérification exploitables dans une démarche Privacy Hardening.

## Contexte de vérification

Ce projet a été testé sur une machine Windows avec Google Chrome :

```text
Version 148.0.7778.97 (Build officiel) (64 bits)
```

Suite à un approfondissement manuel des dossiers Chrome dans :

```text
%LOCALAPPDATA%\Google\Chrome\User Data\
```

un dossier local nommé `screen_ai` a été identifié.

Ce dossier contient notamment des fichiers et sous-dossiers liés à Chrome Screen AI / OCR, par exemple :

```text
_metadata
aksara
gocr
chrome_screen_ai.dll
files_list_main_content_extraction.txt
files_list_ocr.txt
gocr_mobile_chrome_multiscript_2024_q4_engine.binarypb
manifest.json
README.md
screen2x_config.pbtxt
screen2x_model.tflite
THIRD_PARTY_LICENSES
```

## Captures de validation Screen AI

### Contenu du dossier screen_ai

La capture suivante montre les fichiers présents dans le dossier `screen_ai`.

![Contenu du dossier screen_ai](docs/screenshots/screenai-evidence-1.png)

### README Chrome Screen AI

La capture suivante montre le contenu du fichier `README.md` présent dans le dossier `screen_ai`.

![README Chrome Screen AI](docs/screenshots/screenai-evidence-2.png)

Le fichier `README.md` indique que la bibliothèque Chrome Screen AI fournit deux fonctionnalités locales pour Chrome et ChromeOS :

```text
Main Content Extraction
Optical Character Recognition
```

Le README précise également que ces fonctionnalités sont exécutées entièrement sur l'appareil et ne sont pas envoyées au réseau ni stockées sur disque selon ce document.

## Disclaimer concernant screen_ai

Le dossier `screen_ai` n'a pas été découvert au départ via l'article ayant motivé ce projet. Il a été repéré ensuite, lors d'une analyse plus poussée du dossier :

```text
%LOCALAPPDATA%\Google\Chrome\User Data\
```

Ce composant ne semble pas être exactement le même élément que le modèle Gemini Nano / GenAI évoqué dans l'article de départ. Il semble plutôt lié à Chrome Screen AI, à l'OCR et à l'extraction de contenu principal.

Cependant, il reste pertinent dans le cadre de ce projet, car il s'agit d'un autre composant local lié à des fonctionnalités d'analyse automatique présentes dans Chrome.

Point important : tout le monde n'aura pas forcément ce dossier. Certaines personnes peuvent avoir un dossier `screen_ai`, tandis que d'autres non. Sa présence peut dépendre de plusieurs facteurs, notamment la version de Chrome utilisée, le canal installé, les fonctionnalités activées, les flags expérimentaux, les tests progressifs côté Google, le profil utilisateurice et l'historique d'utilisation.

Les canaux Chrome pouvant présenter des différences sont notamment :

```text
Stable
Extended Stable
Beta
Dev
Canary
```

La question reste donc légitime : pourquoi ce type de composant local est-il aussi peu visible pour l'utilisateurice ? Quel est le niveau réel de consentement, de transparence et de contrôle offert autour de ces fonctionnalités ?

Ce projet ne prétend pas démontrer une intention malveillante. Il documente une observation locale, propose un durcissement défensif, et laisse la question ouverte.

Affaire à suivre.

## Pourquoi ce projet existe

Ce projet a été créé après la lecture de l'article suivant :

https://www.thatprivacyguy.com/blog/chrome-silent-nano-install/

L'article explique que Chrome peut télécharger localement un modèle IA de grande taille lié à Gemini Nano / GenAI. Ce dépôt propose une réponse défensive, documentée et réversible : utiliser les policies Chrome Enterprise disponibles localement pour empêcher le téléchargement du modèle local, puis nettoyer les artefacts déjà présents.

Le projet a ensuite été étendu pour désactiver d'autres fonctionnalités IA intégrées à Chrome, comme Gemini, AI Mode, Help Me Write, History Search, Create Themes, DevTools GenAI et certaines fonctions de partage de contenu avec les services IA.

Il a aussi été étendu pour nettoyer `screen_ai`, suite à l'analyse locale du profil Chrome.

Ce projet ne cherche pas à modifier Chrome ni à contourner ses protections. Il applique uniquement des règles de configuration administrateurice et supprime des artefacts locaux connus.

## Objectifs du projet

Ce toolkit permet de :

- Désactiver le téléchargement du modèle IA local GenAI / Gemini Nano de Chrome.
- Désactiver plusieurs fonctionnalités IA intégrées à Chrome.
- Appliquer des policies Chrome Enterprise selon le système utilisé.
- Supprimer les dossiers locaux liés aux modèles IA déjà téléchargés.
- Supprimer les dossiers locaux liés à `screen_ai` / Screen AI / OCR lorsqu'ils existent.
- Nettoyer certaines anciennes règles pouvant provoquer des erreurs dans `chrome://policy/`.
- Générer des rapports de vérification.
- Créer des sauvegardes avant certaines modifications.
- Fournir une base propre pour l'audit, le hardening et la documentation sécurité.

## Systèmes supportés

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
├── README_en.md
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
│   ├── policy-explanation_en.md
│   └── screenshots/
│       ├── screenai-evidence-1.png
│       └── screenai-evidence-2.png
├── reports/
│   └── example-report.md
└── backups/
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

Le mode ciblé nettoie également les artefacts locaux connus :

```text
GenAI / OptimizationGuide
screen_ai / Screen AI / OCR local
```

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

Le mode renforcé nettoie également les artefacts locaux connus :

```text
GenAI / OptimizationGuide
screen_ai / Screen AI / OCR local
```

### Mode restauration

Le mode restauration supprime les policies appliquées par le projet afin de revenir au comportement par défaut de Chrome.

Important : les scripts de restauration restaurent uniquement les policies Chrome appliquées par le projet. Ils ne restaurent pas les fichiers locaux supprimés, comme `screen_ai` ou les modèles IA.

## Utilisation rapide

### Windows

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\scripts\windows\Disable-Chrome-AI-Features.ps1
```

### macOS

```bash
chmod +x scripts/macos/Disable-Chrome-AI-Features-macOS.sh
sudo ./scripts/macos/Disable-Chrome-AI-Features-macOS.sh
osascript -e 'quit app "Google Chrome"'
```

### Linux

```bash
chmod +x scripts/linux/Disable-Chrome-AI-Features-linux.sh
sudo ./scripts/linux/Disable-Chrome-AI-Features-linux.sh
```

Après exécution, ferme complètement Chrome puis relance-le.

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

Tu dois voir les policies du mode renforcé avec l'état `OK`.

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

## Vérification de screen_ai

Après application du script, tu peux vérifier que le dossier `screen_ai` n'est plus présent dans le profil Chrome.

Chemins principaux :

```text
Windows : %LOCALAPPDATA%\Google\Chrome\User Data\screen_ai
macOS   : ~/Library/Application Support/Google/Chrome/User Data/screen_ai
Linux   : ~/.config/google-chrome/User Data/screen_ai
```

Selon la version de Chrome, d'autres chemins proches peuvent exister. Les scripts vérifient plusieurs chemins possibles.

## Rapports et sauvegardes

Les scripts génèrent des rapports dans :

```text
./reports/
```

Les scripts peuvent générer des sauvegardes dans :

```text
./backups/
```

## Limites

Ce projet réduit fortement les fonctionnalités IA intégrées à Chrome côté navigateur, mais il ne peut pas garantir un blocage total de tous les contenus IA côté serveur.

Par exemple :

- Une page web peut afficher du contenu généré par IA.
- Un moteur de recherche peut afficher des résultats ou résumés IA côté serveur.
- Une extension installée peut utiliser ses propres fonctionnalités IA.
- Google peut modifier ou ajouter des policies dans de futures versions de Chrome.
- Certaines policies peuvent dépendre de la version de Chrome installée.
- `screen_ai` peut être retéléchargé par Chrome si une fonctionnalité ou une configuration active le redéclenche.
- Le dossier `screen_ai` peut être présent chez certaines personnes et absent chez d'autres selon le canal Chrome, la version, les flags, les tests progressifs ou l'usage local.

Ce projet ne remplace pas une configuration complète de confidentialité du navigateur.

## Vérifications recommandées

Après l'exécution, vérifie :

```text
chrome://policy/
chrome://on-device-internals/
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
Screen AI
OCR
```

## Sources

- Article ayant motivé le projet : https://www.thatprivacyguy.com/blog/chrome-silent-nano-install/
- Documentation Chrome Enterprise Policies : https://chromeenterprise.google/policies/
- Documentation Chrome Built-in AI : https://developer.chrome.com/docs/ai/

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
Action   : policies locales + suppression des modèles locaux + screen_ai + rapports
```
