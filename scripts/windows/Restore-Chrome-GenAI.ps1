<#
.SYNOPSIS
    Supprime les policies Chrome IA appliquées par le projet sous Windows.

.DESCRIPTION
    Ce script restaure le comportement par défaut de Chrome en supprimant les policies
    appliquées par les scripts du projet chrome-genai-hardening.

    Il supprime notamment les policies liées à :
    - GenAI / Gemini Nano.
    - Gemini.
    - AI Mode.
    - Help Me Write.
    - History Search avec IA.
    - Create Themes avec IA.
    - DevTools GenAI.
    - Search Content Sharing.

    Important :
    Ce script restaure uniquement les policies Chrome.
    Il ne restaure pas les fichiers locaux supprimés, comme screen_ai ou les modèles IA.

.NOTES
    À exécuter dans PowerShell en administrateurice.

    Exemple :
    .\Restore-Chrome-GenAI.ps1

    Simulation sans modification :
    .\Restore-Chrome-GenAI.ps1 -WhatIf
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

if (-not (Test-Administrateur)) {
    Ecrire-Statut "Ce script doit être lancé dans PowerShell en administrateurice." "ERREUR"
    exit 1
}

$DateExecution = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$DateFichier = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

$CheminPolicyChrome = "HKLM:\SOFTWARE\Policies\Google\Chrome"
$Actions = New-Object System.Collections.Generic.List[string]

$ReglesASupprimer = @(
    "AIModeSettings",
    "CreateThemesSettings",
    "DevToolsGenAiSettings",
    "GeminiActOnWebSettings",
    "GeminiSettings",
    "GenAILocalFoundationalModelSettings",
    "HelpMeWriteSettings",
    "HistorySearchSettings",
    "SearchContentSharingSettings",
    "GenAiDefaultSettings"
)

Ecrire-Statut "Démarrage de la restauration Chrome GenAI / No-AI sous Windows."

if (-not (Test-Path $ReportDirectory)) {
    New-Item -Path $ReportDirectory -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path $BackupDirectory)) {
    New-Item -Path $BackupDirectory -ItemType Directory -Force | Out-Null
}

if (Test-Path $CheminPolicyChrome) {
    $BackupPath = Join-Path $BackupDirectory "chrome-policies-restore-backup-$DateFichier.reg"

    try {
        $RegPathForExport = "HKLM\SOFTWARE\Policies\Google\Chrome"

        if ($PSCmdlet.ShouldProcess($BackupPath, "Sauvegarder les policies Chrome avant restauration")) {
            reg.exe export $RegPathForExport $BackupPath /y | Out-Null

            Ecrire-Statut "Sauvegarde registre créée : $BackupPath" "OK"
            $Actions.Add("Sauvegarde registre créée : $BackupPath")
        }
    }
    catch {
        Ecrire-Statut "Impossible de créer la sauvegarde registre : $($_.Exception.Message)" "AVERTISSEMENT"
        $Actions.Add("Erreur sauvegarde registre : $($_.Exception.Message)")
    }

    foreach ($Regle in $ReglesASupprimer) {
        try {
            $RegleExiste = Get-ItemProperty `
                -Path $CheminPolicyChrome `
                -Name $Regle `
                -ErrorAction SilentlyContinue

            if ($null -ne $RegleExiste) {
                if ($PSCmdlet.ShouldProcess($CheminPolicyChrome, "Supprimer la policy $Regle")) {
                    Remove-ItemProperty `
                        -Path $CheminPolicyChrome `
                        -Name $Regle `
                        -ErrorAction SilentlyContinue

                    Ecrire-Statut "Policy supprimée : $Regle" "OK"
                    $Actions.Add("Supprimée : $Regle")
                }
            }
            else {
                Ecrire-Statut "Policy absente : $Regle"
                $Actions.Add("Absente : $Regle")
            }
        }
        catch {
            Ecrire-Statut "Erreur lors de la suppression de $Regle : $($_.Exception.Message)" "AVERTISSEMENT"
            $Actions.Add("Erreur suppression : $Regle - $($_.Exception.Message)")
        }
    }
}
else {
    Ecrire-Statut "Clé Chrome Policy absente : $CheminPolicyChrome" "AVERTISSEMENT"
    $Actions.Add("Clé absente : $CheminPolicyChrome")
}

$CheminRapport = Join-Path $ReportDirectory "chrome-genai-restore-report.txt"

$PoliciesCibleesTexte = $ReglesASupprimer -join "`r`n"

$Rapport = @"
Rapport - Restauration Chrome GenAI / No-AI Windows
Date : $DateExecution

Chemin registre :
$CheminPolicyChrome

Policies ciblées par la restauration :
$PoliciesCibleesTexte

Actions effectuées :
$($Actions -join "`r`n")

Vérification manuelle :
1. Fermer complètement Google Chrome.
2. Relancer Google Chrome.
3. Ouvrir chrome://policy/.
4. Cliquer sur Reload policies ou Actualiser les règles.
5. Vérifier que les policies du projet ne sont plus appliquées.
6. Vérifier que GenAiDefaultSettings n'apparaît plus.

Note :
Ce script restaure uniquement les policies Chrome appliquées par le projet.
Il ne restaure pas les fichiers locaux supprimés, comme screen_ai ou les modèles IA.
Si Chrome a besoin de certains composants, il pourra les retélécharger selon sa configuration et ses policies actives.

Restauration manuelle possible :
Une sauvegarde .reg peut être présente dans le dossier backups si la clé de registre existait avant la restauration.
"@

$Rapport | Out-File -FilePath $CheminRapport -Encoding UTF8

Ecrire-Statut "Rapport généré : $CheminRapport" "OK"
Ecrire-Statut "Ferme Chrome, relance-le, puis vérifie chrome://policy/."