#!/usr/bin/env bash

# Disable-Chrome-AI-Features-linux.sh
#
# Objectif :
# Désactiver un maximum de fonctionnalités IA intégrées à Google Chrome sur Linux.
#
# Fonctionnement :
# - Crée le dossier de policies Chrome si nécessaire.
# - Écrit une policy JSON dans /etc/opt/chrome/policies/managed/.
# - Applique plusieurs policies Chrome Enterprise liées aux fonctionnalités IA.
# - Désactive le modèle IA local GenAI / Gemini Nano.
# - Recherche et supprime les dossiers locaux liés aux modèles IA.
# - Génère un rapport de vérification.
#
# À exécuter avec sudo :
# sudo ./Disable-Chrome-AI-Features-linux.sh

set -euo pipefail

REPORT_DIRECTORY="${1:-./reports}"
POLICY_DIR="/etc/opt/chrome/policies/managed"
POLICY_FILE="${POLICY_DIR}/chrome-no-ai-hardening.json"
OLD_POLICY_FILE="${POLICY_DIR}/chrome-genai-hardening.json"
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
        ecrire_statut "INFO" "Exemple : sudo ./Disable-Chrome-AI-Features-linux.sh"
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

determiner_home_utilisateur() {
    local utilisateur="$1"
    getent passwd "$utilisateur" | cut -d: -f6
}

calculer_taille_mib() {
    local chemin="$1"

    if [[ -d "$chemin" ]]; then
        du -sm "$chemin" 2>/dev/null | awk '{print $1}'
    else
        echo "0"
    fi
}

ecrire_policy_renforcee() {
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
}

verifier_root

UTILISATEUR_REEL="$(determiner_utilisateur_reel)"
HOME_UTILISATEUR="$(determiner_home_utilisateur "$UTILISATEUR_REEL")"

if [[ -z "$HOME_UTILISATEUR" || ! -d "$HOME_UTILISATEUR" ]]; then
    ecrire_statut "ERREUR" "Impossible de déterminer le dossier personnel de l'utilisateur réel."
    exit 1
fi

ecrire_statut "INFO" "Démarrage du durcissement Chrome No-AI pour Linux."
ecrire_statut "INFO" "Utilisateur ciblé : $UTILISATEUR_REEL"
ecrire_statut "INFO" "Dossier personnel ciblé : $HOME_UTILISATEUR"

mkdir -p "$POLICY_DIR"
mkdir -p "$REPORT_DIRECTORY"
mkdir -p "$BACKUP_DIR"

if [[ -f "$POLICY_FILE" ]]; then
    cp "$POLICY_FILE" "$BACKUP_DIR/chrome-no-ai-hardening.json.backup-${DATE_FILE}"
    ecrire_statut "OK" "Sauvegarde créée : $BACKUP_DIR/chrome-no-ai-hardening.json.backup-${DATE_FILE}"
    ACTIONS+=("Sauvegarde créée : $BACKUP_DIR/chrome-no-ai-hardening.json.backup-${DATE_FILE}")
fi

if [[ -f "$OLD_POLICY_FILE" ]]; then
    cp "$OLD_POLICY_FILE" "$BACKUP_DIR/chrome-genai-hardening.json.backup-${DATE_FILE}"
    rm -f "$OLD_POLICY_FILE"
    ecrire_statut "OK" "Ancien fichier ciblé supprimé : $OLD_POLICY_FILE"
    ACTIONS+=("Ancien fichier ciblé supprimé : $OLD_POLICY_FILE")
fi

ecrire_policy_renforcee
chmod 644 "$POLICY_FILE"
chown root:root "$POLICY_FILE"

ecrire_statut "OK" "Fichier de policy installé : $POLICY_FILE"
ACTIONS+=("Fichier de policy installé : $POLICY_FILE")

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
    ecrire_statut "OK" "Policy appliquée : $policy"
    ACTIONS+=("Policy appliquée : $policy")
done

CHEMINS_MODELES_POSSIBLES=(
    "$HOME_UTILISATEUR/.config/google-chrome/OptGuideOnDeviceModel"
    "$HOME_UTILISATEUR/.config/google-chrome/OptimizationGuideModelStore"
    "$HOME_UTILISATEUR/.config/google-chrome/OptimizationGuidePredictionModels"
    "$HOME_UTILISATEUR/.config/google-chrome/User Data/OptGuideOnDeviceModel"
    "$HOME_UTILISATEUR/.config/google-chrome/User Data/OptimizationGuideModelStore"
    "$HOME_UTILISATEUR/.config/google-chrome/User Data/OptimizationGuidePredictionModels"
)

ecrire_statut "INFO" "Recherche des dossiers locaux liés aux modèles IA."

for chemin in "${CHEMINS_MODELES_POSSIBLES[@]}"; do
    if [[ -d "$chemin" ]]; then
        taille_mib="$(calculer_taille_mib "$chemin")"

        ecrire_statut "AVERTISSEMENT" "Dossier trouvé : $chemin (${taille_mib} MiB)"

        rm -rf "$chemin"

        ecrire_statut "OK" "Dossier supprimé : $chemin"
        ACTIONS+=("Dossier supprimé : $chemin (${taille_mib} MiB)")
    else
        ecrire_statut "INFO" "Absent : $chemin"
        ACTIONS+=("Absent : $chemin")
    fi
done

REPORT_PATH="${REPORT_DIRECTORY}/chrome-no-ai-hardening-report-linux.txt"

{
    echo "Rapport - Chrome No-AI Hardening Linux"
    echo "Date : $DATE_NOW"
    echo
    echo "Utilisateur ciblé :"
    echo "$UTILISATEUR_REEL"
    echo
    echo "Chemin policy JSON :"
    echo "$POLICY_FILE"
    echo
    echo "Policies IA appliquées :"
    printf '%s\n' "${POLICIES_APPLIQUEES[@]}"
    echo
    echo "Actions effectuées :"
    printf '%s\n' "${ACTIONS[@]}"
    echo
    echo "Vérification manuelle :"
    echo "1. Fermer complètement Google Chrome."
    echo "2. Relancer Google Chrome."
    echo "3. Aller sur chrome://policy/."
    echo "4. Cliquer sur Reload policies ou Actualiser les règles."
    echo "5. Vérifier que les policies suivantes sont présentes et en état OK :"
    echo "   - AIModeSettings = 1"
    echo "   - CreateThemesSettings = 2"
    echo "   - DevToolsGenAiSettings = 2"
    echo "   - GeminiActOnWebSettings = 1"
    echo "   - GeminiSettings = 1"
    echo "   - GenAILocalFoundationalModelSettings = 1"
    echo "   - HelpMeWriteSettings = 2"
    echo "   - HistorySearchSettings = 2"
    echo "   - SearchContentSharingSettings = 1"
    echo "6. Vérifier que GenAiDefaultSettings n'apparaît pas."
    echo "7. Aller sur chrome://on-device-internals/."
    echo "8. Vérifier si le modèle local est absent ou en état Not Eligible."
    echo
    echo "Limite :"
    echo "Ce script désactive les fonctionnalités IA intégrées à Chrome via policies locales."
    echo "Il ne garantit pas le blocage de tous les contenus IA côté serveur affichés dans une page web."
    echo
    echo "Note :"
    echo "Ce script cible Google Chrome officiel avec le chemin : /etc/opt/chrome/policies/managed/."
    echo "Pour Chromium, le chemin peut être différent : /etc/chromium/policies/managed/."
} > "$REPORT_PATH"

chown -R "$UTILISATEUR_REEL":"$UTILISATEUR_REEL" "$REPORT_DIRECTORY" "$BACKUP_DIR" 2>/dev/null || true

ecrire_statut "OK" "Rapport généré : $REPORT_PATH"
ecrire_statut "INFO" "Ferme Chrome, relance-le, puis vérifie chrome://policy/."
ecrire_statut "INFO" "Résultat attendu : policies IA en état OK dans chrome://policy/."
