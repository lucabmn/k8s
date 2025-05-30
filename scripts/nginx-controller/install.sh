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

# Prüfe ob Helm installiert ist
if ! command -v helm &> /dev/null; then
    print_error "Helm ist nicht installiert"
    print_info "Bitte installieren Sie Helm zuerst:"
    print_info "curl -sSL https://raw.githubusercontent.com/lucabmn/k8s/main/scripts/helm/install.sh | sudo bash"
    exit 1
fi

print_title "NGINX Ingress Controller Installation"

# Prüfe ob bereits eine Installation existiert
print_step "Prüfe auf existierende Installation..."
if helm list -n ingress-nginx | grep -q "ingress-nginx"; then
    print_warning "Eine existierende Installation wurde gefunden"
    select_option "Möchten Sie die existierende Installation entfernen und neu installieren?" "Ja" "Nein"
    if [ $? -eq 0 ]; then
        print_step "Entferne existierende Installation..."
        helm uninstall ingress-nginx --namespace ingress-nginx
        if [ $? -ne 0 ]; then
            print_error "Konnte existierende Installation nicht entfernen"
            exit 1
        fi
        print_success "Existierende Installation wurde entfernt"
    else
        print_info "Installation abgebrochen"
        exit 0
    fi
fi

# Helm Repository hinzufügen
print_step "Füge Helm Repository hinzu..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
if [ $? -ne 0 ]; then
    print_error "Konnte Helm Repository nicht hinzufügen"
    exit 1
fi

# Helm Repositories aktualisieren
print_step "Aktualisiere Helm Repositories..."
helm repo update
if [ $? -ne 0 ]; then
    print_error "Konnte Helm Repositories nicht aktualisieren"
    exit 1
fi

# Namespace erstellen
print_step "Erstelle Namespace..."
kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -
if [ $? -ne 0 ]; then
    print_error "Konnte Namespace nicht erstellen"
    exit 1
fi

# Ingress Controller installieren
print_step "Installiere NGINX Ingress Controller..."
helm install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --set controller.service.type=NodePort \
    --set controller.service.externalTrafficPolicy=Local \
    --wait --timeout 5m

if [ $? -ne 0 ]; then
    print_error "Installation fehlgeschlagen"
    print_info "Versuche Installation zu bereinigen..."
    helm uninstall ingress-nginx --namespace ingress-nginx
    exit 1
fi

print_success "Installation erfolgreich!"
print_info "Status überprüfen mit:"
print_info "kubectl get pods -n ingress-nginx"
print_info "kubectl get svc -n ingress-nginx"