# Kubernetes Cluster Setup Skripts

Dieses Repository enthält ein Bash-Skript zur automatisierten Vorbereitung und Initialisierung von Kubernetes-Nodes (Master und Worker) für einen On-Premise-Cluster.

## Inhaltsverzeichnis

*   [Über dieses Repository](#über-dieses-repository)
*   [Voraussetzungen](#voraussetzungen)
*   [Struktur des Repositories](#struktur-des-repositories)
*   [Verwendung](#verwendung)
    *   [Schritt 1: Repository klonen](#schritt-1-repository-klonen)
    *   [Schritt 2: Master Node vorbereiten und initialisieren](#schritt-2-master-node-vorbereiten-und-initialisieren)
    *   [Schritt 3: Worker Nodes vorbereiten](#schritt-3-worker-nodes-vorbereiten)
    *   [Schritt 4: Worker Nodes dem Cluster hinzufügen](#schritt-4-worker-nodes-dem-cluster-hinzufügen)
    *   [Schritt 5: `/etc/hosts` Konfiguration (WICHTIG!)](#schritt-5-etchosts-konfiguration-wichtig)
    *   [Schritt 6: Cluster Status überprüfen](#schritt-6-cluster-status-überprüfen)
*   [Zusätzliche Schritte nach der Installation](#zusätzliche-schritte-nach-der-installation)
*   [Fehlerbehebung](#fehlerbehebung)
*   [Beitrag](#beitrag)
*   [Lizenz](#lizenz)

## Über dieses Repository

Dieses Repository stellt ein `install.sh`-Skript bereit, das den Prozess der Einrichtung von Kubernetes-Nodes auf Debian/Ubuntu-basierten Systemen vereinfacht. Es automatisiert die folgenden Schritte:

*   System-Updates und Installation notwendiger Pakete.
*   Deaktivierung von Swap.
*   Installation und Konfiguration von `containerd` als Container Runtime.
*   Anpassung der Sysctl-Einstellungen für Kubernetes.
*   Hinzufügen der Kubernetes-Repositories.
*   Installation und Fixierung der Versionen von `kubelet`, `kubeadm` und `kubectl`.
*   Optional: Initialisierung des Kubernetes Control Planes auf dem Master Node.

Das Skript ist interaktiv und fragt nach wichtigen Parametern wie dem Hostnamen des Nodes, seiner Rolle (Master/Worker) und dem Pod-Netzwerk-CIDR.

## Voraussetzungen

Bevor Sie das Skript verwenden, stellen Sie sicher, dass die folgenden Voraussetzungen erfüllt sind:

*   **Betriebssystem:** Debian oder Ubuntu (getestet mit aktuellen Versionen).
*   **Root-Rechte:** Das Skript muss als Root oder mit `sudo` ausgeführt werden.
*   **Mindestens 2 VMs/Server:** Ein Master Node und mindestens ein Worker Node.
*   **Netzwerk:** Alle Nodes müssen sich gegenseitig erreichen können (keine Firewall-Regeln, die die Kubernetes-Ports blockieren). Empfohlen wird ein privates Netzwerk für den Cluster.
*   **Internetverbindung:** Die Nodes benötigen eine Internetverbindung, um Pakete herunterzuladen.

## Struktur des Repositories

```
.
├── scripts/
│   └── install.sh        # Das Haupt-Setup-Skript für Kubernetes Nodes
└── README.md             # Diese README-Datei
```

## Verwendung

Befolgen Sie diese Schritte, um Ihr Kubernetes-Cluster einzurichten.

### Schritt 1: Repository klonen

Klonen Sie dieses Repository auf **jedem** Ihrer geplanten Master- und Worker-Nodes:

```bash
git clone https://github.com/IhrBenutzername/IhrRepoName.git
cd IhrRepoName
```

### Schritt 2: Master Node vorbereiten und initialisieren

Loggen Sie sich auf dem vorgesehenen Master Node (`k8s-master-01`) ein und führen Sie das Skript aus:

```bash
cd scripts/
sudo bash install.sh
```

**Während der Ausführung:**

*   **Hostname:** Geben Sie `k8s-master-01` ein.
*   **Rolle:** Wählen Sie `1` für "Kubernetes Master Node".
*   **Pod-Netzwerk-CIDR:** Geben Sie Ihr gewünschtes Pod-Netzwerk-CIDR ein (z.B. `10.244.0.0/16` für Flannel).
    **WICHTIG:** Merken Sie sich dieses CIDR, es muss auf allen Nodes identisch sein.

Nach erfolgreicher Ausführung des Skripts auf dem Master Node, wird Ihnen am Ende eine Ausgabe ähnlich der folgenden angezeigt:

```
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a Pod network to the cluster.
Run "kubectl apply -f [pod-network-filepath].yaml" with one of the options listed below:

  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

  kubeadm join <control-plane-IP>:<control-plane-port> --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

**WICHTIG:**
*   **Speichern Sie den `kubeadm join`-Befehl!** Sie benötigen ihn, um die Worker Nodes später hinzuzufügen.
*   Führen Sie die drei `mkdir`, `cp` und `chown`-Befehle aus, um `kubectl` für Ihren Benutzer zu konfigurieren.
*   Installieren Sie das Pod-Netzwerk-Addon (z.B. Flannel). Führen Sie dafür den folgenden Befehl auf dem Master Node aus:
    ```bash
    kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
    ```

### Schritt 3: Worker Nodes vorbereiten

Loggen Sie sich auf jedem Worker Node (z.B. `k8s-worker-01`, `k8s-worker-02`) ein und führen Sie das Skript aus:

```bash
cd scripts/
sudo bash install.sh
```

**Während der Ausführung:**

*   **Hostname:** Geben Sie den entsprechenden Hostnamen ein (z.B. `k8s-worker-01`, `k8s-worker-02`).
*   **Rolle:** Wählen Sie `2` für "Kubernetes Worker Node".
*   **Pod-Netzwerk-CIDR:** Geben Sie das **gleiche** CIDR ein, das Sie für den Master Node verwendet haben (z.B. `10.244.0.0/16`).

Das Skript bereitet nun die Worker Nodes vor. Am Ende wird es Sie darauf hinweisen, den `kubeadm join`-Befehl manuell auszuführen.

### Schritt 4: Worker Nodes dem Cluster hinzufügen

Gehen Sie zurück zu jedem Worker Node und führen Sie den **`kubeadm join`**-Befehl aus, den Sie zuvor vom Master Node kopiert haben (aus Schritt 2).

```bash
sudo <kubeadm join BEFEHL HIER EINFÜGEN>
# Beispiel: sudo kubeadm join 192.168.1.100:6443 --token abcdef.0123456789abcdef --discovery-token-ca-cert-hash sha256:xxxxxxxxxxxxxxxxxxxx
```

**Hinweis:** Der Join-Token hat eine begrenzte Gültigkeitsdauer (standardmäßig 24 Stunden). Wenn der Token abgelaufen ist, können Sie auf dem Master Node einen neuen generieren mit:
```bash
sudo kubeadm token create --print-join-command
```

### Schritt 5: `/etc/hosts` Konfiguration (WICHTIG!)

Damit die Nodes sich gegenseitig über ihre Hostnamen auflösen können, ist es **dringend empfohlen**, die `/etc/hosts`-Datei auf **allen Master- und Worker-Nodes** anzupassen.

Bearbeiten Sie die Datei auf jedem Node:
```bash
sudo nano /etc/hosts
```

Fügen Sie am Ende der Datei die IP-Adressen und Hostnamen **aller** Ihrer Cluster-Nodes hinzu (ersetzen Sie die Platzhalter durch Ihre tatsächlichen IPs):

```
# Beispiel für /etc/hosts Einträge für einen 3-Node-Cluster
<IP_DES_K8S_MASTER_01>   k8s-master-01
<IP_DES_K8S_WORKER_01>  k8s-worker-01
<IP_DES_K8S_WORKER_02>  k8s-worker-02
```

Speichern und schließen Sie die Datei.

### Schritt 6: Cluster Status überprüfen

Gehen Sie zum Master Node und überprüfen Sie den Status Ihres Clusters:

```bash
kubectl get nodes
```

Alle Ihre Nodes sollten den Status `Ready` anzeigen. Es kann einen Moment dauern, bis alle System-Pods gestartet sind.

```
NAME             STATUS   ROLES           AGE    VERSION
k8s-master-01    Ready    control-plane   15m    v1.29.0
k8s-worker-01    Ready    <none>          2m     v1.29.0
k8s-worker-02    Ready    <none>          1m     v1.29.0
```

Überprüfen Sie auch die System-Pods:
```bash
kubectl get pods -A
```
Alle Pods sollten den Status `Running` haben.

## Zusätzliche Schritte nach der Installation

Nachdem Ihr grundlegendes Kubernetes-Cluster läuft, sollten Sie die folgenden Schritte in Betracht ziehen:

*   **Ingress Controller:** Für den externen Zugriff auf Anwendungen (z.B. NGINX Ingress Controller).
*   **StorageClass:** Für persistente Speicherung (z.B. mit Rook-Ceph, NFS, oder einem Cloud-Provider).
*   **Monitoring:** Implementieren Sie Tools wie Prometheus und Grafana zur Überwachung des Clusters.
*   **Dashboard:** Installieren Sie das Kubernetes Dashboard für eine grafische Benutzeroberfläche.
*   **Hochverfügbarkeit (HA):** Für den Produktionseinsatz sollten Sie die Einrichtung eines HA-Control-Planes mit mehreren Master-Nodes und einem Load Balancer in Erwägung ziehen.

## Fehlerbehebung

*   **`kubeadm init` oder `kubeadm join` schlägt fehl:**
    *   Überprüfen Sie die Ausgabe des Befehls sorgfältig auf spezifische Fehlermeldungen.
    *   Stellen Sie sicher, dass Swap deaktiviert ist (`sudo swapoff -a`).
    *   Überprüfen Sie die Sysctl-Einstellungen (`sudo sysctl --system`).
    *   Stellen Sie sicher, dass `containerd` läuft (`sudo systemctl status containerd`).
    *   Wenn Sie das Skript auf einem Node erneut ausführen müssen, kann es notwendig sein, das System zurückzusetzen: `sudo kubeadm reset`.
*   **Nodes bleiben im Status `NotReady`:**
    *   Überprüfen Sie die Pods im `kube-system` Namespace auf dem Master Node: `kubectl get pods -n kube-system`.
    *   Stellen Sie sicher, dass Ihr Pod-Netzwerk-Addon (z.B. Flannel) korrekt installiert ist und seine Pods laufen.
    *   Überprüfen Sie die Logs von `kubelet` auf dem betreffenden Node: `sudo journalctl -u kubelet -f`.
    *   Stellen Sie sicher, dass die `/etc/hosts` Datei korrekt konfiguriert ist.

## Beitrag

Beiträge zu diesem Repository sind herzlich willkommen! Wenn Sie Verbesserungen oder Bugfixes haben, öffnen Sie bitte ein Issue oder erstellen Sie einen Pull Request.

## Lizenz

Dieses Projekt ist unter der [MIT Lizenz](LICENSE) lizenziert.