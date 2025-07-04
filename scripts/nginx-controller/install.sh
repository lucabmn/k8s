#!/bin/bash

# Farben für die Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Progress tracking
TOTAL_STEPS=5
CURRENT_STEP=0

# Funktion zum Anzeigen eines Titels
print_title() {
    echo -e "\n${BLUE}${BOLD}=== $1 ===${NC}\n"
}

# Funktion zum Anzeigen eines Schritts
print_step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    local progress=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    local bar_length=30
    local filled=$((progress * bar_length / 100))
    local empty=$((bar_length - filled))
    
    # Progress bar erstellen
    local bar="["
    for ((i=0; i<filled; i++)); do
        bar+="█"
    done
    for ((i=0; i<empty; i++)); do
        bar+="░"
    done
    bar+="]"
    
    echo -e "\n${YELLOW}${BOLD}▶ $1${NC}"
    printf "${BLUE}%s %d%% (Schritt %d/%d)${NC}\n" "$bar" "$progress" "$CURRENT_STEP" "$TOTAL_STEPS"
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

# Funktion zum Anzeigen einer Warnung
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Funktion für Benutzerauswahl mit Pfeiltasten
select_option() {
    local prompt="$1"
    local option1="$2"
    local option2="$3"
    local selected=0
    
    # Cursor ausblenden
    tput civis
    
    # Funktion zum Zeichnen des Menüs
    draw_menu() {
        echo -e "${YELLOW}$prompt${NC}"
        if [ $selected -eq 0 ]; then
            echo -e "${GREEN}${BOLD}▶ $option1${NC}"
            echo -e "  $option2"
        else
            echo -e "  $option1"
            echo -e "${GREEN}${BOLD}▶ $option2${NC}"
        fi
    }
    
    # Initiales Menü zeichnen
    draw_menu
    
    # Tastatureingaben verarbeiten
    while true; do
        read -rsn1 key
        case "$key" in
            $'\x1b')  # ESC sequence
                read -rsn2 key
                case "$key" in
                    "[A")  # Pfeil nach oben
                        selected=$((selected == 0 ? 1 : 0))
                        tput cuu1 2  # Cursor 2 Zeilen nach oben
                        draw_menu
                        ;;
                    "[B")  # Pfeil nach unten
                        selected=$((selected == 0 ? 1 : 0))
                        tput cuu1 2  # Cursor 2 Zeilen nach oben
                        draw_menu
                        ;;
                esac
                ;;
            "")  # Enter
                tput cnorm  # Cursor wieder einblenden
                return $selected
                ;;
        esac
    done
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
print_info "Dieser Schritt kann einige Minuten dauern..."
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