#!/bin/bash

# Farben für die Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Funktion zum Anzeigen eines Titels
print_title() {
    echo -e "\n${BLUE}${BOLD}=== $1 ===${NC}\n"
}

# Funktion zum Anzeigen eines Schritts
print_step() {
    echo -e "\n${YELLOW}${BOLD}▶ $1${NC}"
}

# Funktion zum Anzeigen einer Erfolgsmeldung
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Funktion zum Anzeigen einer Warnung
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Funktion zum Anzeigen eines Fehlers
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Funktion zum Anzeigen einer Info
print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Prüfe ob das Skript als root ausgeführt wird
if [ "$EUID" -ne 0 ]; then
    print_error "Dieses Skript muss als root ausgeführt werden"
    exit 1
fi

# Prüfe ob die erforderlichen Parameter übergeben wurden
if [ "$#" -lt 3 ]; then
    print_error "Verwendung: $0 <WORKER_IP> <USERNAME> <PASSWORD>"
    print_info "Beispiel: $0 192.168.178.51 root meinpasswort"
    exit 1
fi

WORKER_IP="$1"
USERNAME="$2"
PASSWORD="$3"

print_title "Worker Node zum Cluster hinzufügen"
print_info "Worker IP: $WORKER_IP"
print_info "Benutzer: $USERNAME"

# Prüfe ob der Worker Node erreichbar ist
print_step "Prüfe Verbindung zum Worker Node..."
if ! ping -c 1 "$WORKER_IP" &> /dev/null; then
    print_error "Worker Node ist nicht erreichbar"
    exit 1
fi
print_success "Worker Node ist erreichbar"

# Installiere sshpass falls nicht vorhanden
if ! command -v sshpass &> /dev/null; then
    print_step "Installiere sshpass..."
    apt-get update && apt-get install -y sshpass
    if [ $? -ne 0 ]; then
        print_error "Konnte sshpass nicht installieren"
        exit 1
    fi
fi

# Generiere den Join-Befehl
print_step "Generiere Join-Befehl..."
JOIN_COMMAND=$(kubeadm token create --print-join-command)
if [ $? -ne 0 ]; then
    print_error "Konnte Join-Befehl nicht generieren"
    exit 1
fi

# Erstelle .kube Verzeichnis auf dem Worker Node
print_step "Erstelle .kube Verzeichnis auf dem Worker Node..."
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$WORKER_IP" "mkdir -p ~/.kube"
if [ $? -ne 0 ]; then
    print_error "Konnte .kube Verzeichnis nicht erstellen"
    exit 1
fi

# Kopiere die Konfigurationsdatei
print_step "Kopiere Kubernetes Konfiguration..."
sshpass -p "$PASSWORD" scp -o StrictHostKeyChecking=no /etc/kubernetes/admin.conf "$USERNAME@$WORKER_IP:~/.kube/config"
if [ $? -ne 0 ]; then
    print_error "Konnte Konfigurationsdatei nicht kopieren"
    exit 1
fi

# Setze Berechtigungen
print_step "Setze Berechtigungen..."
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$WORKER_IP" "chown $(id -u):$(id -g) ~/.kube/config"
if [ $? -ne 0 ]; then
    print_error "Konnte Berechtigungen nicht setzen"
    exit 1
fi

# Führe den Join-Befehl auf dem Worker Node aus
print_step "Führe Join-Befehl auf dem Worker Node aus..."
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USERNAME@$WORKER_IP" "sudo $JOIN_COMMAND"
if [ $? -ne 0 ]; then
    print_error "Worker Node konnte nicht zum Cluster hinzugefügt werden"
    exit 1
fi

# Warte kurz und prüfe den Status
print_step "Prüfe Cluster-Status..."
sleep 10
if kubectl get nodes | grep -q "$WORKER_IP"; then
    print_success "Worker Node wurde erfolgreich zum Cluster hinzugefügt!"
    print_info "Cluster-Status:"
    kubectl get nodes
else
    print_warning "Worker Node wurde hinzugefügt, aber noch nicht im Cluster sichtbar"
    print_info "Bitte warten Sie einen Moment und prüfen Sie den Status mit: kubectl get nodes"
fi

print_title "Fertig!"
print_info "Der Worker Node wurde zum Cluster hinzugefügt"
print_info "Sie können den Status jederzeit mit 'kubectl get nodes' überprüfen" 