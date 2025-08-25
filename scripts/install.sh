#!/bin/bash

# --- Variablen ---
KUBERNETES_VERSION="v1.33" # Kann bei Bedarf geändert werden
CONTAINERD_VERSION="2.1.4" # Aktuelle containerd Version, kann angepasst werden

# Default Werte
CURRENT_HOSTNAME=$(hostname 2>/dev/null || echo "k8s-node")
DEFAULT_HOSTNAME="$CURRENT_HOSTNAME"
DEFAULT_NODE_ROLE="1"
DEFAULT_POD_CIDR="10.50.0.0/16"
CLUSTER_INFO_FILE="cluster-info.txt"

# Farben für die Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# --- Funktionen ---

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

# Funktion für die Pfeiltasten-Navigation
select_option() {
    local prompt="$1"
    shift
    local options=("$@")
    local selected=0
    local key

    # Verstecke Cursor
    tput civis

    while true; do
        # Lösche vorherige Ausgabe
        tput clear
        echo -e "${BLUE}${BOLD}$prompt${NC}\n"
        
        # Zeige Optionen
        for i in "${!options[@]}"; do
            if [ $i -eq $selected ]; then
                echo -e "${GREEN}${BOLD}➤ ${options[$i]}${NC}"
            else
                echo -e "  ${options[$i]}"
            fi
        done

        # Lese Tastendruck
        read -rsn1 key
        case "$key" in
            $'\x1B')  # ESC-Sequenz
                read -rsn2 key
                case "$key" in
                    "[A") # Pfeil nach oben
                        selected=$((selected - 1))
                        [ $selected -lt 0 ] && selected=$((${#options[@]} - 1))
                        ;;
                    "[B") # Pfeil nach unten
                        selected=$((selected + 1))
                        [ $selected -ge ${#options[@]} ] && selected=0
                        ;;
                esac
                ;;
            "") # Enter
                tput cnorm # Zeige Cursor wieder an
                return $selected
                ;;
        esac
    done
}

# Funktion zum gründlichen Zurücksetzen von Kubernetes
reset_kubernetes() {
    print_step "Führe gründliches Kubernetes-Reset durch..."
    
    # Stoppe alle laufenden Container
    print_info "Stoppe alle laufenden Container..."
    sudo crictl ps -a | grep -v CONTAINER | awk '{print $1}' | xargs -r sudo crictl stop
    sudo crictl ps -a | grep -v CONTAINER | awk '{print $1}' | xargs -r sudo crictl rm

    # Entferne alle Container-Images
    print_info "Entferne Container-Images..."
    sudo crictl rmi --prune

    # Stoppe und deaktiviere kubelet
    print_info "Stoppe kubelet..."
    sudo systemctl stop kubelet
    sudo systemctl disable kubelet

    # Führe kubeadm reset aus
    print_info "Führe kubeadm reset aus..."
    sudo kubeadm reset -f

    # Entferne Kubernetes-Konfigurationsdateien
    print_info "Entferne Kubernetes-Konfigurationsdateien..."
    sudo rm -rf /etc/kubernetes/
    sudo rm -rf /var/lib/kubelet/
    sudo rm -rf /var/lib/etcd/
    sudo rm -rf /var/lib/cni/
    sudo rm -rf /opt/cni/
    sudo rm -rf /var/run/kubernetes/
    sudo rm -rf ~/.kube/

    # Entferne alle iptables-Regeln
    print_info "Entferne iptables-Regeln..."
    sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X

    # Entferne alle IPVS-Regeln
    print_info "Entferne IPVS-Regeln..."
    sudo ipvsadm -C

    # Entferne alle Docker-Container und -Images (falls Docker installiert ist)
    if command -v docker &> /dev/null; then
        print_info "Entferne Docker-Container und -Images..."
        sudo docker stop $(sudo docker ps -aq) 2>/dev/null || true
        sudo docker rm $(sudo docker ps -aq) 2>/dev/null || true
        sudo docker rmi $(sudo docker images -q) 2>/dev/null || true
    fi

    print_success "Kubernetes-Reset abgeschlossen."
}

# Funktion zum Prüfen ob Kubernetes bereits installiert ist
check_kubernetes_installed() {
    if command -v kubectl &> /dev/null && command -v kubeadm &> /dev/null && command -v kubelet &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Funktion zum Prüfen ob Node bereits Teil eines Clusters ist
check_node_in_cluster() {
    if kubectl get nodes &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Funktion zum Einrichten der kubectl Konfiguration
setup_kubectl_config() {
    print_step "Richte kubectl Konfiguration ein..."
    
    # Erstelle .kube Verzeichnis
    mkdir -p "$HOME/.kube"
    if [ $? -ne 0 ]; then
        print_error "Konnte .kube Verzeichnis nicht erstellen"
        return 1
    fi

    if [ "$NODE_ROLE" == "master" ]; then
        # Prüfe ob admin.conf existiert
        if [ ! -f "/etc/kubernetes/admin.conf" ]; then
            print_error "Kubernetes admin.conf nicht gefunden"
            print_info "Bitte stellen Sie sicher, dass der Master Node korrekt initialisiert wurde"
            return 1
        fi

        # Kopiere Konfigurationsdatei
        sudo cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
        if [ $? -ne 0 ]; then
            print_error "Konnte Kubernetes Konfiguration nicht kopieren"
            return 1
        fi

        # Setze Berechtigungen
        sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"
        if [ $? -ne 0 ]; then
            print_error "Konnte Berechtigungen nicht setzen"
            return 1
        fi
    else
        # Für Worker Nodes: Frage nach Master Node IP
        read -p "Bitte geben Sie die IP-Adresse des Master Nodes ein: " MASTER_IP
        if [ -z "$MASTER_IP" ]; then
            print_error "IP-Adresse darf nicht leer sein"
            return 1
        fi

        # Erstelle temporäre Konfiguration
        cat > "$HOME/.kube/config" << EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: https://${MASTER_IP}:6443
    insecure-skip-tls-verify: true
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
users:
- name: kubernetes-admin
  user:
    client-certificate-data: ""
    client-key-data: ""
EOF

        print_info "Temporäre kubectl Konfiguration erstellt"
        print_warning "Hinweis: Für volle Funktionalität müssen Sie die Konfigurationsdatei vom Master Node kopieren"
        print_info "Sie können dies mit folgendem Befehl auf dem Master Node tun:"
        print_info "scp /etc/kubernetes/admin.conf root@${MASTER_IP}:~/.kube/config"
    fi

    # Teste die Konfiguration
    if kubectl get nodes &> /dev/null; then
        print_success "kubectl Konfiguration erfolgreich eingerichtet"
        return 0
    else
        print_warning "kubectl Konfiguration konnte nicht verifiziert werden"
        if [ "$NODE_ROLE" == "worker" ]; then
            print_info "Dies ist normal für Worker Nodes. Führen Sie kubectl Befehle auf dem Master Node aus."
        else
            print_info "Bitte überprüfen Sie die Berechtigungen und die Konfigurationsdatei"
        fi
        return 1
    fi
}

# Funktion zum Prüfen und Installieren von curl
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

# Funktion zum Speichern der Cluster-Informationen
save_cluster_info() {
    local join_command="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "=== Kubernetes Cluster Informationen ===" > "$CLUSTER_INFO_FILE"
    echo "Erstellt am: $timestamp" >> "$CLUSTER_INFO_FILE"
    echo "" >> "$CLUSTER_INFO_FILE"
    
    echo "=== Master Node Informationen ===" >> "$CLUSTER_INFO_FILE"
    echo "Hostname: $(hostname)" >> "$CLUSTER_INFO_FILE"
    echo "IP-Adresse: $(hostname -I | awk '{print $1}')" >> "$CLUSTER_INFO_FILE"
    echo "Pod-Netzwerk-CIDR: $POD_NETWORK_CIDR" >> "$CLUSTER_INFO_FILE"
    echo "" >> "$CLUSTER_INFO_FILE"
    
    echo "=== Worker Node Beitrittsbefehl ===" >> "$CLUSTER_INFO_FILE"
    echo "$join_command" >> "$CLUSTER_INFO_FILE"
    echo "" >> "$CLUSTER_INFO_FILE"
    
    echo "=== Wichtige Befehle ===" >> "$CLUSTER_INFO_FILE"
    echo "1. Pod-Netzwerk-Addon installieren (z.B. Flannel):" >> "$CLUSTER_INFO_FILE"
    echo "   kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml" >> "$CLUSTER_INFO_FILE"
    echo "" >> "$CLUSTER_INFO_FILE"
    
    echo "2. Cluster-Status überprüfen:" >> "$CLUSTER_INFO_FILE"
    echo "   kubectl get nodes" >> "$CLUSTER_INFO_FILE"
    echo "   kubectl get pods -A" >> "$CLUSTER_INFO_FILE"
    echo "" >> "$CLUSTER_INFO_FILE"
    
    echo "3. Neuen Join-Token generieren (falls der alte abgelaufen ist):" >> "$CLUSTER_INFO_FILE"
    echo "   sudo kubeadm token create --print-join-command" >> "$CLUSTER_INFO_FILE"
    echo "" >> "$CLUSTER_INFO_FILE"
    
    echo "=== /etc/hosts Konfiguration ===" >> "$CLUSTER_INFO_FILE"
    echo "Fügen Sie folgende Zeilen in /etc/hosts auf allen Nodes ein:" >> "$CLUSTER_INFO_FILE"
    echo "$(hostname -I | awk '{print $1}') $(hostname)" >> "$CLUSTER_INFO_FILE"
    echo "" >> "$CLUSTER_INFO_FILE"
    
    echo "=== Wichtige Hinweise ===" >> "$CLUSTER_INFO_FILE"
    echo "1. Speichern Sie diese Datei sicher auf!" >> "$CLUSTER_INFO_FILE"
    echo "2. Der Join-Token ist 24 Stunden gültig" >> "$CLUSTER_INFO_FILE"
    echo "3. Konfigurieren Sie die /etc/hosts auf allen Nodes" >> "$CLUSTER_INFO_FILE"
    echo "4. Installieren Sie das Pod-Netzwerk-Addon auf dem Master Node" >> "$CLUSTER_INFO_FILE"
    
    # Setze Berechtigungen
    chmod 600 "$CLUSTER_INFO_FILE"
    
    echo "Cluster-Informationen wurden in $CLUSTER_INFO_FILE gespeichert."
}

# Funktion zum Vorbereiten des Worker Nodes für kubectl
prepare_worker_kubectl() {
    local worker_ip="$1"
    print_step "Bereite Worker Node für kubectl Konfiguration vor..."
    
    # Erstelle .kube Verzeichnis auf dem Worker Node
    ssh "root@${worker_ip}" "mkdir -p ~/.kube"
    if [ $? -ne 0 ]; then
        print_error "Konnte .kube Verzeichnis auf Worker Node nicht erstellen"
        return 1
    fi
    
    # Kopiere die Konfigurationsdatei
    scp /etc/kubernetes/admin.conf "root@${worker_ip}:~/.kube/config"
    if [ $? -ne 0 ]; then
        print_error "Konnte Konfigurationsdatei nicht kopieren"
        return 1
    fi
    
    # Setze Berechtigungen
    ssh "root@${worker_ip}" "chown $(id -u):$(id -g) ~/.kube/config"
    if [ $? -ne 0 ]; then
        print_error "Konnte Berechtigungen nicht setzen"
        return 1
    fi
    
    print_success "Worker Node wurde für kubectl vorbereitet"
    return 0
}

# Funktion zum Anzeigen der Konfiguration und Bestätigung
show_config_and_confirm() {
    print_title "Kubernetes Node Konfiguration"
    print_info "Bitte überprüfen Sie die folgenden Einstellungen:"
    echo ""
    echo "Hostname: $NODE_HOSTNAME"
    echo "IP-Adresse: $(hostname -I | awk '{print $1}')"
    echo "Rolle: $([ "$NODE_ROLE" == "master" ] && echo "Master Node" || echo "Worker Node")"
    echo "Pod-Netzwerk-CIDR: $POD_NETWORK_CIDR"
    echo ""
    
    select_option "Sind diese Einstellungen korrekt?" "Ja, Installation starten" "Nein, Einstellungen ändern"
    if [ $? -eq 1 ]; then
        print_info "Bitte geben Sie die Einstellungen erneut ein."
        return 1
    fi
    return 0
}

# --- Hauptskript Start ---

print_title "Kubernetes Node Setup Skript"
print_info "Dieses Skript hilft Ihnen bei der Einrichtung eines Kubernetes-Nodes."
print_info "Es führt Sie Schritt für Schritt durch den Prozess."

# Prüfen ob Kubernetes bereits installiert ist
if check_kubernetes_installed; then
    print_warning "Kubernetes ist bereits installiert."
    
    # Prüfen ob Node bereits Teil eines Clusters ist
    if check_node_in_cluster; then
        print_warning "Dieser Node ist bereits Teil eines Clusters."
        select_option "Möchten Sie den Node aus dem Cluster entfernen und neu konfigurieren?" "Ja" "Nein"
        if [ $? -eq 0 ]; then
            print_step "Entferne Node aus dem Cluster..."
            reset_kubernetes
            print_success "Node wurde zurückgesetzt."
        else
            print_info "Keine Änderungen vorgenommen. Beende Skript."
            exit 0
        fi
    else
        print_warning "Kubernetes ist installiert, aber der Node ist noch nicht Teil eines Clusters."
        select_option "Möchten Sie einem bestehenden Cluster beitreten?" "Ja" "Nein"
        if [ $? -eq 0 ]; then
            read -p "Bitte geben Sie den kubeadm join Befehl ein: " JOIN_COMMAND
            print_step "Trete dem Cluster bei..."
            eval "sudo $JOIN_COMMAND"
            if [ $? -eq 0 ]; then
                print_success "Node wurde erfolgreich dem Cluster hinzugefügt!"
                if ! setup_kubectl_config; then
                    print_warning "kubectl Konfiguration konnte nicht eingerichtet werden."
                    print_info "Bitte kopieren Sie die Konfigurationsdatei manuell vom Master Node."
                fi
                exit 0
            else
                print_error "Fehler beim Beitreten des Clusters. Bitte überprüfen Sie den Befehl und versuchen Sie es erneut."
                exit 1
            fi
        fi
    fi
fi

# 1. Hostname abfragen
print_step "Hostname konfigurieren"
read -p "Geben Sie den Hostnamen für diesen Node ein [$DEFAULT_HOSTNAME]: " NODE_HOSTNAME
NODE_HOSTNAME=${NODE_HOSTNAME:-$DEFAULT_HOSTNAME}
if [ -z "$NODE_HOSTNAME" ]; then
    print_error "Hostname darf nicht leer sein. Abbruch."
    exit 1
fi
sudo hostnamectl set-hostname "$NODE_HOSTNAME"
print_success "Hostname auf '$NODE_HOSTNAME' gesetzt."

# 2. Rolle auswählen
print_step "Node-Rolle auswählen"
select_option "Wählen Sie die Rolle für diesen Node:" "Kubernetes Master Node" "Kubernetes Worker Node"
NODE_ROLE_CHOICE=$?

NODE_ROLE=""
case $NODE_ROLE_CHOICE in
    0)
        NODE_ROLE="master"
        print_success "Rolle: Master Node ausgewählt."
        ;;
    1)
        NODE_ROLE="worker"
        print_success "Rolle: Worker Node ausgewählt."
        ;;
esac

# 3. Pod-Netzwerk-CIDR abfragen
print_step "Pod-Netzwerk konfigurieren"
read -p "Geben Sie das Pod-Netzwerk-CIDR ein [$DEFAULT_POD_CIDR]: " POD_NETWORK_CIDR
POD_NETWORK_CIDR=${POD_NETWORK_CIDR:-$DEFAULT_POD_CIDR}
if [ -z "$POD_NETWORK_CIDR" ]; then
    print_error "Pod-Netzwerk-CIDR darf nicht leer sein. Abbruch."
    exit 1
fi
print_success "Pod-Netzwerk-CIDR: $POD_NETWORK_CIDR"

# Zeige Konfiguration und frage nach Bestätigung
while ! show_config_and_confirm; do
    # 1. Hostname abfragen
    print_step "Hostname konfigurieren"
    read -p "Geben Sie den Hostnamen für diesen Node ein [$DEFAULT_HOSTNAME]: " NODE_HOSTNAME
    NODE_HOSTNAME=${NODE_HOSTNAME:-$DEFAULT_HOSTNAME}
    if [ -z "$NODE_HOSTNAME" ]; then
        print_error "Hostname darf nicht leer sein. Abbruch."
        exit 1
    fi
    sudo hostnamectl set-hostname "$NODE_HOSTNAME"
    print_success "Hostname auf '$NODE_HOSTNAME' gesetzt."

    # 2. Rolle auswählen
    print_step "Node-Rolle auswählen"
    select_option "Wählen Sie die Rolle für diesen Node:" "Kubernetes Master Node" "Kubernetes Worker Node"
    NODE_ROLE_CHOICE=$?

    NODE_ROLE=""
    case $NODE_ROLE_CHOICE in
        0)
            NODE_ROLE="master"
            print_success "Rolle: Master Node ausgewählt."
            ;;
        1)
            NODE_ROLE="worker"
            print_success "Rolle: Worker Node ausgewählt."
            ;;
    esac

    # 3. Pod-Netzwerk-CIDR abfragen
    print_step "Pod-Netzwerk konfigurieren"
    read -p "Geben Sie das Pod-Netzwerk-CIDR ein [$DEFAULT_POD_CIDR]: " POD_NETWORK_CIDR
    POD_NETWORK_CIDR=${POD_NETWORK_CIDR:-$DEFAULT_POD_CIDR}
    if [ -z "$POD_NETWORK_CIDR" ]; then
        print_error "Pod-Netzwerk-CIDR darf nicht leer sein. Abbruch."
        exit 1
    fi
    print_success "Pod-Netzwerk-CIDR: $POD_NETWORK_CIDR"
done

echo ""
echo "--- System-Vorbereitung ---"

# Sicherstellen, dass curl vorhanden ist
install_curl_if_missing

# 1. OS Update & Pakete installieren
echo "1. System aktualisieren und notwendige Pakete installieren..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y apt-transport-https ca-certificates software-properties-common curl git wget
if [ $? -ne 0 ]; then
    echo "Fehler bei der Installation grundlegender Pakete. Abbruch."
    exit 1
fi
echo "Pakete installiert."

# 2. Swap deaktivieren
echo "2. Swap deaktivieren..."
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
echo "Swap deaktiviert."

# 3. Container Runtime installieren (containerd)
echo "3. containerd installieren und konfigurieren..."

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update

# Install containerd mit spezifischer Version
sudo apt install -y containerd.io
if [ $? -ne 0 ]; then
    echo "Fehler bei der Installation von containerd. Abbruch."
    exit 1
fi

# Configure containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
echo "containerd installiert und konfiguriert."

# 4. Sysctl-Einstellungen anpassen (für Kubernetes)
echo "4. Sysctl-Einstellungen anpassen..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
echo "Sysctl-Einstellungen angewendet."

# 5. Kubernetes Repositories hinzufügen
echo "5. Kubernetes Repository hinzufügen..."
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
echo "Kubernetes Repository hinzugefügt."

# 6. kubelet, kubeadm, kubectl installieren
echo "6. kubelet, kubeadm, kubectl installieren..."
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
if [ $? -ne 0 ]; then
    echo "Fehler bei der Installation von Kubernetes-Komponenten. Abbruch."
    exit 1
fi
echo "Kubernetes-Komponenten installiert und auf Hold gesetzt."

echo ""

# --- Master Node spezifische Konfiguration ---
if [ "$NODE_ROLE" == "master" ]; then
    echo "--- Master Node Konfiguration ---"
    
    # Prüfe ob Ports bereits in Verwendung sind
    if netstat -tuln | grep -q ":6443\|:10259\|:10257\|:10250\|:2379\|:2380"; then
        echo "Warnung: Einige benötigte Ports sind bereits in Verwendung."
        read -p "Möchten Sie Kubernetes zurücksetzen und neu initialisieren? (j/n): " RESET_CHOICE
        if [[ $RESET_CHOICE == "j" ]]; then
            reset_kubernetes
        else
            echo "Abbruch: Ports sind belegt. Bitte beenden Sie die blockierenden Prozesse manuell."
            exit 1
        fi
    fi

    echo "Initialisiere Kubernetes Control Plane..."
    sudo kubeadm init --pod-network-cidr="$POD_NETWORK_CIDR"

    if [ $? -ne 0 ]; then
        echo "Fehler: kubeadm init fehlgeschlagen. Überprüfen Sie die Fehlermeldungen."
        echo "Möglicherweise müssen Sie ein 'sudo kubeadm reset' ausführen, um es erneut zu versuchen."
        exit 1
    fi

    # Richte kubectl Konfiguration ein
    if ! setup_kubectl_config; then
        echo "Fehler: kubectl Konfiguration konnte nicht eingerichtet werden."
        exit 1
    fi

    # Generiere den Join-Befehl und speichere die Cluster-Informationen
    JOIN_COMMAND=$(sudo kubeadm token create --print-join-command)
    save_cluster_info "$JOIN_COMMAND"

    echo ""
    echo "--- WICHTIG: Nächste Schritte für den Master Node ---"
    echo "1. Installieren Sie das Pod-Netzwerk-Addon (z.B. Flannel):"
    echo "   kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml"
    echo ""
    echo "2. Alle wichtigen Informationen wurden in $CLUSTER_INFO_FILE gespeichert."
    echo "   Bitte bewahren Sie diese Datei sicher auf!"
    echo ""
    echo "3. Überprüfen Sie den Status Ihres Clusters:"
    echo "   kubectl get nodes"

elif [ "$NODE_ROLE" == "worker" ]; then
    echo "--- Worker Node Konfiguration ---"
    echo "Dieser Node ist nun vorbereitet, um dem Kubernetes Cluster beizutreten."
    echo ""
    echo "--- WICHTIG: Nächste Schritte für den Worker Node ---"
    echo "1. Führen Sie auf diesem Worker Node den 'kubeadm join'-Befehl aus, den Sie vom Master Node erhalten haben."
    echo "   Beispiel (ersetzen Sie die Platzhalter):"
    echo "   sudo kubeadm join <MASTER_IP>:<MASTER_PORT> --token <YOUR_TOKEN> --discovery-token-ca-cert-hash sha256:<YOUR_HASH>"
    echo ""
    echo "2. Nach dem Beitreten:"
    echo "   - Erstellen Sie das .kube Verzeichnis:"
    echo "     mkdir -p ~/.kube"
    echo "   - Kopieren Sie die Konfigurationsdatei vom Master Node:"
    echo "     scp root@<MASTER_IP>:/etc/kubernetes/admin.conf ~/.kube/config"
    echo "   - Setzen Sie die korrekten Berechtigungen:"
    echo "     chown \$(id -u):\$(id -g) ~/.kube/config"
    echo "   - Oder verwenden Sie die temporäre Konfiguration, die das Skript erstellt hat"
    echo ""
    echo "3. Überprüfen Sie auf dem Master Node, ob dieser Worker erfolgreich beigetreten ist:"
    echo "   kubectl get nodes"
fi

echo ""
echo "=== Setup Skript abgeschlossen ==="
echo "Bitte denken Sie daran, die /etc/hosts Datei auf allen Nodes anzupassen, damit die Nodes sich über Namen erreichen können."
