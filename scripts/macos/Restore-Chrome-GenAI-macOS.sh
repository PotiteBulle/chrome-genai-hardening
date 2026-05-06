#!/usr/bin/env bash

# Restore-Chrome-GenAI-macOS.sh
#
# Objectif :
# Supprimer les policies Chrome GenAI appliquées par le script macOS.
#
# À exécuter avec sudo :
# sudo ./Restore-Chrome-GenAI-macOS.sh

set -euo pipefail

REPORT_DIRECTORY="${1:-./reports}"
POLICY_PLIST="/Library/Managed Preferences/com.google.Chrome.plist"
DATE_NOW="$(date '+%Y-%m-%d %H:%M:%S')"

ecrire_statut() {
    local niveau="$1"
    local message="$2"

    case "$niveau" in
        "OK")
            printf '[OK] %s\n' "$message"
            ;;
        "AVERTISSEMENT")
            printf '[AVERTISSEMENT] %s\n' "$message"
            ;;
        "ERREUR")
            printf '[ERREUR] %s\n' "$message"
            ;;
        *)
            printf '[INFO] %s\n' "$message"
            ;;
    esac
}

if [[ "${EUID}" -ne 0 ]]; then
    ecrire_statut "ERREUR" "Ce script doit être lancé avec sudo."
    ecrire_statut "INFO" "Exemple : sudo ./Restore-Chrome-GenAI-macOS.sh"
    exit 1
fi

mkdir -p "$REPORT_DIRECTORY"

ACTIONS=()

if [[ -f "$POLICY_PLIST" ]]; then
    TEMP_PLIST="$(mktemp)"
    cp "$POLICY_PLIST" "$TEMP_PLIST"
    plutil -convert xml1 "$TEMP_PLIST"

    for cle in "GenAILocalFoundationalModelSettings" "GenAiDefaultSettings"; do
        if /usr/libexec/PlistBuddy -c "Print :${cle}" "$TEMP_PLIST" >/dev/null 2>&1; then
            /usr/libexec/PlistBuddy -c "Delete :${cle}" "$TEMP_PLIST"
            ecrire_statut "OK" "Policy supprimée : $cle"
            ACTIONS+=("Supprimée : $cle")
        else
            ecrire_statut "INFO" "Policy absente : $cle"
            ACTIONS+=("Absente : $cle")
        fi
    done

    cp "$TEMP_PLIST" "$POLICY_PLIST"
    chmod 644 "$POLICY_PLIST"
    chown root:wheel "$POLICY_PLIST"
    rm -f "$TEMP_PLIST"
else
    ecrire_statut "AVERTISSEMENT" "Fichier de policy absent : $POLICY_PLIST"
    ACTIONS+=("Fichier de policy absent : $POLICY_PLIST")
fi

REPORT_PATH="${REPORT_DIRECTORY}/chrome-genai-restore-report-macos.txt"

{
    echo "Rapport - Restauration Chrome GenAI macOS"
    echo "Date : $DATE_NOW"
    echo
    echo "Chemin plist :"
    echo "$POLICY_PLIST"
    echo
    echo "Actions effectuées :"
    printf '%s\n' "${ACTIONS[@]}"
    echo
    echo "Vérification manuelle :"
    echo "1. Fermer toutes les fenêtres Chrome."
    echo "2. Relancer Chrome."
    echo "3. Aller sur chrome://policy/."
    echo "4. Cliquer sur Reload policies ou Actualiser les règles."
    echo "5. Vérifier que GenAILocalFoundationalModelSettings n'est plus appliquée."
} > "$REPORT_PATH"

ecrire_statut "OK" "Rapport généré : $REPORT_PATH"
ecrire_statut "INFO" "Redémarre Chrome puis vérifie chrome://policy/."