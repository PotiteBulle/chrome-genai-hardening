<#
.SYNOPSIS
    Désactive le téléchargement du modèle IA local GenAI / Gemini Nano de Chrome sous Windows.

.DESCRIPTION
    Ce script applique la policy Chrome Enterprise locale suivante :

    GenAILocalFoundationalModelSettings = 1

    Cette policy demande à Chrome de ne pas télécharger le modèle IA local utilisé
    par certaines fonctionnalités GenAI, notamment Gemini Nano.

    Le script nettoie également les artefacts locaux connus :
    - modèles GenAI / OptimizationGuide.
    - Screen AI / OCR local.

.NOTES
    À exécuter dans PowerShell en administrateurice.

    Exemple :
    .\Disable-Chrome-GenAI.ps1

    Simulation sans modification :
    .\Disable-Chrome-GenAI.ps1 -WhatIf
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$ReportDirectory = ".\reports",
    [string]$BackupDirectory = ".\backups"
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

function Obtenir-TailleDossierMo {
    param(
        [string]$Chemin
    )

    try {
        $TailleOctets = (
            Get-ChildItem -Path $Chemin -Recurse -Force -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum
        ).Sum

        if ($null -eq $TailleOctets) {
            $TailleOctets = 0
        }

        return [Math]::Round(($TailleOctets / 1MB), 2)
    }
    catch {
        return 0
    }
}

if (-not (Test-Administrateur)) {
    Ecrire-Statut "Ce script doit être lancé dans PowerShell en administrateurice." "ERREUR"
    exit 1
}

$DateExecution = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$DateFichier = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

$CheminPolicyChrome = "HKLM:\SOFTWARE\Policies\Google\Chrome"
$Actions = New-Object System.Collections.Generic.List[string]

Ecrire-Statut "Démarrage du durcissement Chrome GenAI sous Windows."

if (-not (Test-Path $ReportDirectory)) {
    New-Item -Path $ReportDirectory -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path $BackupDirectory)) {
    New-Item -Path $BackupDirectory -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path $CheminPolicyChrome)) {
    if ($PSCmdlet.ShouldProcess($CheminPolicyChrome, "Créer la clé de registre Chrome Policy")) {
        New-Item -Path $CheminPolicyChrome -Force | Out-Null

        Ecrire-Statut "Clé de registre créée : $CheminPolicyChrome" "OK"
        $Actions.Add("Clé de registre créée : $CheminPolicyChrome")
    }
}
else {
    Ecrire-Statut "Clé de registre existante : $CheminPolicyChrome"
    $Actions.Add("Clé de registre existante : $CheminPolicyChrome")
}

$BackupPath = Join-Path $BackupDirectory "chrome-policies-backup-$DateFichier.reg"

if (Test-Path $CheminPolicyChrome) {
    try {
        $RegPathForExport = "HKLM\SOFTWARE\Policies\Google\Chrome"

        if ($PSCmdlet.ShouldProcess($BackupPath, "Sauvegarder les policies Chrome existantes")) {
            reg.exe export $RegPathForExport $BackupPath /y | Out-Null

            Ecrire-Statut "Sauvegarde registre créée : $BackupPath" "OK"
            $Actions.Add("Sauvegarde registre créée : $BackupPath")
        }
    }
    catch {
        Ecrire-Statut "Impossible de créer la sauvegarde registre : $($_.Exception.Message)" "AVERTISSEMENT"
        $Actions.Add("Erreur sauvegarde registre : $($_.Exception.Message)")
    }
}

try {
    if ($PSCmdlet.ShouldProcess($CheminPolicyChrome, "Appliquer GenAILocalFoundationalModelSettings = 1")) {
        New-ItemProperty `
            -Path $CheminPolicyChrome `
            -Name "GenAILocalFoundationalModelSettings" `
            -PropertyType DWord `
            -Value 1 `
            -Force | Out-Null

        Ecrire-Statut "Policy appliquée : GenAILocalFoundationalModelSettings = 1" "OK"
        $Actions.Add("Policy appliquée : GenAILocalFoundationalModelSettings = 1")
    }
}
catch {
    Ecrire-Statut "Erreur lors de l'application de GenAILocalFoundationalModelSettings : $($_.Exception.Message)" "ERREUR"
    $Actions.Add("Erreur policy GenAILocalFoundationalModelSettings : $($_.Exception.Message)")
}

$AncienneRegle = "GenAiDefaultSettings"

try {
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
            $Actions.Add("Ancienne règle supprimée : GenAiDefaultSettings")
        }
    }
    else {
        Ecrire-Statut "Ancienne règle absente : GenAiDefaultSettings"
        $Actions.Add("Ancienne règle absente : GenAiDefaultSettings")
    }
}
catch {
    Ecrire-Statut "Erreur lors du nettoyage de GenAiDefaultSettings : $($_.Exception.Message)" "AVERTISSEMENT"
    $Actions.Add("Erreur nettoyage GenAiDefaultSettings : $($_.Exception.Message)")
}

$CheminsLocaux = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\OptGuideOnDeviceModel",
    "$env:LOCALAPPDATA\Google\Chrome\OptGuideOnDeviceModel",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\OptimizationGuideModelStore",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\OptimizationGuidePredictionModels",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\screen_ai"
)

Ecrire-Statut "Recherche des artefacts locaux liés aux modèles IA et à Screen AI."

foreach ($Chemin in $CheminsLocaux) {
    if (Test-Path $Chemin) {
        try {
            $TailleMo = Obtenir-TailleDossierMo -Chemin $Chemin

            Ecrire-Statut "Dossier trouvé : $Chemin ($TailleMo Mo)" "AVERTISSEMENT"

            if ($PSCmdlet.ShouldProcess($Chemin, "Supprimer le dossier local")) {
                Remove-Item -Path $Chemin -Recurse -Force -ErrorAction Stop

                Ecrire-Statut "Dossier supprimé : $Chemin" "OK"
                $Actions.Add("Supprimé : $Chemin ($TailleMo Mo)")
            }
        }
        catch {
            Ecrire-Statut "Impossible de supprimer : $Chemin" "ERREUR"
            Ecrire-Statut $_.Exception.Message "ERREUR"

            $Actions.Add("Erreur suppression : $Chemin - $($_.Exception.Message)")
        }
    }
    else {
        Ecrire-Statut "Absent : $Chemin"
        $Actions.Add("Absent : $Chemin")
    }
}

$CheminRapport = Join-Path $ReportDirectory "chrome-genai-policy-check.txt"

$Rapport = @"
Rapport - Chrome GenAI Hardening Windows
Date : $DateExecution

Chemin registre :
$CheminPolicyChrome

Policy appliquée :
GenAILocalFoundationalModelSettings = 1

Règle nettoyée si présente :
GenAiDefaultSettings

Artefacts locaux vérifiés :
- modèles GenAI / OptimizationGuide
- Screen AI / OCR local

Chemins vérifiés :
$($CheminsLocaux -join "`r`n")

Actions effectuées :
$($Actions -join "`r`n")

Vérification manuelle :
1. Fermer complètement Google Chrome.
2. Relancer Google Chrome.
3. Ouvrir chrome://policy/.
4. Cliquer sur Reload policies ou Actualiser les règles.
5. Vérifier que GenAILocalFoundationalModelSettings = 1 est en état OK.
6. Vérifier que GenAiDefaultSettings n'apparaît plus.
7. Ouvrir chrome://on-device-internals/.
8. Vérifier que le modèle local est absent ou en état Not Eligible.
9. Vérifier que le dossier screen_ai n'est plus présent dans le profil Chrome.

Résultat attendu dans chrome://policy/ :
GenAILocalFoundationalModelSettings    1    OK

Note :
Ce script applique uniquement le mode ciblé GenAI et nettoie les artefacts locaux connus.
Il ne garantit pas le blocage de toutes les fonctionnalités IA côté serveur affichées dans une page web.
"@

$Rapport | Out-File -FilePath $CheminRapport -Encoding UTF8

Ecrire-Statut "Rapport généré : $CheminRapport" "OK"
Ecrire-Statut "Ferme Chrome, relance-le, puis vérifie chrome://policy/ et chrome://on-device-internals/."