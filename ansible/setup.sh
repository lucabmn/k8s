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

echo -e "${YELLOW}=== Kubernetes Cluster Setup - Voraussetzungen Installation ===${NC}"

# Prüfen, ob wir Root-Rechte haben
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Bitte führen Sie dieses Skript mit sudo aus:${NC}"
    echo "sudo $0"
    exit 1
fi

# Betriebssystem erkennen
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
else
    echo -e "${RED}Betriebssystem konnte nicht erkannt werden${NC}"
    exit 1
fi

echo -e "${YELLOW}Betriebssystem erkannt: $OS${NC}"

# Python3 installieren
echo -e "\n${YELLOW}Installiere Python3...${NC}"
if [ "$OS" = "Ubuntu" ] || [ "$OS" = "Debian GNU/Linux" ]; then
    apt update
    apt install -y python3 python3-pip
elif [ "$OS" = "CentOS Linux" ] || [ "$OS" = "Red Hat Enterprise Linux" ]; then
    yum install -y python3 python3-pip
else
    echo -e "${RED}Nicht unterstütztes Betriebssystem${NC}"
    exit 1
fi
check_command "Python3 Installation"

# Ansible installieren
echo -e "\n${YELLOW}Installiere Ansible...${NC}"
if [ "$OS" = "Ubuntu" ] || [ "$OS" = "Debian GNU/Linux" ]; then
    apt install -y software-properties-common
    apt-add-repository --yes --update ppa:ansible/ansible
    apt install -y ansible
elif [ "$OS" = "CentOS Linux" ] || [ "$OS" = "Red Hat Enterprise Linux" ]; then
    yum install -y epel-release
    yum install -y ansible
fi
check_command "Ansible Installation"

# SSH Server installieren
echo -e "\n${YELLOW}Installiere SSH Server...${NC}"
if [ "$OS" = "Ubuntu" ] || [ "$OS" = "Debian GNU/Linux" ]; then
    apt install -y openssh-server
elif [ "$OS" = "CentOS Linux" ] || [ "$OS" = "Red Hat Enterprise Linux" ]; then
    yum install -y openssh-server
fi
check_command "SSH Server Installation"

# SSH Service starten und aktivieren
systemctl enable sshd
systemctl start sshd
check_command "SSH Service Start"

# SSH Key generieren, falls noch nicht vorhanden
if [ ! -f ~/.ssh/id_rsa ]; then
    echo -e "\n${YELLOW}Generiere SSH Key...${NC}"
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    check_command "SSH Key Generierung"
fi

echo -e "\n${GREEN}=== Installation abgeschlossen! ===${NC}"
echo -e "\n${YELLOW}Nächste Schritte:${NC}"
echo "1. Bearbeiten Sie die Datei 'inventory/hosts.yml' und tragen Sie die IP-Adressen Ihrer Server ein"
echo "2. Führen Sie das Ansible Playbook aus:"
echo "   ansible-playbook -i inventory/hosts.yml site.yml"
echo -e "\n${YELLOW}Hinweis:${NC}"
echo "Stellen Sie sicher, dass Sie von diesem Computer aus per SSH auf alle Server zugreifen können."
echo "Sie können die Verbindung testen mit:"
echo "ssh <benutzer>@<server-ip>" 