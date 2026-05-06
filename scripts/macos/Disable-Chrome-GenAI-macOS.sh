#!/usr/bin/env bash

# Disable-Chrome-GenAI-macOS.sh
#
# Objectif :
# Désactiver le téléchargement du modèle IA local GenAI / Gemini Nano de Chrome sur macOS.
#
# Fonctionnement :
# - Crée ou met à jour le fichier de policies Chrome macOS.
# - Applique GenAILocalFoundationalModelSettings = 1.
# - Supprime GenAiDefaultSettings si cette ancienne règle existe.
# - Recherche et supprime les dossiers locaux liés aux modèles IA.
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
        ecrire_statut "INFO" "Exemple : sudo ./Disable-Chrome-GenAI-macOS.sh"
        exit 1
    fi
}

creer_plist_vide() {
    local fichier="$1"

    cat > "$fichier" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
</dict>
</plist>
EOF
}

definir_policy_integer() {
    local fichier="$1"
    local cle="$2"
    local valeur="$3"

    /usr/libexec/PlistBuddy -c "Delete :${cle}" "$fichier" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :${cle} integer ${valeur}" "$fichier"
}

supprimer_policy_si_presente() {
    local fichier="$1"
    local cle="$2"

    if /usr/libexec/PlistBuddy -c "Print :${cle}" "$fichier" >/dev/null 2>&1; then
        /usr/libexec/PlistBuddy -c "Delete :${cle}" "$fichier"
        ecrire_statut "OK" "Ancienne règle supprimée : ${cle}"
    else
        ecrire_statut "INFO" "Ancienne règle absente : ${cle}"
    fi
}

calculer_taille_mib() {
    local chemin="$1"

    if [[ -d "$chemin" ]]; then
        du -sm "$chemin" 2>/dev/null | awk '{print $1}'
    else
        echo "0"
    fi
}

verifier_root

ecrire_statut "INFO" "Démarrage du durcissement Chrome GenAI pour macOS."

mkdir -p "$POLICY_DIR"
mkdir -p "$REPORT_DIRECTORY"
mkdir -p "$BACKUP_DIR"

TEMP_PLIST="$(mktemp)"

if [[ -f "$POLICY_PLIST" ]]; then
    cp "$POLICY_PLIST" "$BACKUP_DIR/com.google.Chrome.plist.backup-${DATE_FILE}"
    cp "$POLICY_PLIST" "$TEMP_PLIST"
    ecrire_statut "OK" "Sauvegarde créée dans : $BACKUP_DIR"
else
    creer_plist_vide "$TEMP_PLIST"
    ecrire_statut "INFO" "Aucun fichier de policy existant. Création d'un nouveau fichier plist."
fi

plutil -convert xml1 "$TEMP_PLIST"

definir_policy_integer "$TEMP_PLIST" "GenAILocalFoundationalModelSettings" "1"
ecrire_statut "OK" "Policy appliquée : GenAILocalFoundationalModelSettings = 1"

supprimer_policy_si_presente "$TEMP_PLIST" "GenAiDefaultSettings"

cp "$TEMP_PLIST" "$POLICY_PLIST"
chmod 644 "$POLICY_PLIST"
chown root:wheel "$POLICY_PLIST"
rm -f "$TEMP_PLIST"

ecrire_statut "OK" "Fichier de policy installé : $POLICY_PLIST"

ACTIONS=()

CHEMINS_MODELES_POSSIBLES=(
    "$HOME/Library/Application Support/Google/Chrome/OptGuideOnDeviceModel"
    "$HOME/Library/Application Support/Google/Chrome/OptimizationGuideModelStore"
    "$HOME/Library/Application Support/Google/Chrome/OptimizationGuidePredictionModels"
)

ecrire_statut "INFO" "Recherche des dossiers locaux liés aux modèles IA."

for chemin in "${CHEMINS_MODELES_POSSIBLES[@]}"; do
    if [[ -d "$chemin" ]]; then
        taille_mib="$(calculer_taille_mib "$chemin")"

        ecrire_statut "AVERTISSEMENT" "Dossier trouvé : $chemin (${taille_mib} MiB)"

        rm -rf "$chemin"

        ecrire_statut "OK" "Dossier supprimé : $chemin"
        ACTIONS+=("Supprimé : $chemin (${taille_mib} MiB)")
    else
        ecrire_statut "INFO" "Absent : $chemin"
        ACTIONS+=("Absent : $chemin")
    fi
done

REPORT_PATH="${REPORT_DIRECTORY}/chrome-genai-policy-check-macos.txt"

{
    echo "Rapport - Chrome GenAI Hardening macOS"
    echo "Date : $DATE_NOW"
    echo
    echo "Policy appliquée :"
    echo "GenAILocalFoundationalModelSettings = 1"
    echo
    echo "Chemin plist :"
    echo "$POLICY_PLIST"
    echo
    echo "Règle supprimée si présente :"
    echo "GenAiDefaultSettings"
    echo
    echo "Actions effectuées :"
    printf '%s\n' "${ACTIONS[@]}"
    echo
    echo "Vérification manuelle :"
    echo "1. Fermer toutes les fenêtres Chrome."
    echo "2. Relancer Chrome."
    echo "3. Aller sur chrome://policy/."
    echo "4. Cliquer sur Reload policies ou Actualiser les règles."
    echo "5. Vérifier que la policy suivante est présente et en état OK :"
    echo "   - GenAILocalFoundationalModelSettings = 1"
    echo "6. Vérifier que GenAiDefaultSettings n'apparaît plus."
    echo "7. Aller sur chrome://on-device-internals/."
    echo "8. Vérifier si le modèle local est absent ou en état Not Eligible."
    echo
    echo "Note :"
    echo "Sur macOS, Chrome peut nécessiter un redémarrage complet pour relire les policies."
} > "$REPORT_PATH"

ecrire_statut "OK" "Rapport généré : $REPORT_PATH"
ecrire_statut "INFO" "Ferme Chrome, relance-le, puis vérifie chrome://policy/."
ecrire_statut "INFO" "Résultat attendu : GenAILocalFoundationalModelSettings = 1 avec l'état OK."