#!/bin/bash

# --- Variablen ---
KUBERNETES_VERSION="v1.29" # Kann bei Bedarf geändert werden
CONTAINERD_VERSION="1.7.13" # Aktuelle containerd Version, kann angepasst werden

# Default Werte
DEFAULT_HOSTNAME="k8s-master-01"
DEFAULT_NODE_ROLE="1"
DEFAULT_POD_CIDR="10.50.0.0/16"

# --- Funktionen ---

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

# --- Hauptskript Start ---

echo "=== Kubernetes Node Setup Skript ==="

# Prüfen ob Kubernetes bereits installiert ist
if check_kubernetes_installed; then
    echo "Kubernetes ist bereits installiert."
    
    # Prüfen ob Node bereits Teil eines Clusters ist
    if check_node_in_cluster; then
        echo "Dieser Node ist bereits Teil eines Clusters."
        read -p "Möchten Sie den Node aus dem Cluster entfernen und neu konfigurieren? (j/n): " RESET_CHOICE
        if [[ $RESET_CHOICE == "j" ]]; then
            echo "Entferne Node aus dem Cluster..."
            sudo kubeadm reset -f
            echo "Node wurde zurückgesetzt."
        else
            echo "Keine Änderungen vorgenommen. Beende Skript."
            exit 0
        fi
    else
        echo "Kubernetes ist installiert, aber der Node ist noch nicht Teil eines Clusters."
        read -p "Möchten Sie einem bestehenden Cluster beitreten? (j/n): " JOIN_CHOICE
        if [[ $JOIN_CHOICE == "j" ]]; then
            read -p "Bitte geben Sie den kubeadm join Befehl ein: " JOIN_COMMAND
            echo "Trete dem Cluster bei..."
            eval "sudo $JOIN_COMMAND"
            if [ $? -eq 0 ]; then
                echo "Node wurde erfolgreich dem Cluster hinzugefügt!"
                exit 0
            else
                echo "Fehler beim Beitreten des Clusters. Bitte überprüfen Sie den Befehl und versuchen Sie es erneut."
                exit 1
            fi
        fi
    fi
fi

# 1. Hostname abfragen
read -p "Geben Sie den Hostnamen für diesen Node ein [$DEFAULT_HOSTNAME]: " NODE_HOSTNAME
NODE_HOSTNAME=${NODE_HOSTNAME:-$DEFAULT_HOSTNAME}
if [ -z "$NODE_HOSTNAME" ]; then
    echo "Hostname darf nicht leer sein. Abbruch."
    exit 1
fi
sudo hostnamectl set-hostname "$NODE_HOSTNAME"
echo "Hostname auf '$NODE_HOSTNAME' gesetzt."

# 2. Rolle auswählen
echo "Wählen Sie die Rolle für diesen Node:"
echo "1) Kubernetes Master Node"
echo "2) Kubernetes Worker Node"
read -p "Geben Sie die Nummer Ihrer Wahl ein (1 oder 2) [$DEFAULT_NODE_ROLE]: " NODE_ROLE_CHOICE
NODE_ROLE_CHOICE=${NODE_ROLE_CHOICE:-$DEFAULT_NODE_ROLE}

NODE_ROLE=""
case $NODE_ROLE_CHOICE in
    1)
        NODE_ROLE="master"
        echo "Rolle: Master Node ausgewählt."
        ;;
    2)
        NODE_ROLE="worker"
        echo "Rolle: Worker Node ausgewählt."
        ;;
    *)
        echo "Ungültige Auswahl. Abbruch."
        exit 1
        ;;
esac

# 3. Pod-Netzwerk-CIDR abfragen (nur relevant für Master, aber für Consistency auf allen Nodes abfragen)
read -p "Geben Sie das Pod-Netzwerk-CIDR ein [$DEFAULT_POD_CIDR]: " POD_NETWORK_CIDR
POD_NETWORK_CIDR=${POD_NETWORK_CIDR:-$DEFAULT_POD_CIDR}
if [ -z "$POD_NETWORK_CIDR" ]; then
    echo "Pod-Netzwerk-CIDR darf nicht leer sein. Abbruch."
    exit 1
fi
echo "Pod-Netzwerk-CIDR: $POD_NETWORK_CIDR"

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
    echo "Initialisiere Kubernetes Control Plane..."
    sudo kubeadm init --pod-network-cidr="$POD_NETWORK_CIDR"

    if [ $? -ne 0 ]; then
        echo "Fehler: kubeadm init fehlgeschlagen. Überprüfen Sie die Fehlermeldungen."
        echo "Möglicherweise müssen Sie ein 'sudo kubeadm reset' ausführen, um es erneut zu versuchen."
        exit 1
    fi

    echo "Konfiguriere kubectl für den Benutzerzugriff..."
    mkdir -p "$HOME/.kube"
    sudo cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
    sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"
    echo "kubectl konfiguriert."

    echo ""
    echo "--- WICHTIG: Nächste Schritte für den Master Node ---"
    echo "1. Installieren Sie das Pod-Netzwerk-Addon (z.B. Flannel):"
    echo "   kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml"
    echo ""
    echo "2. Um Worker-Nodes hinzuzufügen, müssen Sie den 'kubeadm join'-Befehl verwenden, der Ihnen nach der Initialisierung des Masters angezeigt wurde."
    echo "   Wenn Sie ihn verloren haben, können Sie einen neuen generieren mit:"
    echo "   sudo kubeadm token create --print-join-command"
    echo "   Führen Sie diesen Befehl dann auf den Worker-Nodes aus."
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
    echo "2. Überprüfen Sie auf dem Master Node, ob dieser Worker erfolgreich beigetreten ist:"
    echo "   kubectl get nodes"
fi

echo ""
echo "=== Setup Skript abgeschlossen ==="
echo "Bitte denken Sie daran, die /etc/hosts Datei auf allen Nodes anzupassen, damit die Nodes sich über Namen erreichen können."