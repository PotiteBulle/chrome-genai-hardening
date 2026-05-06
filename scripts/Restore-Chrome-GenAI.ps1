<#
.SYNOPSIS
    Supprime les policies appliquees par Disable-Chrome-GenAI.ps1.

.DESCRIPTION
    Ce script restaure le comportement par defaut de Chrome en supprimant les valeurs registre
    utilisees pour bloquer le modele IA local GenAI. Il ne retelecharge rien et ne force pas
    l'activation des fonctionnalites IA.

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

$ChromePolicyPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"
$Removed = New-Object System.Collections.Generic.List[string]

if (Test-Path $ChromePolicyPath) {
    foreach ($Name in @("GenAILocalFoundationalModelSettings", "GenAiDefaultSettings")) {
        $Property = Get-ItemProperty -Path $ChromePolicyPath -Name $Name -ErrorAction SilentlyContinue

        if ($null -ne $Property) {
            if ($PSCmdlet.ShouldProcess("$ChromePolicyPath\$Name", "Supprimer la policy")) {
                Remove-ItemProperty -Path $ChromePolicyPath -Name $Name -ErrorAction SilentlyContinue
                Write-Status "Policy supprimee : $Name" "OK"
                $Removed.Add("Supprimee : $Name")
            }
        }
        else {
            Write-Status "Policy absente : $Name"
            $Removed.Add("Absente : $Name")
        }
    }
}
else {
    Write-Status "Cle Chrome Policy absente : $ChromePolicyPath" "WARN"
    $Removed.Add("Cle absente : $ChromePolicyPath")
}

if (-not (Test-Path $ReportDirectory)) {
    New-Item -Path $ReportDirectory -ItemType Directory -Force | Out-Null
}

$ReportPath = Join-Path $ReportDirectory "chrome-genai-restore-report.txt"

$Report = @"
Rapport - Restauration Chrome GenAI
Date : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Chemin registre :
$ChromePolicyPath

Actions effectuees :
$($Removed -join "`r`n")

Verification manuelle :
1. Redemarrer Chrome.
2. Aller sur chrome://policy/.
3. Cliquer sur Reload policies.
4. Verifier que les policies supprimees ne sont plus appliquees.
"@

$Report | Out-File -FilePath $ReportPath -Encoding UTF8

Write-Status "Rapport genere : $ReportPath" "OK"
Write-Status "Redemarre Chrome puis verifie chrome://policy/."
