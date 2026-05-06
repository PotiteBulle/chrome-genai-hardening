<#
.SYNOPSIS
    Desactive le telechargement du modele IA local GenAI/Gemini Nano de Chrome.

.DESCRIPTION
    Ce script applique des policies Chrome Enterprise via le registre Windows afin de limiter
    le telechargement du modele IA local GenAI. Il recherche aussi certains dossiers locaux
    lies aux modeles IA et les supprime lorsqu'ils sont presents.

.NOTES
    Execution recommandee : PowerShell en administrateurice.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$ReportDirectory = ".\reports"
)

function Test-IsAdministrator {
    $CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)
    return $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Write-Status {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    switch ($Level) {
        "OK"    { Write-Host "[OK] $Message" -ForegroundColor Green }
        "WARN"  { Write-Host "[WARN] $Message" -ForegroundColor Yellow }
        "ERROR" { Write-Host "[ERROR] $Message" -ForegroundColor Red }
        default { Write-Host "[INFO] $Message" -ForegroundColor Cyan }
    }
}

if (-not (Test-IsAdministrator)) {
    Write-Status "Lance ce script en PowerShell administrateurice." "ERROR"
    exit 1
}

Write-Status "Demarrage du durcissement Chrome GenAI."

$ChromePolicyPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"

if (-not (Test-Path $ChromePolicyPath)) {
    if ($PSCmdlet.ShouldProcess($ChromePolicyPath, "Creer la cle registre Chrome Policy")) {
        New-Item -Path $ChromePolicyPath -Force | Out-Null
        Write-Status "Cle registre creee : $ChromePolicyPath" "OK"
    }
}

if ($PSCmdlet.ShouldProcess($ChromePolicyPath, "Appliquer GenAILocalFoundationalModelSettings = 1")) {
    New-ItemProperty `
        -Path $ChromePolicyPath `
        -Name "GenAILocalFoundationalModelSettings" `
        -PropertyType DWord `
        -Value 1 `
        -Force | Out-Null

    Write-Status "Policy appliquee : GenAILocalFoundationalModelSettings = 1" "OK"
}

if ($PSCmdlet.ShouldProcess($ChromePolicyPath, "Appliquer GenAiDefaultSettings = 2")) {
    New-ItemProperty `
        -Path $ChromePolicyPath `
        -Name "GenAiDefaultSettings" `
        -PropertyType DWord `
        -Value 2 `
        -Force | Out-Null

    Write-Status "Policy complementaire appliquee : GenAiDefaultSettings = 2" "OK"
}

$PossibleModelPaths = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\OptGuideOnDeviceModel",
    "$env:LOCALAPPDATA\Google\Chrome\OptGuideOnDeviceModel",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\OptimizationGuideModelStore",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\OptimizationGuidePredictionModels"
)

$Actions = New-Object System.Collections.Generic.List[string]

Write-Status "Recherche des dossiers locaux lies aux modeles IA."

foreach ($Path in $PossibleModelPaths) {
    if (Test-Path $Path) {
        try {
            $SizeBytes = (Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum).Sum

            if ($null -eq $SizeBytes) {
                $SizeBytes = 0
            }

            $SizeGB = [Math]::Round(($SizeBytes / 1GB), 2)
            Write-Status "Dossier trouve : $Path ($SizeGB Go)" "WARN"

            if ($PSCmdlet.ShouldProcess($Path, "Supprimer le dossier de modele local")) {
                Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
                Write-Status "Dossier supprime : $Path" "OK"
                $Actions.Add("Supprime : $Path ($SizeGB Go)")
            }
        }
        catch {
            Write-Status "Impossible de supprimer : $Path" "ERROR"
            Write-Status $_.Exception.Message "ERROR"
            $Actions.Add("Erreur suppression : $Path - $($_.Exception.Message)")
        }
    }
    else {
        Write-Status "Absent : $Path"
        $Actions.Add("Absent : $Path")
    }
}

if (-not (Test-Path $ReportDirectory)) {
    New-Item -Path $ReportDirectory -ItemType Directory -Force | Out-Null
}

$ReportPath = Join-Path $ReportDirectory "chrome-genai-policy-check.txt"
$PolicyCheck = Get-ItemProperty -Path $ChromePolicyPath

$Report = @"
Rapport - Chrome GenAI Hardening
Date : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Policies appliquees :
GenAILocalFoundationalModelSettings = $($PolicyCheck.GenAILocalFoundationalModelSettings)
GenAiDefaultSettings                = $($PolicyCheck.GenAiDefaultSettings)

Chemin registre :
$ChromePolicyPath

Actions effectuees :
$($Actions -join "`r`n")

Verification manuelle :
1. Ouvrir Chrome.
2. Aller sur chrome://policy/.
3. Cliquer sur Reload policies.
4. Verifier :
   - GenAILocalFoundationalModelSettings = 1
   - GenAiDefaultSettings = 2
5. Aller sur chrome://on-device-internals/.
6. Verifier si un modele local est encore present.

Note :
Si Chrome etait ouvert pendant l'execution, fermer puis relancer Chrome.
"@

$Report | Out-File -FilePath $ReportPath -Encoding UTF8

Write-Status "Rapport genere : $ReportPath" "OK"
Write-Status "Ouvre Chrome puis va sur chrome://policy/ et clique sur Reload policies."
