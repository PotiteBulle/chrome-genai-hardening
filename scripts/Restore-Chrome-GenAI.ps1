<#
.SYNOPSIS
    Restaure le comportement par défaut de Chrome pour la policy GenAI locale.

.DESCRIPTION
    Ce script supprime la policy GenAILocalFoundationalModelSettings appliquée
    par le script Disable-Chrome-GenAI.ps1.

    Il supprime aussi GenAiDefaultSettings si elle existe encore, afin de nettoyer
    une ancienne configuration qui pouvait provoquer une erreur dans chrome://policy/.

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

$CheminPolicyChrome = "HKLM:\SOFTWARE\Policies\Google\Chrome"
$Actions = New-Object System.Collections.Generic.List[string]

Ecrire-Statut "Démarrage de la restauration Chrome GenAI."

if (Test-Path $CheminPolicyChrome) {
    $ReglesASupprimer = @(
        "GenAILocalFoundationalModelSettings",
        "GenAiDefaultSettings"
    )

    foreach ($Regle in $ReglesASupprimer) {
        $RegleExiste = Get-ItemProperty `
            -Path $CheminPolicyChrome `
            -Name $Regle `
            -ErrorAction SilentlyContinue

        if ($null -ne $RegleExiste) {
            if ($PSCmdlet.ShouldProcess($CheminPolicyChrome, "Supprimer la règle $Regle")) {
                Remove-ItemProperty `
                    -Path $CheminPolicyChrome `
                    -Name $Regle `
                    -ErrorAction SilentlyContinue

                Ecrire-Statut "Règle supprimée : $Regle" "OK"
                $Actions.Add("Supprimée : $Regle")
            }
        }
        else {
            Ecrire-Statut "Règle absente : $Regle"
            $Actions.Add("Absente : $Regle")
        }
    }
}
else {
    Ecrire-Statut "Clé Chrome Policy absente : $CheminPolicyChrome" "AVERTISSEMENT"
    $Actions.Add("Clé absente : $CheminPolicyChrome")
}

if (-not (Test-Path $ReportDirectory)) {
    New-Item -Path $ReportDirectory -ItemType Directory -Force | Out-Null
}

$CheminRapport = Join-Path $ReportDirectory "chrome-genai-restore-report.txt"

$Rapport = @"
Rapport - Restauration Chrome GenAI
Date : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Chemin registre :
$CheminPolicyChrome

Actions effectuées :
$($Actions -join "`r`n")

Vérification manuelle :
1. Redémarrer Chrome.
2. Aller sur chrome://policy/.
3. Cliquer sur Reload policies ou Actualiser les règles.
4. Vérifier que GenAILocalFoundationalModelSettings n'est plus appliquée.
5. Vérifier que GenAiDefaultSettings n'apparaît plus.

Note :
Ce script ne télécharge rien et ne force aucune fonctionnalité IA.
Il supprime uniquement les policies locales appliquées par le projet.
"@

$Rapport | Out-File -FilePath $CheminRapport -Encoding UTF8

Ecrire-Statut "Rapport généré : $CheminRapport" "OK"
Ecrire-Statut "Redémarre Chrome puis vérifie chrome://policy/."