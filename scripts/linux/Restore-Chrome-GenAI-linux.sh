#!/usr/bin/env bash

# Restore-Chrome-GenAI-linux.sh
#
# Objectif :
# Supprimer les policies Chrome GenAI / No-AI appliquées par le projet sur Linux.
#
# Fonctionnement :
# - Sauvegarde les fichiers de policies du projet si présents.
# - Supprime les fichiers JSON créés par les scripts de durcissement.
# - Génère un rapport de restauration.
#
# À exécuter avec sudo :
# sudo ./Restore-Chrome-GenAI-linux.sh

set -euo pipefail

REPORT_DIRECTORY="${1:-./reports}"
POLICY_DIR="/etc/opt/chrome/policies/managed"
TARGET_FILES=(
    "${POLICY_DIR}/chrome-genai-hardening.json"
    "${POLICY_DIR}/chrome-no-ai-hardening.json"
)

BACKUP_DIR="./backups"
DATE_NOW="$(date '+%Y-%m-%d %H:%M:%S')"
DATE_FILE="$(date '+%Y-%m-%d_%H-%M-%S')"

ACTIONS=()

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

verifier_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        ecrire_statut "ERREUR" "Ce script doit être lancé avec sudo."
        ecrire_statut "INFO" "Exemple : sudo ./Restore-Chrome-GenAI-linux.sh"
        exit 1
    fi
}

determiner_utilisateur_reel() {
    if [[ -n "${SUDO_USER:-}" ]]; then
        echo "$SUDO_USER"
    else
        logname 2>/dev/null || echo "$USER"
    fi
}

verifier_root

UTILISATEUR_REEL="$(determiner_utilisateur_reel)"

ecrire_statut "INFO" "Démarrage de la restauration Chrome GenAI / No-AI pour Linux."

mkdir -p "$REPORT_DIRECTORY"
mkdir -p "$BACKUP_DIR"

for fichier in "${TARGET_FILES[@]}"; do
    if [[ -f "$fichier" ]]; then
        nom_fichier="$(basename "$fichier")"
        sauvegarde="${BACKUP_DIR}/${nom_fichier}.restore-backup-${DATE_FILE}"

        cp "$fichier" "$sauvegarde"
        rm -f "$fichier"

        ecrire_statut "OK" "Fichier de policy supprimé : $fichier"
        ecrire_statut "OK" "Sauvegarde créée : $sauvegarde"

        ACTIONS+=("Fichier supprimé : $fichier")
        ACTIONS+=("Sauvegarde créée : $sauvegarde")
    else
        ecrire_statut "INFO" "Fichier absent : $fichier"
        ACTIONS+=("Fichier absent : $fichier")
    fi
done

REPORT_PATH="${REPORT_DIRECTORY}/chrome-genai-restore-report-linux.txt"

{
    echo "Rapport - Restauration Chrome GenAI / No-AI Linux"
    echo "Date : $DATE_NOW"
    echo
    echo "Chemin policies :"
    echo "$POLICY_DIR"
    echo
    echo "Actions effectuées :"
    printf '%s\n' "${ACTIONS[@]}"
    echo
    echo "Policies retirées si présentes :"
    echo "AIModeSettings"
    echo "CreateThemesSettings"
    echo "DevToolsGenAiSettings"
    echo "GeminiActOnWebSettings"
    echo "GeminiSettings"
    echo "GenAILocalFoundationalModelSettings"
    echo "HelpMeWriteSettings"
    echo "HistorySearchSettings"
    echo "SearchContentSharingSettings"
    echo "GenAiDefaultSettings"
    echo
    echo "Vérification manuelle :"
    echo "1. Fermer complètement Google Chrome."
    echo "2. Relancer Google Chrome."
    echo "3. Aller sur chrome://policy/."
    echo "4. Cliquer sur Reload policies ou Actualiser les règles."
    echo "5. Vérifier que les policies du projet ne sont plus appliquées."
    echo
    echo "Note :"
    echo "Ce script supprime uniquement les fichiers de policies créés par le projet."
    echo "Il ne supprime pas les fichiers de policies appartenant à d'autres outils ou à une entreprise."
} > "$REPORT_PATH"

chown -R "$UTILISATEUR_REEL":"$UTILISATEUR_REEL" "$REPORT_DIRECTORY" "$BACKUP_DIR" 2>/dev/null || true

ecrire_statut "OK" "Rapport généré : $REPORT_PATH"
ecrire_statut "INFO" "Ferme Chrome, relance-le, puis vérifie chrome://policy/."
