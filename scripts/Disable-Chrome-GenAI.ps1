<#
.SYNOPSIS
    Désactive le téléchargement du modèle IA local GenAI / Gemini Nano de Chrome.

.DESCRIPTION
    Ce script applique une policy Chrome Enterprise locale via le registre Windows.
    La règle utilisée est GenAILocalFoundationalModelSettings = 1.

    Cette règle demande à Chrome de ne pas télécharger le modèle IA local utilisé
    par certaines fonctionnalités GenAI, notamment Gemini Nano.

    Le script supprime aussi l'ancienne règle GenAiDefaultSettings si elle existe,
    car certaines versions de Chrome l'ignorent lorsqu'elle n'est pas configurée
    depuis une source cloud.

.NOTES
    À exécuter dans PowerShell en administrateur.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$ReportDirectory = ".\reports"
)

function Test-Administrateur {
    $Identite = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($Identite)

    return $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Ecrire-Statut {
    param(
        [string]$Message,
        [string]$Niveau = "INFO"
    )

    switch ($Niveau) {
        "OK" {
            Write-Host "[OK] $Message" -ForegroundColor Green
        }
        "AVERTISSEMENT" {
            Write-Host "[AVERTISSEMENT] $Message" -ForegroundColor Yellow
        }
        "ERREUR" {
            Write-Host "[ERREUR] $Message" -ForegroundColor Red
        }
        default {
            Write-Host "[INFO] $Message" -ForegroundColor Cyan
        }
    }
}

if (-not (Test-Administrateur)) {
    Ecrire-Statut "Ce script doit être lancé dans PowerShell en administrateur." "ERREUR"
    exit 1
}

Ecrire-Statut "Démarrage du durcissement Chrome GenAI."

$CheminPolicyChrome = "HKLM:\SOFTWARE\Policies\Google\Chrome"

if (-not (Test-Path $CheminPolicyChrome)) {
    if ($PSCmdlet.ShouldProcess($CheminPolicyChrome, "Créer la clé de registre Chrome Policy")) {
        New-Item -Path $CheminPolicyChrome -Force | Out-Null
        Ecrire-Statut "Clé de registre créée : $CheminPolicyChrome" "OK"
    }
}

if ($PSCmdlet.ShouldProcess($CheminPolicyChrome, "Appliquer GenAILocalFoundationalModelSettings = 1")) {
    New-ItemProperty `
        -Path $CheminPolicyChrome `
        -Name "GenAILocalFoundationalModelSettings" `
        -PropertyType DWord `
        -Value 1 `
        -Force | Out-Null

    Ecrire-Statut "Policy appliquée : GenAILocalFoundationalModelSettings = 1" "OK"
}

# Nettoyage de l'ancienne règle complémentaire si elle existe.
# Cette règle peut générer une erreur dans chrome://policy/ lorsqu'elle n'est pas fournie par une source cloud.
$AncienneRegle = "GenAiDefaultSettings"

$RegleExiste = Get-ItemProperty `
    -Path $CheminPolicyChrome `
    -Name $AncienneRegle `
    -ErrorAction SilentlyContinue

if ($null -ne $RegleExiste) {
    if ($PSCmdlet.ShouldProcess($CheminPolicyChrome, "Supprimer l'ancienne règle GenAiDefaultSettings")) {
        Remove-ItemProperty `
            -Path $CheminPolicyChrome `
            -Name $AncienneRegle `
            -ErrorAction SilentlyContinue

        Ecrire-Statut "Ancienne règle supprimée : GenAiDefaultSettings" "OK"
    }
}
else {
    Ecrire-Statut "Ancienne règle GenAiDefaultSettings absente. Aucun nettoyage nécessaire."
}

$CheminsModelesPossibles = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\OptGuideOnDeviceModel",
    "$env:LOCALAPPDATA\Google\Chrome\OptGuideOnDeviceModel",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\OptimizationGuideModelStore",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\OptimizationGuidePredictionModels"
)

$Actions = New-Object System.Collections.Generic.List[string]

Ecrire-Statut "Recherche des dossiers locaux liés aux modèles IA."

foreach ($Chemin in $CheminsModelesPossibles) {
    if (Test-Path $Chemin) {
        try {
            $TailleOctets = (
                Get-ChildItem -Path $Chemin -Recurse -Force -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum
            ).Sum

            if ($null -eq $TailleOctets) {
                $TailleOctets = 0
            }

            $TailleGo = [Math]::Round(($TailleOctets / 1GB), 2)

            Ecrire-Statut "Dossier trouvé : $Chemin ($TailleGo Go)" "AVERTISSEMENT"

            if ($PSCmdlet.ShouldProcess($Chemin, "Supprimer le dossier de modèle local")) {
                Remove-Item -Path $Chemin -Recurse -Force -ErrorAction Stop

                Ecrire-Statut "Dossier supprimé : $Chemin" "OK"
                $Actions.Add("Supprimé : $Chemin ($TailleGo Go)")
            }
        }
        catch {
            Ecrire-Statut "Impossible de supprimer : $Chemin" "ERREUR"
            Ecrire-Statut $_.Exception.Message "ERREUR"
            $Actions.Add("Erreur lors de la suppression : $Chemin - $($_.Exception.Message)")
        }
    }
    else {
        Ecrire-Statut "Absent : $Chemin"
        $Actions.Add("Absent : $Chemin")
    }
}

if (-not (Test-Path $ReportDirectory)) {
    New-Item -Path $ReportDirectory -ItemType Directory -Force | Out-Null
}

$CheminRapport = Join-Path $ReportDirectory "chrome-genai-policy-check.txt"
$VerificationPolicy = Get-ItemProperty -Path $CheminPolicyChrome

$ValeurPolicyPrincipale = $VerificationPolicy.GenAILocalFoundationalModelSettings

$Rapport = @"
Rapport - Chrome GenAI Hardening
Date : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Policy appliquée :
GenAILocalFoundationalModelSettings = $ValeurPolicyPrincipale

Chemin registre :
$CheminPolicyChrome

Règle supprimée si présente :
GenAiDefaultSettings

Actions effectuées :
$($Actions -join "`r`n")

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
"@

$Rapport | Out-File -FilePath $CheminRapport -Encoding UTF8

Ecrire-Statut "Rapport généré : $CheminRapport" "OK"
Ecrire-Statut "Ouvre Chrome, va sur chrome://policy/, puis clique sur Reload policies ou Actualiser les règles."
Ecrire-Statut "Résultat attendu : GenAILocalFoundationalModelSettings = 1 avec l'état OK."