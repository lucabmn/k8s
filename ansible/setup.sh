#!/bin/bash

# Farben für die Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funktion zum Prüfen, ob ein Befehl erfolgreich war
check_command() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1 erfolgreich${NC}"
    else
        echo -e "${RED}✗ $1 fehlgeschlagen${NC}"
        exit 1
    fi
}

# Funktion zum Prüfen, ob ein Paket bereits installiert ist
is_package_installed() {
    if [ "$OS" = "Ubuntu" ] || [ "$OS" = "Debian GNU/Linux" ]; then
        dpkg -l "$1" &> /dev/null
    elif [ "$OS" = "CentOS Linux" ] || [ "$OS" = "Red Hat Enterprise Linux" ]; then
        rpm -q "$1" &> /dev/null
    elif [ "$OS" = "macOS" ]; then
        if [ "$1" = "python3" ]; then
            command -v python3 &> /dev/null
        elif [ "$1" = "ansible" ]; then
            command -v ansible &> /dev/null
        elif [ "$1" = "openssh-server" ]; then
            systemsetup -getremotelogin &> /dev/null
        fi
    fi
    return $?
}

echo -e "${YELLOW}=== Kubernetes Cluster Setup - Voraussetzungen Installation ===${NC}"

# Prüfen, ob wir Root-Rechte haben
if [ "$(uname)" != "Darwin" ] && [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Bitte führen Sie dieses Skript mit sudo aus:${NC}"
    echo "sudo $0"
    exit 1
fi

# Betriebssystem erkennen
if [ "$(uname)" = "Darwin" ]; then
    OS="macOS"
elif [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
else
    echo -e "${RED}Betriebssystem konnte nicht erkannt werden${NC}"
    exit 1
fi

echo -e "${YELLOW}Betriebssystem erkannt: $OS${NC}"

# Python3 installieren
echo -e "\n${YELLOW}Prüfe Python3 Installation...${NC}"
if ! is_package_installed python3; then
    echo "Python3 wird installiert..."
    if [ "$OS" = "macOS" ]; then
        if ! command -v brew &> /dev/null; then
            echo "Homebrew wird installiert..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            check_command "Homebrew Installation"
        fi
        brew install python3
    elif [ "$OS" = "Ubuntu" ] || [ "$OS" = "Debian GNU/Linux" ]; then
        apt update
        apt install -y python3 python3-pip
    elif [ "$OS" = "CentOS Linux" ] || [ "$OS" = "Red Hat Enterprise Linux" ]; then
        yum install -y python3 python3-pip
    fi
    check_command "Python3 Installation"
else
    echo -e "${GREEN}Python3 ist bereits installiert${NC}"
fi

# Ansible installieren
echo -e "\n${YELLOW}Prüfe Ansible Installation...${NC}"
if ! is_package_installed ansible; then
    echo "Ansible wird installiert..."
    if [ "$OS" = "macOS" ]; then
        brew install ansible
    elif [ "$OS" = "Ubuntu" ] || [ "$OS" = "Debian GNU/Linux" ]; then
        apt install -y software-properties-common
        apt-add-repository --yes --update ppa:ansible/ansible
        apt install -y ansible
    elif [ "$OS" = "CentOS Linux" ] || [ "$OS" = "Red Hat Enterprise Linux" ]; then
        yum install -y epel-release
        yum install -y ansible
    fi
    check_command "Ansible Installation"
else
    echo -e "${GREEN}Ansible ist bereits installiert${NC}"
fi

# SSH Server installieren und konfigurieren
echo -e "\n${YELLOW}Prüfe SSH Server Installation...${NC}"
if [ "$OS" = "macOS" ]; then
    if ! systemsetup -getremotelogin | grep -q "On"; then
        echo "SSH Server wird aktiviert..."
        systemsetup -setremotelogin on
        check_command "SSH Server Aktivierung"
    else
        echo -e "${GREEN}SSH Server ist bereits aktiviert${NC}"
    fi
elif ! is_package_installed openssh-server; then
    echo "SSH Server wird installiert..."
    if [ "$OS" = "Ubuntu" ] || [ "$OS" = "Debian GNU/Linux" ]; then
        apt install -y openssh-server
    elif [ "$OS" = "CentOS Linux" ] || [ "$OS" = "Red Hat Enterprise Linux" ]; then
        yum install -y openssh-server
    fi
    check_command "SSH Server Installation"
else
    echo -e "${GREEN}SSH Server ist bereits installiert${NC}"
fi

# SSH Service starten und aktivieren
echo -e "\n${YELLOW}Starte SSH Service...${NC}"
if [ "$OS" = "macOS" ]; then
    # SSH ist bereits aktiviert durch systemsetup
    echo -e "${GREEN}SSH Service ist aktiv${NC}"
elif [ "$OS" = "Ubuntu" ] || [ "$OS" = "Debian GNU/Linux" ]; then
    systemctl enable ssh
    systemctl start ssh
    check_command "SSH Service Start"
elif [ "$OS" = "CentOS Linux" ] || [ "$OS" = "Red Hat Enterprise Linux" ]; then
    systemctl enable sshd
    systemctl start sshd
    check_command "SSH Service Start"
fi

# SSH Key Setup
echo -e "\n${YELLOW}Richte SSH Keys ein...${NC}"

# .ssh Verzeichnis erstellen falls nicht vorhanden
if [ ! -d ~/.ssh ]; then
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    check_command "SSH Verzeichnis erstellt"
else
    echo -e "${GREEN}SSH Verzeichnis existiert bereits${NC}"
fi

# SSH Key generieren, falls noch nicht vorhanden
if [ ! -f ~/.ssh/id_rsa ]; then
    echo -e "${YELLOW}Generiere neuen SSH Key...${NC}"
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    check_command "SSH Key Generierung"
else
    echo -e "${GREEN}SSH Key existiert bereits${NC}"
fi

# Berechtigungen setzen
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
check_command "SSH Key Berechtigungen gesetzt"

# SSH Key anzeigen
echo -e "\n${YELLOW}Ihr öffentlicher SSH Key:${NC}"
cat ~/.ssh/id_rsa.pub

echo -e "\n${GREEN}=== Installation abgeschlossen! ===${NC}"
echo -e "\n${YELLOW}Nächste Schritte:${NC}"
echo "1. Bearbeiten Sie die Datei 'inventory/hosts.yml' und tragen Sie die IP-Adressen Ihrer Server ein"
echo "2. Kopieren Sie den oben angezeigten SSH Key auf Ihre Server mit:"
echo "   ssh-copy-id <benutzer>@<server-ip>"
echo "3. Führen Sie das Ansible Playbook aus:"
echo "   ansible-playbook -i inventory/hosts.yml site.yml"
echo -e "\n${YELLOW}Hinweis:${NC}"
echo "Stellen Sie sicher, dass Sie von diesem Computer aus per SSH auf alle Server zugreifen können."
echo "Sie können die Verbindung testen mit:"
echo "ssh <benutzer>@<server-ip>"