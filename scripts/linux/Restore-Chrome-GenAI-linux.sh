#!/usr/bin/env bash

# Restore-Chrome-GenAI-linux.sh
#
# Objectif :
# Restaurer le comportement par défaut de Google Chrome sur Linux pour les policies IA du projet.
#
# Fonctionnement :
# - Vérifie que le script est lancé avec sudo.
# - Recherche les fichiers de policies créés par le projet.
# - Sauvegarde les fichiers trouvés avant suppression.
# - Supprime les fichiers JSON de policies du projet.
# - Génère un rapport de restauration.
#
# Important :
# Ce script restaure uniquement les policies Chrome appliquées par le projet.
# Il ne restaure pas les fichiers locaux supprimés, comme screen_ai ou les modèles IA.
#
# À exécuter avec sudo :
# sudo ./Restore-Chrome-GenAI-linux.sh
#
# Note :
# Ce script cible Google Chrome officiel.
# Pour Chromium, le chemin des policies peut être différent :
# /etc/chromium/policies/managed/

set -euo pipefail

REPORT_DIRECTORY="${1:-./reports}"
POLICY_DIR="/etc/opt/chrome/policies/managed"

TARGET_FILES=(
    "$POLICY_DIR/chrome-genai-hardening.json"
    "$POLICY_DIR/chrome-no-ai-hardening.json"
)

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

log "INFO" "Démarrage de la restauration Chrome GenAI / No-AI pour Linux."
log "INFO" "Utilisateur ciblé : $UTILISATEUR_REEL"
log "INFO" "Dossier de policies Chrome : $POLICY_DIR"

for fichier in "${TARGET_FILES[@]}"; do
    if [[ -f "$fichier" ]]; then
        nom="$(basename "$fichier")"
        sauvegarde="$BACKUP_DIR/${nom}.restore-backup-${DATE_FILE}"

        cp "$fichier" "$sauvegarde"
        rm -f "$fichier"

        ACTIONS+=("Fichier supprimé : $fichier")
        ACTIONS+=("Sauvegarde créée : $sauvegarde")

        log "OK" "Fichier de policy supprimé : $fichier"
        log "OK" "Sauvegarde créée : $sauvegarde"
    else
        ACTIONS+=("Fichier absent : $fichier")
        log "INFO" "Fichier absent : $fichier"
    fi
done

REPORT_PATH="$REPORT_DIRECTORY/chrome-genai-restore-report-linux.txt"

{
    echo "Rapport - Restauration Chrome GenAI / No-AI Linux"
    echo "Date : $DATE_NOW"
    echo
    echo "Utilisateur ciblé :"
    echo "$UTILISATEUR_REEL"
    echo
    echo "Dossier de policies Chrome :"
    echo "$POLICY_DIR"
    echo
    echo "Fichiers de policies ciblés :"
    printf '%s\n' "${TARGET_FILES[@]}"
    echo
    echo "Actions effectuées :"
    printf '%s\n' "${ACTIONS[@]}"
    echo
    echo "Policies normalement retirées après suppression des fichiers :"
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
    echo "3. Ouvrir chrome://policy/."
    echo "4. Cliquer sur Reload policies ou Actualiser les règles."
    echo "5. Vérifier que les policies du projet ne sont plus appliquées."
    echo "6. Vérifier que GenAiDefaultSettings n'apparaît pas."
    echo
    echo "Note :"
    echo "Ce script restaure uniquement les policies Chrome appliquées par le projet."
    echo "Il ne restaure pas les fichiers locaux supprimés, comme screen_ai ou les modèles IA."
    echo "Si Chrome a besoin de certains composants, il pourra les retélécharger selon sa configuration et ses policies actives."
    echo
    echo "Compatibilité :"
    echo "Ce script cible Google Chrome officiel avec le chemin : /etc/opt/chrome/policies/managed/."
    echo "Pour Chromium, le chemin peut être différent : /etc/chromium/policies/managed/."
} > "$REPORT_PATH"

chown -R "$UTILISATEUR_REEL":"$UTILISATEUR_REEL" "$REPORT_DIRECTORY" "$BACKUP_DIR" 2>/dev/null || true

log "OK" "Rapport généré : $REPORT_PATH"
log "INFO" "Ferme Chrome, relance-le, puis vérifie chrome://policy/."