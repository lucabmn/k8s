Okay, hier ist eine separate `README.md` speziell für den `scripts/` Unterordner, die sich nur auf das `install.sh` Skript und dessen Verwendung konzentriert, inklusive eines `wget`-Befehls zum Herunterladen.

---

# Kubernetes Node Setup Skript

Dieses Verzeichnis enthält das Bash-Skript `install.sh`, das zur automatisierten Vorbereitung und Initialisierung von Kubernetes-Nodes (Master und Worker) für einen On-Premise-Cluster dient.

## Inhaltsverzeichnis

*   [Über das Skript](#über-das-skript)
*   [Voraussetzungen](#voraussetzungen)
*   [Verwendung des Skripts](#verwendung-des-skripts)
    *   [Schritt 1: Skript herunterladen](#schritt-1-skript-herunterladen)
    *   [Schritt 2: Master Node vorbereiten und initialisieren](#schritt-2-master-node-vorbereiten-und-initialisieren)
    *   [Schritt 3: Worker Nodes vorbereiten](#schritt-3-worker-nodes-vorbereiten)
    *   [Schritt 4: Worker Nodes dem Cluster hinzufügen](#schritt-4-worker-nodes-dem-cluster-hinzufügen)
    *   [Schritt 5: `/etc/hosts` Konfiguration (WICHTIG!)](#schritt-5-etchosts-konfiguration-wichtig)
    *   [Schritt 6: Cluster Status überprüfen](#schritt-6-cluster-status-überprüfen)
*   [Wichtige Hinweise](#wichtige-hinweise)
*   [Fehlerbehebung](#fehlerbehebung)

## Über das Skript

Das `install.sh`-Skript automatisiert die initialen Konfigurationsschritte, um einen Server als Kubernetes-Node vorzubereiten. Es kümmert sich um:

*   System-Updates und Installation notwendiger Pakete (`curl`, `apt-transport-https` etc.).
*   Deaktivierung von Swap.
*   Installation und Konfiguration von `containerd` als Container Runtime.
*   Anpassung der Sysctl-Einstellungen (`br_netfilter`, `overlay`).
*   Hinzufügen der offiziellen Kubernetes-Repositories.
*   Installation und Versionen-Pinning von `kubelet`, `kubeadm` und `kubectl`.
*   Auf Master-Nodes: Initialisierung des Kubernetes Control Planes.

Das Skript ist interaktiv und fragt nach dem Hostnamen des Nodes, seiner Rolle (Master/Worker) und dem gewünschten Pod-Netzwerk-CIDR.

## Voraussetzungen

*   **Betriebssystem:** Debian oder Ubuntu (getestet mit aktuellen Versionen).
*   **Root-Rechte:** Das Skript muss mit Root-Rechten ausgeführt werden (z.B. `sudo bash install.sh`).
*   **Internetverbindung:** Der Node benötigt eine Internetverbindung, um Pakete und Container-Images herunterzuladen.
*   **Netzwerkplanung:** Kennen Sie das Pod-Netzwerk-CIDR, das Sie für Ihr Cluster verwenden möchten (z.B. `10.244.0.0/16` für Flannel). Dieses muss auf allen Nodes konsistent sein.

## Verwendung des Skripts

Führen Sie die folgenden Schritte auf **jedem Ihrer Kubernetes-Nodes (Master und Worker)** aus.

### Schritt 1: Skript herunterladen

Verwenden Sie `wget`, um das Skript direkt herunterzuladen:

```bash
mkdir -p ~/k8s-setup && cd ~/k8s-setup
wget https://raw.githubusercontent.com/lucabmn/k8s/main/scripts/install.sh
chmod +x install.sh
```
*(Ersetzen Sie `IhrBenutzername` und `IhrRepoName` durch die tatsächlichen Werte Ihres GitHub-Repositorys.)*

### Schritt 2: Master Node vorbereiten und initialisieren

Loggen Sie sich auf dem vorgesehenen Master Node (z.B. `k8s-master-01`) ein und starten Sie das Skript:

```bash
sudo bash install.sh
```

**Während der Ausführung:**

*   **Hostname:** Geben Sie den Hostnamen für Ihren Master Node ein (z.B. `k8s-master-01`).
*   **Rolle:** Wählen Sie `1` für "Kubernetes Master Node".
*   **Pod-Netzwerk-CIDR:** Geben Sie Ihr gewünschtes Pod-Netzwerk-CIDR ein (z.B. `10.244.0.0/16`). **Notieren Sie sich dieses CIDR**, da es auf allen Worker Nodes identisch sein muss.

Nachdem das Skript auf dem Master Node abgeschlossen ist, wird Ihnen eine wichtige Ausgabe angezeigt.
**Beachten Sie insbesondere:**

*   **Der `kubeadm join`-Befehl:** Dieser Befehl wird verwendet, um Worker Nodes zum Cluster hinzuzufügen. Kopieren Sie ihn und speichern Sie ihn sicher.
*   **Die Anweisungen zur `kubectl`-Konfiguration:** Führen Sie die drei `mkdir`, `cp`, und `chown`-Befehle aus, um `kubectl` für Ihren normalen Benutzer zugänglich zu machen.
*   **Installation des Pod-Netzwerk-Addons:** Führen Sie den Befehl zum Installieren des Pod-Netzwerk-Addons (z.B. Flannel) auf dem **Master Node** aus. Beispiel für Flannel:
    ```bash
    kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
    ```

### Schritt 3: Worker Nodes vorbereiten

Loggen Sie sich auf jedem Worker Node (z.B. `k8s-worker-01`, `k8s-worker-02`) ein, wechseln Sie in das Verzeichnis mit dem Skript und starten Sie es:

```bash
cd ~/k8s-setup # Oder das Verzeichnis, in das Sie das Skript heruntergeladen haben
sudo bash install.sh
```

**Während der Ausführung:**

*   **Hostname:** Geben Sie den entsprechenden Hostnamen für den Worker Node ein (z.B. `k8s-worker-01` oder `k8s-worker-02`).
*   **Rolle:** Wählen Sie `2` für "Kubernetes Worker Node".
*   **Pod-Netzwerk-CIDR:** Geben Sie das **gleiche** Pod-Netzwerk-CIDR ein, das Sie für den Master Node verwendet haben (z.B. `10.244.0.0/16`).

Das Skript bereitet nun den Worker Node vor. Am Ende wird es Sie darauf hinweisen, den `kubeadm join`-Befehl manuell auszuführen.

### Schritt 4: Worker Nodes dem Cluster hinzufügen

Führen Sie auf **jedem Worker Node** den `kubeadm join`-Befehl aus, den Sie aus der Ausgabe der Master-Node-Initialisierung kopiert haben.

```bash
sudo <IHREN KUBEADM JOIN BEFEHL HIER EINFÜGEN>
# Beispiel: sudo kubeadm join 192.168.1.100:6443 --token abcdef.0123456789abcdef --discovery-token-ca-cert-hash sha256:xxxxxxxxxxxxxxxxxxxx
```

### Schritt 5: `/etc/hosts` Konfiguration (WICHTIG!)

Damit die Nodes sich gegenseitig über ihre Hostnamen auflösen können, ist es **dringend empfohlen**, die `/etc/hosts`-Datei auf **allen Master- und Worker-Nodes** anzupassen. Dies ist für die interne Kommunikation und die Stabilität des Clusters wichtig.

Bearbeiten Sie die Datei auf jedem Node:
```bash
sudo nano /etc/hosts
```

Fügen Sie am Ende der Datei die IP-Adressen und Hostnamen **aller** Ihrer Cluster-Nodes hinzu (ersetzen Sie die Platzhalter durch Ihre tatsächlichen IPs):

```
# Beispiel für /etc/hosts Einträge
<IP_DES_K8S_MASTER_01>   k8s-master-01
<IP_DES_K8S_WORKER_01>  k8s-worker-01
<IP_DES_K8S_WORKER_02>  k8s-worker-02
```

Speichern und schließen Sie die Datei.

### Schritt 6: Cluster Status überprüfen

Sobald alle Worker Nodes beigetreten sind, gehen Sie zum Master Node und überprüfen Sie den Status Ihres Clusters:

```bash
kubectl get nodes
kubectl get pods -A
```
Alle Ihre Nodes sollten den Status `Ready` und alle wichtigen System-Pods den Status `Running` anzeigen.

## Wichtige Hinweise

*   **Versions-Pinning:** Das Skript installiert Kubernetes-Komponenten und pinnt deren Versionen, um unbeabsichtigte Upgrades zu verhindern. Die Standardversion ist `v1.29`, kann aber im Skript angepasst werden.
*   **Join-Token:** Der `kubeadm join`-Token, der vom Master generiert wird, ist standardmäßig nur 24 Stunden gültig. Falls er abläuft, können Sie auf dem Master einen neuen erzeugen mit: `sudo kubeadm token create --print-join-command`.

## Fehlerbehebung

*   **Skript bricht ab:** Lesen Sie die Fehlermeldungen sorgfältig. Oft fehlen Voraussetzungen oder Pakete konnten nicht installiert werden.
*   **`kubeadm init` / `kubeadm join` Fehler:**
    *   Stellen Sie sicher, dass Swap deaktiviert ist (`sudo swapoff -a`).
    *   Überprüfen Sie, ob `containerd` läuft und korrekt konfiguriert ist (`sudo systemctl status containerd`).
    *   Überprüfen Sie die Sysctl-Einstellungen (`sudo sysctl --system`).
    *   Wenn ein Node in einem inkonsistenten Zustand ist, kann `sudo kubeadm reset` helfen, ihn zurückzusetzen, bevor Sie das Skript erneut ausführen.
*   **Nodes `NotReady`:**
    *   Überprüfen Sie die Pods im `kube-system` Namespace auf dem Master (`kubectl get pods -n kube-system`).
    *   Vergewissern Sie sich, dass Ihr Pod-Netzwerk-Addon (z.B. Flannel) richtig installiert ist und seine Pods laufen.
    *   Schauen Sie in die Logs von `kubelet` auf dem betreffenden Node: `sudo journalctl -u kubelet -f`.
    *   Prüfen Sie Ihre Firewall-Einstellungen (wenn vorhanden) und die `/etc/hosts` Konfiguration.

---