# Vérification après exécution

Ce document liste les contrôles à effectuer après l'exécution du script.

## 1. Vérifier les policies Chrome

Ouvrir Chrome, puis aller sur :

```text
chrome://policy/
```

Cliquer sur :

```text
Reload policies
```

Vérifier que les policies suivantes sont présentes :

```text
GenAILocalFoundationalModelSettings    1
GenAiDefaultSettings                   2
```

## 2. Vérifier les modèles locaux

Ouvrir :

```text
chrome://on-device-internals/
```

Vérifier si un modèle local est encore indiqué comme présent.

## 3. Vérifier les flags expérimentaux

Ouvrir :

```text
chrome://flags/
```

Rechercher :

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

Désactiver manuellement les flags IA expérimentaux si nécessaire.

## 4. Vérifier le rapport local

Le script génère un rapport dans :

```text
.\reports\chrome-genai-policy-check.txt
```

Le rapport doit contenir :

- la date d'exécution.
- les policies appliquées.
- les dossiers vérifiés.
- les dossiers supprimés ou absents.
- les instructions de vérification manuelle.

## 5. Redémarrer Chrome

Si Chrome était ouvert pendant l'exécution du script, ferme toutes les fenêtres Chrome, puis relance le navigateur.

## 6. Commande de contrôle du registre

PowerShell administrateur :

```powershell
Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" |
Select-Object GenAILocalFoundationalModelSettings, GenAiDefaultSettings |
Format-List
```

Résultat attendu :

```text
GenAILocalFoundationalModelSettings : 1
GenAiDefaultSettings                : 2
```
