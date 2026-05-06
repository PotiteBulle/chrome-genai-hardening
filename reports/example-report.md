# Exemple de rapport

```text
Rapport - Chrome GenAI Hardening
Date : 2026-05-06 14:32:10

Policies appliquees :
GenAILocalFoundationalModelSettings = 1
GenAiDefaultSettings                = 2

Chemin registre :
HKLM:\SOFTWARE\Policies\Google\Chrome

Actions effectuees :
Absent : C:\Users\User\AppData\Local\Google\Chrome\User Data\OptGuideOnDeviceModel
Absent : C:\Users\User\AppData\Local\Google\Chrome\OptGuideOnDeviceModel
Supprime : C:\Users\User\AppData\Local\Google\Chrome\User Data\OptimizationGuideModelStore (3.98 Go)
Absent : C:\Users\User\AppData\Local\Google\Chrome\User Data\OptimizationGuidePredictionModels

Verification manuelle :
1. Ouvrir Chrome.
2. Aller sur chrome://policy/.
3. Cliquer sur Reload policies.
4. Vérifier :
   - GenAILocalFoundationalModelSettings = 1
   - GenAiDefaultSettings = 2
5. Aller sur chrome://on-device-internals/.
6. Vérifier si un modele local est encore present.

Note :
Si Chrome était ouvert pendant l'éxecution, fermer puis relancer Chrome.
```
