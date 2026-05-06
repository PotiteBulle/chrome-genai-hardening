#!/usr/bin/env bash

# Disable-Chrome-GenAI-linux.sh
#
# Objectif :
# Désactiver le téléchargement du modèle IA local GenAI / Gemini Nano de Google Chrome sur Linux.
#
# Fonctionnement :
# - Crée le dossier de policies Chrome si nécessaire.
# - Écrit une policy JSON dans /etc/opt/chrome/policies/managed/.
# - Applique GenAILocalFoundationalModelSettings = 1.
# - Supprime les anciens fichiers de policy du projet si nécessaire.
# - Recherche et supprime les dossiers locaux liés aux modèles IA.
# - Génère un rapport de vérification.
#
# À exécuter avec sudo :
# sudo ./Disable-Chrome-GenAI-linux.sh

set -euo pipefail

REPORT_DIRECTORY="${1:-./reports}"
POLICY_DIR="/etc/opt/chrome/policies/managed"
POLICY_FILE="${POLICY_DIR}/chrome-genai-hardening.json"
OLD_POLICY_FILE="${POLICY_DIR}/chrome-no-ai-hardening.json"
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
        ecrire_statut "INFO" "Exemple : sudo ./Disable-Chrome-GenAI-linux.sh"
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

ecrire_policy_ciblee() {
    cat > "$POLICY_FILE" <<'EOF'
{
  "GenAILocalFoundationalModelSettings": 1
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

ecrire_statut "INFO" "Démarrage du durcissement Chrome GenAI pour Linux."
ecrire_statut "INFO" "Utilisateur ciblé : $UTILISATEUR_REEL"
ecrire_statut "INFO" "Dossier personnel ciblé : $HOME_UTILISATEUR"

mkdir -p "$POLICY_DIR"
mkdir -p "$REPORT_DIRECTORY"
mkdir -p "$BACKUP_DIR"

if [[ -f "$POLICY_FILE" ]]; then
    cp "$POLICY_FILE" "$BACKUP_DIR/chrome-genai-hardening.json.backup-${DATE_FILE}"
    ecrire_statut "OK" "Sauvegarde créée : $BACKUP_DIR/chrome-genai-hardening.json.backup-${DATE_FILE}"
    ACTIONS+=("Sauvegarde créée : $BACKUP_DIR/chrome-genai-hardening.json.backup-${DATE_FILE}")
fi

if [[ -f "$OLD_POLICY_FILE" ]]; then
    cp "$OLD_POLICY_FILE" "$BACKUP_DIR/chrome-no-ai-hardening.json.backup-${DATE_FILE}"
    rm -f "$OLD_POLICY_FILE"
    ecrire_statut "OK" "Ancien fichier de policy supprimé : $OLD_POLICY_FILE"
    ACTIONS+=("Ancien fichier de policy supprimé : $OLD_POLICY_FILE")
fi

ecrire_policy_ciblee
chmod 644 "$POLICY_FILE"
chown root:root "$POLICY_FILE"

ecrire_statut "OK" "Policy appliquée : GenAILocalFoundationalModelSettings = 1"
ecrire_statut "OK" "Fichier de policy installé : $POLICY_FILE"
ACTIONS+=("Policy appliquée : GenAILocalFoundationalModelSettings = 1")
ACTIONS+=("Fichier de policy installé : $POLICY_FILE")

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

REPORT_PATH="${REPORT_DIRECTORY}/chrome-genai-policy-check-linux.txt"

{
    echo "Rapport - Chrome GenAI Hardening Linux"
    echo "Date : $DATE_NOW"
    echo
    echo "Utilisateur ciblé :"
    echo "$UTILISATEUR_REEL"
    echo
    echo "Policy appliquée :"
    echo "GenAILocalFoundationalModelSettings = 1"
    echo
    echo "Chemin policy JSON :"
    echo "$POLICY_FILE"
    echo
    echo "Actions effectuées :"
    printf '%s\n' "${ACTIONS[@]}"
    echo
    echo "Vérification manuelle :"
    echo "1. Fermer complètement Google Chrome."
    echo "2. Relancer Google Chrome."
    echo "3. Aller sur chrome://policy/."
    echo "4. Cliquer sur Reload policies ou Actualiser les règles."
    echo "5. Vérifier que la policy suivante est présente et en état OK :"
    echo "   - GenAILocalFoundationalModelSettings = 1"
    echo "6. Aller sur chrome://on-device-internals/."
    echo "7. Vérifier si le modèle local est absent ou en état Not Eligible."
    echo
    echo "Note :"
    echo "Ce script cible Google Chrome officiel avec le chemin : /etc/opt/chrome/policies/managed/."
    echo "Pour Chromium, le chemin peut être différent : /etc/chromium/policies/managed/."
} > "$REPORT_PATH"

chown -R "$UTILISATEUR_REEL":"$UTILISATEUR_REEL" "$REPORT_DIRECTORY" "$BACKUP_DIR" 2>/dev/null || true

ecrire_statut "OK" "Rapport généré : $REPORT_PATH"
ecrire_statut "INFO" "Ferme Chrome, relance-le, puis vérifie chrome://policy/."
ecrire_statut "INFO" "Résultat attendu : GenAILocalFoundationalModelSettings = 1 avec l'état OK."
