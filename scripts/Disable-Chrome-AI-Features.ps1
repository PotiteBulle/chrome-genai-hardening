<#
.SYNOPSIS
    Désactive un maximum de fonctionnalités IA intégrées à Google Chrome.

.DESCRIPTION
    Ce script applique plusieurs policies Chrome Enterprise locales via le registre Windows.
    L'objectif est de réduire au maximum les fonctionnalités IA intégrées à Chrome :
    modèle IA local, Gemini, AI Mode, aide à l'écriture, historique IA, thèmes IA,
    DevTools IA et partage de contenu avec les fonctions IA.

.NOTES
    À exécuter dans PowerShell en administrateurice.
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
    Ecrire-Statut "Ce script doit être lancé dans PowerShell en administrateurice." "ERREUR"
    exit 1
}

$CheminPolicyChrome = "HKLM:\SOFTWARE\Policies\Google\Chrome"

if (-not (Test-Path $CheminPolicyChrome)) {
    if ($PSCmdlet.ShouldProcess($CheminPolicyChrome, "Créer la clé de registre Chrome Policy")) {
        New-Item -Path $CheminPolicyChrome -Force | Out-Null
        Ecrire-Statut "Clé de registre créée : $CheminPolicyChrome" "OK"
    }
}

$PoliciesIA = @{
    "GenAILocalFoundationalModelSettings" = 1
    "GeminiSettings"                     = 1
    "AIModeSettings"                     = 1
    "HelpMeWriteSettings"                = 2
    "HistorySearchSettings"              = 2
    "CreateThemesSettings"               = 2
    "DevToolsGenAiSettings"              = 2
    "SearchContentSharingSettings"       = 1
    "GeminiActOnWebSettings"             = 1
}

$Actions = New-Object System.Collections.Generic.List[string]

foreach ($Policy in $PoliciesIA.GetEnumerator()) {
    $Nom = $Policy.Key
    $Valeur = $Policy.Value

    if ($PSCmdlet.ShouldProcess($CheminPolicyChrome, "Appliquer $Nom = $Valeur")) {
        New-ItemProperty `
            -Path $CheminPolicyChrome `
            -Name $Nom `
            -PropertyType DWord `
            -Value $Valeur `
            -Force | Out-Null

        Ecrire-Statut "Policy appliquée : $Nom = $Valeur" "OK"
        $Actions.Add("Policy appliquée : $Nom = $Valeur")
    }
}

# Nettoyage de GenAiDefaultSettings si elle existe.
# Cette règle peut être ignorée localement par Chrome lorsqu'elle n'est pas fournie par une source cloud.
$AncienneRegle = "GenAiDefaultSettings"

$RegleExiste = Get-ItemProperty `
    -Path $CheminPolicyChrome `
    -Name $AncienneRegle `
    -ErrorAction SilentlyContinue

if ($null -ne $RegleExiste) {
    if ($PSCmdlet.ShouldProcess($CheminPolicyChrome, "Supprimer GenAiDefaultSettings")) {
        Remove-ItemProperty `
            -Path $CheminPolicyChrome `
            -Name $AncienneRegle `
            -ErrorAction SilentlyContinue

        Ecrire-Statut "Ancienne règle supprimée : GenAiDefaultSettings" "OK"
        $Actions.Add("Ancienne règle supprimée : GenAiDefaultSettings")
    }
}

$CheminsModelesPossibles = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\OptGuideOnDeviceModel",
    "$env:LOCALAPPDATA\Google\Chrome\OptGuideOnDeviceModel",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\OptimizationGuideModelStore",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\OptimizationGuidePredictionModels"
)

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

            if ($PSCmdlet.ShouldProcess($Chemin, "Supprimer le dossier de modèle local")) {
                Remove-Item -Path $Chemin -Recurse -Force -ErrorAction Stop

                Ecrire-Statut "Dossier supprimé : $Chemin" "OK"
                $Actions.Add("Dossier supprimé : $Chemin ($TailleGo Go)")
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

if (-not (Test-Path $ReportDirectory)) {
    New-Item -Path $ReportDirectory -ItemType Directory -Force | Out-Null
}

$CheminRapport = Join-Path $ReportDirectory "chrome-no-ai-hardening-report.txt"

$Rapport = @"
Rapport - Chrome No-AI Hardening
Date : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Chemin registre :
$CheminPolicyChrome

Policies IA appliquées :
$(
    $PoliciesIA.GetEnumerator() |
    Sort-Object Name |
    ForEach-Object { "$($_.Key) = $($_.Value)" } |
    Out-String
)

Actions effectuées :
$($Actions -join "`r`n")

Vérification manuelle :
1. Ouvrir Chrome.
2. Aller sur chrome://policy/.
3. Cliquer sur Reload policies ou Actualiser les règles.
4. Vérifier que les policies appliquées sont en état OK.
5. Aller sur chrome://on-device-internals/.
6. Vérifier que le modèle local est en état Not Eligible ou absent.
7. Aller dans chrome://settings/ai si disponible.
8. Vérifier que les fonctions IA ne sont plus disponibles.

Limite :
Ce script désactive les fonctionnalités IA intégrées à Chrome via policies locales.
Il ne garantit pas le blocage de tous les contenus IA côté serveur affichés dans une page web.
"@

$Rapport | Out-File -FilePath $CheminRapport -Encoding UTF8

Ecrire-Statut "Rapport généré : $CheminRapport" "OK"
Ecrire-Statut "Ouvre chrome://policy/ puis clique sur Reload policies ou Actualiser les règles."