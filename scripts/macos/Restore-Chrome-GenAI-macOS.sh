#!/usr/bin/env bash

# Restore-Chrome-GenAI-macOS.sh
#
# Objectif :
# Restaurer le comportement par défaut de Chrome sur macOS pour les policies IA du projet.
#
# Fonctionnement :
# - Vérifie que le script est lancé avec sudo.
# - Sauvegarde le fichier de policies Chrome macOS s'il existe.
# - Supprime les policies IA appliquées par le projet.
# - Génère un rapport de restauration.
#
# Important :
# Ce script restaure uniquement les policies Chrome.
# Il ne restaure pas les fichiers locaux supprimés, comme screen_ai ou les modèles IA.
#
# À exécuter avec sudo :
# sudo ./Restore-Chrome-GenAI-macOS.sh

set -euo pipefail

REPORT_DIRECTORY="${1:-./reports}"
POLICY_PLIST="/Library/Managed Preferences/com.google.Chrome.plist"
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

mkdir -p "$REPORT_DIRECTORY" "$BACKUP_DIR"

POLICIES=(
    "AIModeSettings"
    "CreateThemesSettings"
    "DevToolsGenAiSettings"
    "GeminiActOnWebSettings"
    "GeminiSettings"
    "GenAILocalFoundationalModelSettings"
    "HelpMeWriteSettings"
    "HistorySearchSettings"
    "SearchContentSharingSettings"
    "GenAiDefaultSettings"
)

if [[ -f "$POLICY_PLIST" ]]; then
    BACKUP_PATH="$BACKUP_DIR/com.google.Chrome.plist.restore-backup-${DATE_FILE}"
    cp "$POLICY_PLIST" "$BACKUP_PATH"

    ACTIONS+=("Sauvegarde créée : $BACKUP_PATH")
    log "OK" "Sauvegarde créée : $BACKUP_PATH"

    TEMP_PLIST="$(mktemp)"
    trap 'rm -f "$TEMP_PLIST"' EXIT

    cp "$POLICY_PLIST" "$TEMP_PLIST"
    plutil -convert xml1 "$TEMP_PLIST"

    for cle in "${POLICIES[@]}"; do
        if /usr/libexec/PlistBuddy -c "Print :${cle}" "$TEMP_PLIST" >/dev/null 2>&1; then
            /usr/libexec/PlistBuddy -c "Delete :${cle}" "$TEMP_PLIST"

            ACTIONS+=("Policy supprimée : $cle")
            log "OK" "Policy supprimée : $cle"
        else
            ACTIONS+=("Policy absente : $cle")
        fi
    done

    cp "$TEMP_PLIST" "$POLICY_PLIST"
    chmod 644 "$POLICY_PLIST"
    chown root:wheel "$POLICY_PLIST"

    ACTIONS+=("Fichier de policy mis à jour : $POLICY_PLIST")
else
    ACTIONS+=("Fichier de policy absent : $POLICY_PLIST")
    log "AVERTISSEMENT" "Fichier de policy absent : $POLICY_PLIST"
fi

REPORT_PATH="$REPORT_DIRECTORY/chrome-genai-restore-report-macos.txt"

{
    echo "Rapport - Restauration Chrome GenAI / No-AI macOS"
    echo "Date : $DATE_NOW"
    echo
    echo "Utilisateur ciblé :"
    echo "$UTILISATEUR_REEL"
    echo
    echo "Fichier de policy :"
    echo "$POLICY_PLIST"
    echo
    echo "Policies ciblées par la restauration :"
    printf '%s\n' "${POLICIES[@]}"
    echo
    echo "Actions effectuées :"
    printf '%s\n' "${ACTIONS[@]}"
    echo
    echo "Vérification manuelle :"
    echo "1. Fermer complètement Google Chrome."
    echo "2. Relancer Google Chrome."
    echo "3. Aller sur chrome://policy/."
    echo "4. Cliquer sur Reload policies ou Actualiser les règles."
    echo "5. Vérifier que les policies du projet ne sont plus appliquées."
    echo
    echo "Note :"
    echo "Ce script restaure uniquement les policies Chrome appliquées par le projet."
    echo "Il ne restaure pas les fichiers locaux supprimés, comme screen_ai ou les modèles IA."
    echo "Si Chrome a besoin de certains composants, il pourra les retélécharger selon sa configuration et ses policies actives."
} > "$REPORT_PATH"

chown -R "$UTILISATEUR_REEL":staff "$REPORT_DIRECTORY" "$BACKUP_DIR" 2>/dev/null || true

log "OK" "Rapport généré : $REPORT_PATH"
log "INFO" "Ferme Chrome, relance-le, puis vérifie chrome://policy/."