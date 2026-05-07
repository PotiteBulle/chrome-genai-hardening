#!/usr/bin/env bash

# Disable-Chrome-AI-Features-linux.sh
#
# Objectif :
# Désactiver un maximum de fonctionnalités IA intégrées à Google Chrome sur Linux.
#
# Fonctionnement :
# - Vérifie que le script est lancé avec sudo.
# - Crée le dossier de policies Chrome si nécessaire.
# - Sauvegarde les anciens fichiers de policies du projet s'ils existent.
# - Écrit un fichier JSON de policies Chrome Enterprise.
# - Applique plusieurs policies liées aux fonctionnalités IA de Chrome.
# - Désactive le modèle IA local GenAI / Gemini Nano.
# - Supprime l'ancien fichier ciblé si le mode renforcé est utilisé.
# - Recherche et supprime les dossiers locaux liés aux modèles IA.
# - Recherche et supprime les dossiers locaux liés à Screen AI / OCR.
# - Génère un rapport de vérification.
#
# À exécuter avec sudo :
# sudo ./Disable-Chrome-AI-Features-linux.sh
#
# Note :
# Ce script cible Google Chrome officiel.
# Pour Chromium, le chemin des policies peut être différent :
# /etc/chromium/policies/managed/

set -euo pipefail

REPORT_DIRECTORY="${1:-./reports}"
POLICY_DIR="/etc/opt/chrome/policies/managed"
POLICY_FILE="$POLICY_DIR/chrome-no-ai-hardening.json"
OLD_POLICY_FILE="$POLICY_DIR/chrome-genai-hardening.json"
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
HOME_UTILISATEUR="$(getent passwd "$UTILISATEUR_REEL" | cut -d: -f6)"

if [[ -z "$HOME_UTILISATEUR" || ! -d "$HOME_UTILISATEUR" ]]; then
    log "ERREUR" "Dossier utilisateur introuvable."
    exit 1
fi

mkdir -p "$POLICY_DIR" "$REPORT_DIRECTORY" "$BACKUP_DIR"

log "INFO" "Démarrage du durcissement Chrome No-AI pour Linux."
log "INFO" "Utilisateur ciblé : $UTILISATEUR_REEL"
log "INFO" "Dossier utilisateur : $HOME_UTILISATEUR"

if [[ -f "$POLICY_FILE" ]]; then
    BACKUP_PATH="$BACKUP_DIR/chrome-no-ai-hardening.json.backup-${DATE_FILE}"
    cp "$POLICY_FILE" "$BACKUP_PATH"

    ACTIONS+=("Sauvegarde créée : $BACKUP_PATH")
    log "OK" "Sauvegarde créée : $BACKUP_PATH"
fi

if [[ -f "$OLD_POLICY_FILE" ]]; then
    OLD_BACKUP_PATH="$BACKUP_DIR/chrome-genai-hardening.json.backup-${DATE_FILE}"
    cp "$OLD_POLICY_FILE" "$OLD_BACKUP_PATH"
    rm -f "$OLD_POLICY_FILE"

    ACTIONS+=("Sauvegarde de l'ancien fichier ciblé : $OLD_BACKUP_PATH")
    ACTIONS+=("Ancien fichier ciblé supprimé : $OLD_POLICY_FILE")

    log "OK" "Sauvegarde de l'ancien fichier ciblé : $OLD_BACKUP_PATH"
    log "OK" "Ancien fichier ciblé supprimé : $OLD_POLICY_FILE"
fi

cat > "$POLICY_FILE" <<'EOF'
{
  "AIModeSettings": 1,
  "CreateThemesSettings": 2,
  "DevToolsGenAiSettings": 2,
  "GeminiActOnWebSettings": 1,
  "GeminiSettings": 1,
  "GenAILocalFoundationalModelSettings": 1,
  "HelpMeWriteSettings": 2,
  "HistorySearchSettings": 2,
  "SearchContentSharingSettings": 1
}
EOF

chmod 644 "$POLICY_FILE"
chown root:root "$POLICY_FILE"

ACTIONS+=("Fichier de policy installé : $POLICY_FILE")
log "OK" "Fichier de policy installé : $POLICY_FILE"

POLICIES_APPLIQUEES=(
    "AIModeSettings = 1"
    "CreateThemesSettings = 2"
    "DevToolsGenAiSettings = 2"
    "GeminiActOnWebSettings = 1"
    "GeminiSettings = 1"
    "GenAILocalFoundationalModelSettings = 1"
    "HelpMeWriteSettings = 2"
    "HistorySearchSettings = 2"
    "SearchContentSharingSettings = 1"
)

for policy in "${POLICIES_APPLIQUEES[@]}"; do
    ACTIONS+=("Policy appliquée : $policy")
    log "OK" "Policy appliquée : $policy"
done

CHEMINS=(
    "$HOME_UTILISATEUR/.config/google-chrome/OptGuideOnDeviceModel"
    "$HOME_UTILISATEUR/.config/google-chrome/OptimizationGuideModelStore"
    "$HOME_UTILISATEUR/.config/google-chrome/OptimizationGuidePredictionModels"
    "$HOME_UTILISATEUR/.config/google-chrome/User Data/OptGuideOnDeviceModel"
    "$HOME_UTILISATEUR/.config/google-chrome/User Data/OptimizationGuideModelStore"
    "$HOME_UTILISATEUR/.config/google-chrome/User Data/OptimizationGuidePredictionModels"
    "$HOME_UTILISATEUR/.config/google-chrome/screen_ai"
    "$HOME_UTILISATEUR/.config/google-chrome/User Data/screen_ai"
)

log "INFO" "Recherche des artefacts locaux liés aux modèles IA et à Screen AI."

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

REPORT_PATH="$REPORT_DIRECTORY/chrome-no-ai-hardening-report-linux.txt"

{
    echo "Rapport - Chrome No-AI Hardening Linux"
    echo "Date : $DATE_NOW"
    echo
    echo "Utilisateur ciblé :"
    echo "$UTILISATEUR_REEL"
    echo
    echo "Dossier utilisateur :"
    echo "$HOME_UTILISATEUR"
    echo
    echo "Dossier de policies Chrome :"
    echo "$POLICY_DIR"
    echo
    echo "Fichier de policy installé :"
    echo "$POLICY_FILE"
    echo
    echo "Policies appliquées :"
    printf '%s\n' "${POLICIES_APPLIQUEES[@]}"
    echo
    echo "Artefacts locaux vérifiés :"
    echo "- modèles GenAI / OptimizationGuide"
    echo "- Screen AI / OCR local"
    echo
    echo "Chemins vérifiés :"
    printf '%s\n' "${CHEMINS[@]}"
    echo
    echo "Actions effectuées :"
    printf '%s\n' "${ACTIONS[@]}"
    echo
    echo "Vérification manuelle :"
    echo "1. Fermer complètement Google Chrome."
    echo "2. Relancer Google Chrome."
    echo "3. Ouvrir chrome://policy/."
    echo "4. Cliquer sur Reload policies ou Actualiser les règles."
    echo "5. Vérifier que les policies IA sont en état OK."
    echo "6. Vérifier que GenAiDefaultSettings n'apparaît pas."
    echo "7. Ouvrir chrome://on-device-internals/."
    echo "8. Vérifier que le modèle local est absent ou en état Not Eligible."
    echo "9. Vérifier que le dossier screen_ai n'est plus présent dans le profil Chrome."
    echo
    echo "Résultat attendu dans chrome://policy/ :"
    echo "AIModeSettings                       1    OK"
    echo "CreateThemesSettings                 2    OK"
    echo "DevToolsGenAiSettings                2    OK"
    echo "GeminiActOnWebSettings               1    OK"
    echo "GeminiSettings                       1    OK"
    echo "GenAILocalFoundationalModelSettings  1    OK"
    echo "HelpMeWriteSettings                  2    OK"
    echo "HistorySearchSettings                2    OK"
    echo "SearchContentSharingSettings         1    OK"
    echo
    echo "Note :"
    echo "Ce script cible Google Chrome officiel avec le chemin : /etc/opt/chrome/policies/managed/."
    echo "Pour Chromium, le chemin peut être différent : /etc/chromium/policies/managed/."
    echo "Ce script applique les policies IA Chrome connues et nettoie les artefacts locaux connus."
    echo "Il ne garantit pas le blocage de tous les contenus IA côté serveur affichés dans une page web."
} > "$REPORT_PATH"

chown -R "$UTILISATEUR_REEL":"$UTILISATEUR_REEL" "$REPORT_DIRECTORY" "$BACKUP_DIR" 2>/dev/null || true

log "OK" "Rapport généré : $REPORT_PATH"
log "INFO" "Ferme Chrome, relance-le, puis vérifie chrome://policy/ et chrome://on-device-internals/."