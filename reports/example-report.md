Rapport - Chrome GenAI Hardening
Date : 2026-05-06 09:03:11 (Fait sur une de mes machines qui est sur Google Chrome)

Policy appliquée :
GenAILocalFoundationalModelSettings = 1

Chemin registre :
HKLM:\SOFTWARE\Policies\Google\Chrome

Règle supprimée si présente :
GenAiDefaultSettings

Actions effectuées :
Absent : C:\Users\Utilisateurice\AppData\Local\Google\Chrome\User Data\OptGuideOnDeviceModel
Absent : C:\Users\Utilisateurice\AppData\Local\Google\Chrome\OptGuideOnDeviceModel
Absent : C:\Users\Utilisateurice\AppData\Local\Google\Chrome\User Data\OptimizationGuideModelStore
Absent : C:\Users\Utilisateurice\AppData\Local\Google\Chrome\User Data\OptimizationGuidePredictionModels

Vérification manuelle :
1. Ouvrir Chrome.
2. Aller sur chrome://policy/.
3. Cliquer sur Reload policies ou Actualiser les règles.
4. Vérifier que la policy suivante est présente et en état OK :
   - GenAILocalFoundationalModelSettings = 1
5. Vérifier que GenAiDefaultSettings n'apparaît plus.
6. Aller sur chrome://on-device-internals/.
7. Vérifier si un modèle local est encore présent.

Note :
Si Chrome était ouvert pendant l'exécution, fermer toutes les fenêtres Chrome puis relancer le navigateur.
