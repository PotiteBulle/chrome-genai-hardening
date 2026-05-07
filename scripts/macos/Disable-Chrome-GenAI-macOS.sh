#!/usr/bin/env bash

# Disable-Chrome-GenAI-macOS.sh
#
# Objectif :
# Désactiver le téléchargement du modèle IA local GenAI / Gemini Nano de Chrome sur macOS.
#
# Fonctionnement :
# - Crée ou met à jour le fichier de policies Chrome macOS.
# - Applique la policy GenAILocalFoundationalModelSettings = 1.
# - Supprime GenAiDefaultSettings si cette ancienne règle existe.
# - Recherche et supprime les dossiers locaux liés aux modèles IA.
# - Recherche et supprime les dossiers locaux liés à Screen AI / OCR.
# - Génère un rapport de vérification.
#
# À exécuter avec sudo :
# sudo ./Disable-Chrome-GenAI-macOS.sh

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
    log "OK" "Sauvegarde créée : $BACKUP_PATH"
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
    log "INFO" "Aucun fichier de policy existant. Création d'un nouveau fichier plist."
fi

plutil -convert xml1 "$TEMP_PLIST"

/usr/libexec/PlistBuddy -c "Delete :GenAILocalFoundationalModelSettings" "$TEMP_PLIST" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :GenAILocalFoundationalModelSettings integer 1" "$TEMP_PLIST"

ACTIONS+=("Policy appliquée : GenAILocalFoundationalModelSettings = 1")
log "OK" "Policy appliquée : GenAILocalFoundationalModelSettings = 1"

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

REPORT_PATH="$REPORT_DIRECTORY/chrome-genai-policy-check-macos.txt"

{
    echo "Rapport - Chrome GenAI Hardening macOS"
    echo "Date : $DATE_NOW"
    echo
    echo "Utilisateur ciblé :"
    echo "$UTILISATEUR_REEL"
    echo
    echo "Fichier de policy :"
    echo "$POLICY_PLIST"
    echo
    echo "Policy appliquée :"
    echo "GenAILocalFoundationalModelSettings = 1"
    echo
    echo "Règle nettoyée si présente :"
    echo "GenAiDefaultSettings"
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
    echo "5. Vérifier que GenAILocalFoundationalModelSettings = 1 est en état OK."
    echo "6. Vérifier que GenAiDefaultSettings n'apparaît plus."
    echo "7. Aller sur chrome://on-device-internals/."
    echo "8. Vérifier si le modèle local est absent ou en état Not Eligible."
    echo "9. Vérifier que le dossier screen_ai n'est plus présent dans le profil Chrome."
    echo
    echo "Note :"
    echo "Ce script applique uniquement le mode ciblé GenAI et nettoie les artefacts locaux connus."
} > "$REPORT_PATH"

chown -R "$UTILISATEUR_REEL":staff "$REPORT_DIRECTORY" "$BACKUP_DIR" 2>/dev/null || true

log "OK" "Rapport généré : $REPORT_PATH"
log "INFO" "Ferme Chrome, relance-le, puis vérifie chrome://policy/ et chrome://on-device-internals/."