#!/usr/bin/env bash

# Disable-Chrome-AI-Features-macOS.sh
#
# Objectif :
# Désactiver un maximum de fonctionnalités IA intégrées à Google Chrome sur macOS.
#
# Fonctionnement :
# - Crée ou met à jour le fichier de policies Chrome macOS.
# - Applique plusieurs policies Chrome Enterprise liées aux fonctionnalités IA.
# - Désactive le modèle IA local GenAI / Gemini Nano.
# - Supprime GenAiDefaultSettings si cette ancienne règle existe.
# - Recherche et supprime les dossiers locaux liés aux modèles IA.
# - Recherche et supprime les dossiers locaux liés à Screen AI / OCR.
# - Génère un rapport de vérification.
#
# À exécuter avec sudo :
# sudo ./Disable-Chrome-AI-Features-macOS.sh

set -euo pipefail

REPORT_DIRECTORY="${1:-./reports}"
POLICY_PLIST="/Library/Managed Preferences/com.google.Chrome.plist"
POLICY_DIR="$(dirname "$POLICY_PLIST")"
BACKUP_DIR="./backups"
DATE_NOW="$(date '+%Y-%m-%d %H:%M:%S')"
DATE_FILE="$(date '+%Y-%m-%d_%H-%M-%S')"
ACTIONS=()

log() {
    printf '[%s] %s\n' "$1" "$2"
}

if [[ "${EUID}" -ne 0 ]]; then
    log "ERREUR" "Ce script doit être lancé avec sudo."
    exit 1
fi

UTILISATEUR_REEL="${SUDO_USER:-$(logname 2>/dev/null || echo "$USER")}"
HOME_UTILISATEUR="$(dscl . -read "/Users/${UTILISATEUR_REEL}" NFSHomeDirectory 2>/dev/null | awk '{print $2}')"

if [[ -z "$HOME_UTILISATEUR" || ! -d "$HOME_UTILISATEUR" ]]; then
    log "ERREUR" "Dossier utilisateur introuvable."
    exit 1
fi

mkdir -p "$POLICY_DIR" "$REPORT_DIRECTORY" "$BACKUP_DIR"

TEMP_PLIST="$(mktemp)"
trap 'rm -f "$TEMP_PLIST"' EXIT

if [[ -f "$POLICY_PLIST" ]]; then
    BACKUP_PATH="$BACKUP_DIR/com.google.Chrome.plist.backup-${DATE_FILE}"
    cp "$POLICY_PLIST" "$BACKUP_PATH"
    cp "$POLICY_PLIST" "$TEMP_PLIST"
    ACTIONS+=("Sauvegarde créée : $BACKUP_PATH")
else
    cat > "$TEMP_PLIST" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
</dict>
</plist>
EOF
    ACTIONS+=("Création d'un nouveau fichier plist.")
fi

plutil -convert xml1 "$TEMP_PLIST"

POLICIES=(
    "AIModeSettings:1"
    "CreateThemesSettings:2"
    "DevToolsGenAiSettings:2"
    "GeminiActOnWebSettings:1"
    "GeminiSettings:1"
    "GenAILocalFoundationalModelSettings:1"
    "HelpMeWriteSettings:2"
    "HistorySearchSettings:2"
    "SearchContentSharingSettings:1"
)

for item in "${POLICIES[@]}"; do
    cle="${item%%:*}"
    valeur="${item##*:}"

    /usr/libexec/PlistBuddy -c "Delete :${cle}" "$TEMP_PLIST" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :${cle} integer ${valeur}" "$TEMP_PLIST"

    ACTIONS+=("Policy appliquée : ${cle} = ${valeur}")
    log "OK" "Policy appliquée : ${cle} = ${valeur}"
done

if /usr/libexec/PlistBuddy -c "Print :GenAiDefaultSettings" "$TEMP_PLIST" >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c "Delete :GenAiDefaultSettings" "$TEMP_PLIST"
    ACTIONS+=("Ancienne règle supprimée : GenAiDefaultSettings")
    log "OK" "Ancienne règle supprimée : GenAiDefaultSettings"
else
    ACTIONS+=("Ancienne règle absente : GenAiDefaultSettings")
fi

cp "$TEMP_PLIST" "$POLICY_PLIST"
chmod 644 "$POLICY_PLIST"
chown root:wheel "$POLICY_PLIST"

ACTIONS+=("Fichier de policy installé : $POLICY_PLIST")

CHEMINS=(
    "$HOME_UTILISATEUR/Library/Application Support/Google/Chrome/OptGuideOnDeviceModel"
    "$HOME_UTILISATEUR/Library/Application Support/Google/Chrome/OptimizationGuideModelStore"
    "$HOME_UTILISATEUR/Library/Application Support/Google/Chrome/OptimizationGuidePredictionModels"
    "$HOME_UTILISATEUR/Library/Application Support/Google/Chrome/User Data/OptGuideOnDeviceModel"
    "$HOME_UTILISATEUR/Library/Application Support/Google/Chrome/User Data/OptimizationGuideModelStore"
    "$HOME_UTILISATEUR/Library/Application Support/Google/Chrome/User Data/OptimizationGuidePredictionModels"
    "$HOME_UTILISATEUR/Library/Application Support/Google/Chrome/screen_ai"
    "$HOME_UTILISATEUR/Library/Application Support/Google/Chrome/User Data/screen_ai"
)

for chemin in "${CHEMINS[@]}"; do
    if [[ -d "$chemin" ]]; then
        taille="$(du -sm "$chemin" 2>/dev/null | awk '{print $1}')"
        rm -rf "$chemin"

        ACTIONS+=("Supprimé : $chemin (${taille:-0} MiB)")
        log "OK" "Dossier supprimé : $chemin"
    else
        ACTIONS+=("Absent : $chemin")
    fi
done

REPORT_PATH="$REPORT_DIRECTORY/chrome-no-ai-hardening-report-macos.txt"

{
    echo "Rapport - Chrome No-AI Hardening macOS"
    echo "Date : $DATE_NOW"
    echo
    echo "Utilisateur ciblé :"
    echo "$UTILISATEUR_REEL"
    echo
    echo "Fichier de policy :"
    echo "$POLICY_PLIST"
    echo
    echo "Artefacts locaux vérifiés :"
    echo "- modèles GenAI / OptimizationGuide"
    echo "- Screen AI / OCR local"
    echo
    echo "Actions effectuées :"
    printf '%s\n' "${ACTIONS[@]}"
    echo
    echo "Vérification manuelle :"
    echo "1. Fermer complètement Google Chrome."
    echo "2. Relancer Google Chrome."
    echo "3. Aller sur chrome://policy/."
    echo "4. Cliquer sur Reload policies ou Actualiser les règles."
    echo "5. Vérifier que les policies IA sont en état OK."
    echo "6. Aller sur chrome://on-device-internals/."
    echo "7. Vérifier si le modèle local est absent ou en état Not Eligible."
    echo "8. Vérifier que le dossier screen_ai n'est plus présent dans le profil Chrome."
} > "$REPORT_PATH"

chown -R "$UTILISATEUR_REEL":staff "$REPORT_DIRECTORY" "$BACKUP_DIR" 2>/dev/null || true

log "OK" "Rapport généré : $REPORT_PATH"
log "INFO" "Ferme Chrome, relance-le, puis vérifie chrome://policy/ et chrome://on-device-internals/."