#!/bin/bash

# --- Variablen ---
HELM_VERSION="v3.18.6" # Aktuelle Helm-Version, kann bei Bedarf angepasst werden
HELM_INSTALL_DIR="/usr/local/bin" # Wo Helm installiert werden soll

# --- Funktionen ---

# Funktion zur Installation von curl, falls nicht vorhanden
install_curl_if_missing() {
    if ! command -v curl &> /dev/null; then
        echo "curl ist nicht installiert. Installiere curl..."
        sudo apt update
        sudo apt install -y curl
        if [ $? -ne 0 ]; then
            echo "Fehler: Konnte curl nicht installieren. Bitte manuell installieren und erneut versuchen."
            exit 1
        fi
        echo "curl erfolgreich installiert."
    fi
}

# --- Hauptskript Start ---

echo "=== Helm Installationsskript ==="
echo "Dieses Skript installiert Helm und richtet Bash/Zsh Autocompletion ein. 🚀"

# Sicherstellen, dass curl vorhanden ist
install_curl_if_missing

echo ""
echo "1. Helm ${HELM_VERSION} herunterladen und installieren..."

# Temporäres Verzeichnis erstellen
TMP_DIR=$(mktemp -d)
if [ $? -ne 0 ]; then
    echo "Fehler: Konnte temporäres Verzeichnis nicht erstellen. Abbruch."
    exit 1
fi
echo "Temporäres Verzeichnis: ${TMP_DIR}"

# Helm tarball herunterladen
echo "Lade Helm ${HELM_VERSION} von GitHub herunter..."
curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" -o "${TMP_DIR}/helm.tar.gz"
if [ $? -ne 0 ]; then
    echo "Fehler: Konnte Helm Tarball nicht herunterladen. Überprüfe die Version und Internetverbindung."
    rm -rf "${TMP_DIR}"
    exit 1
fi

# Helm entpacken
echo "Entpacke Helm..."
tar -zxvf "${TMP_DIR}/helm.tar.gz" -C "${TMP_DIR}"
if [ $? -ne 0 ]; then
    echo "Fehler: Konnte Helm Tarball nicht entpacken. Abbruch."
    rm -rf "${TMP_DIR}"
    exit 1
fi

# Helm ausführbar machen und in den Installationspfad verschieben
echo "Verschiebe Helm nach ${HELM_INSTALL_DIR}..."
sudo mv "${TMP_DIR}/linux-amd64/helm" "${HELM_INSTALL_DIR}/helm"
if [ $? -ne 0 ]; then
    echo "Fehler: Konnte Helm nicht in ${HELM_INSTALL_DIR} verschieben. Überprüfe Berechtigungen."
    rm -rf "${TMP_DIR}"
    exit 1
fi

# Berechtigungen setzen
sudo chmod +x "${HELM_INSTALL_DIR}/helm"

# Temporäres Verzeichnis aufräumen
echo "Räume temporäre Dateien auf..."
rm -rf "${TMP_DIR}"

echo "Helm ${HELM_VERSION} erfolgreich installiert! 🎉"
echo "Überprüfe die Installation: $(helm version --short)"

echo ""
echo "2. Helm Autocompletion für Bash/Zsh einrichten..."

CURRENT_SHELL=$(basename "$SHELL")

if [ "$CURRENT_SHELL" == "bash" ]; then
    echo "Einrichtung für Bash-Shell..."
    # Prüfen, ob .bashrc existiert
    if [ ! -f "$HOME/.bashrc" ]; then
        echo "Warnung: $HOME/.bashrc nicht gefunden. Erstelle es."
        touch "$HOME/.bashrc"
    fi
    # Command completion hinzufügen, falls nicht bereits vorhanden
    if ! grep -q 'source <(helm completion bash)' "$HOME/.bashrc"; then
        echo '# Helm Autocompletion' >> "$HOME/.bashrc"
        echo 'source <(helm completion bash)' >> "$HOME/.bashrc"
        echo 'echo "Helm Bash autocompletion geladen. ✨"' >> "$HOME/.bashrc"
        echo "Helm Bash autocompletion wurde zur $HOME/.bashrc hinzugefügt."
        echo "Bitte führe 'source $HOME/.bashrc' aus oder öffne ein neues Terminal, damit die Änderungen wirksam werden."
    else
        echo "Helm Bash autocompletion ist bereits in $HOME/.bashrc vorhanden."
    fi
elif [ "$CURRENT_SHELL" == "zsh" ]; then
    echo "Einrichtung für Zsh-Shell..."
    # Prüfen, ob .zshrc existiert
    if [ ! -f "$HOME/.zshrc" ]; then
        echo "Warnung: $HOME/.zshrc nicht gefunden. Erstelle es."
        touch "$HOME/.zshrc"
    fi
    # Autocompletion hinzufügen
    if ! grep -q 'source <(helm completion zsh)' "$HOME/.zshrc"; then
        echo '# Helm Autocompletion' >> "$HOME/.zshrc"
        echo 'source <(helm completion zsh)' >> "$HOME/.zshrc"
        echo 'echo "Helm Zsh autocompletion geladen. ✨"' >> "$HOME/.zshrc"
        echo "Helm Zsh autocompletion wurde zur $HOME/.zshrc hinzugefügt."
        echo "Bitte führe 'source $HOME/.zshrc' aus oder öffne ein neues Terminal, damit die Änderungen wirksam werden."
    else
        echo "Helm Zsh autocompletion ist bereits in $HOME/.zshrc vorhanden."
    fi
else
    echo "Deine Shell '$CURRENT_SHELL' wird nicht automatisch konfiguriert."
    echo "Du kannst die Autovervollständigung manuell einrichten, indem du die Befehle für deine Shell findest:"
    echo "   helm completion YOUR_SHELL"
    echo "und diese zu deiner Shell-Konfigurationsdatei (z.B. ~/.profile oder ~/.bash_profile) hinzufügst."
fi

echo ""
echo "=== Helm Installation abgeschlossen! Viel Spaß! 🎉 ==="
