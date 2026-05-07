# Explication des policies Chrome utilisées

Ce document explique les policies utilisées par le projet `chrome-genai-hardening`.

Le projet permet de désactiver le modèle IA local de Chrome, notamment Gemini Nano / GenAI, ainsi que plusieurs fonctionnalités IA intégrées au navigateur.

Il fonctionne sur trois systèmes :

```text
Windows
macOS
Linux
```

Chaque système applique les policies Chrome Enterprise d'une manière différente.

```text
Windows : registre Windows
macOS   : fichier plist
Linux   : fichier JSON de policies managed
```

## 1. Objectif des policies

Les policies utilisées par ce projet ont pour objectif de :

- Désactiver le téléchargement du modèle IA local GenAI / Gemini Nano.
- Désactiver plusieurs fonctionnalités IA intégrées à Chrome.
- Réduire les téléchargements automatiques non souhaités.
- Empêcher certaines intégrations IA côté navigateur.
- Nettoyer les anciens fichiers de modèles IA déjà présents.
- Garder une configuration vérifiable via `chrome://policy/`.

## 2. Policy principale

La policy principale du projet est :

```text
GenAILocalFoundationalModelSettings = 1
```

Cette règle indique à Chrome de ne pas télécharger le modèle IA local utilisé par certaines fonctionnalités GenAI.

Elle est utilisée dans tous les modes du projet :

```text
Mode ciblé
Mode renforcé
Windows
macOS
Linux
```

C'est la règle la plus importante pour empêcher Chrome d'utiliser ou de télécharger le modèle local lié à Gemini Nano / GenAI.

## 3. Mode ciblé

Le mode ciblé applique uniquement la policy principale :

```text
GenAILocalFoundationalModelSettings = 1
```

Ce mode est utile si l'objectif est uniquement de bloquer le modèle IA local.

Scripts concernés :

```text
scripts/windows/Disable-Chrome-GenAI.ps1
scripts/macos/Disable-Chrome-GenAI-macOS.sh
scripts/linux/Disable-Chrome-GenAI-linux.sh
```

Après application, la vérification se fait dans Chrome via :

```text
chrome://policy/
```

Résultat attendu :

```text
GenAILocalFoundationalModelSettings    1    OK
```

## 4. Mode renforcé

Le mode renforcé applique plusieurs policies Chrome Enterprise liées aux fonctionnalités IA.

Policies appliquées :

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

Scripts concernés :

```text
scripts/windows/Disable-Chrome-AI-Features.ps1
scripts/macos/Disable-Chrome-AI-Features-macOS.sh
scripts/linux/Disable-Chrome-AI-Features-linux.sh
```

Ce mode est recommandé si l'objectif est de réduire au maximum les fonctionnalités IA intégrées à Chrome côté navigateur.

## 5. Détail des policies du mode renforcé

### AIModeSettings

```text
AIModeSettings = 1
```

Cette policy désactive ou limite les intégrations liées au mode IA de Chrome, notamment les points d'entrée AI Mode lorsqu'ils sont disponibles.

### CreateThemesSettings

```text
CreateThemesSettings = 2
```

Cette policy désactive la création de thèmes avec IA dans Chrome.

### DevToolsGenAiSettings

```text
DevToolsGenAiSettings = 2
```

Cette policy désactive les fonctionnalités GenAI intégrées aux DevTools de Chrome.

### GeminiActOnWebSettings

```text
GeminiActOnWebSettings = 1
```

Cette policy désactive ou limite les capacités d'action de Gemini sur le contenu web lorsque cette fonctionnalité est disponible.

### GeminiSettings

```text
GeminiSettings = 1
```

Cette policy désactive ou limite l'intégration Gemini dans Chrome.

### GenAILocalFoundationalModelSettings

```text
GenAILocalFoundationalModelSettings = 1
```

Cette policy empêche le téléchargement du modèle IA local GenAI / Gemini Nano.

C'est la policy centrale du projet.

### HelpMeWriteSettings

```text
HelpMeWriteSettings = 2
```

Cette policy désactive la fonctionnalité d'aide à l'écriture basée sur l'IA.

### HistorySearchSettings

```text
HistorySearchSettings = 2
```

Cette policy désactive la recherche dans l'historique assistée par IA.

### SearchContentSharingSettings

```text
SearchContentSharingSettings = 1
```

Cette policy limite ou désactive le partage de contenu avec certaines fonctionnalités de recherche ou d'IA intégrées.

## 6. Note importante concernant GenAiDefaultSettings

La policy suivante n'est plus utilisée par ce projet :

```text
GenAiDefaultSettings
```

Certaines installations de Chrome peuvent ignorer cette règle lorsqu'elle est configurée localement.

Dans ce cas, Chrome peut afficher une erreur dans :

```text
chrome://policy/
```

Exemple d'erreur :

```text
Règle ignorée, car non configurée par une source cloud.
```

Pour éviter cette erreur, le projet n'applique pas `GenAiDefaultSettings`.

Les scripts peuvent toutefois la supprimer si elle est déjà présente depuis une ancienne version du projet.

## 7. Emplacement des policies par système

### Windows

Sur Windows, les policies sont écrites dans le registre :

```text
HKLM:\SOFTWARE\Policies\Google\Chrome
```

Exemple de vérification PowerShell :

```powershell
Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" |
Select-Object `
    AIModeSettings,
    CreateThemesSettings,
    DevToolsGenAiSettings,
    GeminiActOnWebSettings,
    GeminiSettings,
    GenAILocalFoundationalModelSettings,
    HelpMeWriteSettings,
    HistorySearchSettings,
    SearchContentSharingSettings |
Format-List
```

### macOS

Sur macOS, les policies sont écrites dans un fichier plist :

```text
/Library/Managed Preferences/com.google.Chrome.plist
```

Le fichier doit appartenir à `root:wheel` avec des permissions adaptées.

Les scripts macOS créent ou modifient ce fichier automatiquement.

### Linux

Sur Linux, les policies sont écrites dans un fichier JSON de policies managed :

```text
/etc/opt/chrome/policies/managed/
```

Pour Google Chrome officiel, les fichiers utilisés par le projet peuvent être :

```text
/etc/opt/chrome/policies/managed/chrome-genai-hardening.json
/etc/opt/chrome/policies/managed/chrome-no-ai-hardening.json
```

Pour Chromium, le chemin peut être différent :

```text
/etc/chromium/policies/managed/
```

Le projet cible prioritairement Google Chrome officiel.

## 8. Vérification après application

Après l'exécution d'un script, ouvrir Chrome et aller sur :

```text
chrome://policy/
```

Cliquer ensuite sur :

```text
Reload policies
```

ou :

```text
Actualiser les règles
```

Pour le mode ciblé, le résultat attendu est :

```text
GenAILocalFoundationalModelSettings    1    OK
```

Pour le mode renforcé, le résultat attendu est :

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

La policy suivante ne doit pas apparaître :

```text
GenAiDefaultSettings
```

## 9. Vérification du modèle local

Le modèle local peut être vérifié via :

```text
chrome://on-device-internals/
```

Un résultat attendu après application du durcissement peut être :

```text
Foundational model state: Not Eligible
Folder size: 0 MiB
enabled by enterprise policy: false
```

Cela indique que le modèle local n'est pas utilisable par Chrome.

## 10. Nettoyage des modèles locaux

Les scripts peuvent rechercher et supprimer certains dossiers liés aux modèles IA locaux.

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

## 11. Restauration

Les scripts de restauration suppriment les policies appliquées par le projet.

Scripts concernés :

```text
scripts/windows/Restore-Chrome-GenAI.ps1
scripts/macos/Restore-Chrome-GenAI-macOS.sh
scripts/linux/Restore-Chrome-GenAI-linux.sh
```

Policies retirées par le mode restauration :

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

`GenAiDefaultSettings` est retirée uniquement par nettoyage, au cas où elle serait encore présente depuis une ancienne version du projet.

## 12. Limites

Ces policies réduisent fortement les fonctionnalités IA intégrées à Chrome côté navigateur.

Cependant, elles ne peuvent pas garantir le blocage de tous les contenus IA côté serveur.

Exemples :

- Une page web peut afficher du contenu généré par IA.
- Un moteur de recherche peut afficher des résumés IA côté serveur.
- Une extension installée peut utiliser ses propres fonctionnalités IA.
- Google peut modifier ou ajouter des policies dans de futures versions de Chrome.
- Certaines policies peuvent dépendre de la version exacte de Chrome installée.

Ce projet ne remplace pas une configuration complète de confidentialité du navigateur.

## 13. Résumé rapide

```text
Policy centrale : GenAILocalFoundationalModelSettings = 1
Mode ciblé      : blocage du modèle IA local
Mode renforcé   : blocage de plusieurs intégrations IA Chrome
Windows         : registre Windows
macOS           : fichier plist
Linux           : fichier JSON managed policies
Vérification    : chrome://policy/ et chrome://on-device-internals/
```
