# 🚀 Kubernetes Node Setup Skript 🚀

Willkommen im `scripts/` Verzeichnis! 🎉 Hier findest du unser magisches `install.sh`-Skript, das dir hilft, deine Kubernetes-Nodes super einfach vorzubereiten und zu initialisieren. Schluss mit stundenlangem manuellem Tippen! 💻✨

## 📚 Inhaltsverzeichnis

*   [🌟 Über das Skript](#-über-das-skript)
*   [✅ Voraussetzungen](#-voraussetzungen)
*   [🛠️ Verwendung des Skripts](#-verwendung-des-skripts)
    *   [Schritt 1: Skript herunterladen ⬇️](#schritt-1-skript-herunterladen-)
    *   [Schritt 2: Master Node vorbereiten und initialisieren 👑](#schritt-2-master-node-vorbereiten-und-initialisieren-)
    *   [Schritt 3: Worker Nodes vorbereiten 👷](#schritt-3-worker-nodes-vorbereiten-)
    *   [Schritt 4: Worker Nodes dem Cluster hinzufügen 🤝](#schritt-4-worker-nodes-dem-cluster-hinzufügen-)
    *   [Schritt 5: `/etc/hosts` Konfiguration (WICHTIG!) 🗺️](#schritt-5-etchosts-konfiguration-wichtig-)
    *   [Schritt 6: Cluster Status überprüfen 👀](#schritt-6-cluster-status-überprüfen-)
*   [💡 Wichtige Hinweise](#-wichtige-hinweise)
*   [❓ Fehlerbehebung](#-fehlerbehebung)

## 🌟 Über das Skript

Das `install.sh`-Skript ist dein persönlicher Assistent für die Kubernetes-Node-Einrichtung auf Debian/Ubuntu-Systemen! Es nimmt dir eine Menge Arbeit ab und kümmert sich um:

*   System-Updates und die Installation aller benötigten Pakete. 📦
*   Das Deaktivieren von Swap (ganz wichtig für K8s!). 🚫
*   Die Installation und Konfiguration von `containerd` als deine Container Runtime. 🐳
*   Anpassungen an den Sysctl-Einstellungen für eine reibungslose Netzwerkkommunikation. 🌐
*   Das Hinzufügen der offiziellen Kubernetes-Repositories. 🔗
*   Die Installation von `kubelet`, `kubeadm` und `kubectl` – und pinnt deren Versionen, damit nichts versehentlich kaputt geht. 🔒
*   Auf Master-Nodes: Die Initialisierung deiner Kubernetes Control Plane. 🎉

Das Beste daran? Das Skript ist interaktiv! Es fragt dich nach wichtigen Details wie dem Hostnamen deines Nodes, seiner Rolle (Master oder Worker) und dem Pod-Netzwerk-CIDR. So bleibt alles flexibel und auf deine Bedürfnisse zugeschnitten. 💬

## ✅ Voraussetzungen

Bevor du loslegst, sorge bitte dafür, dass die folgenden Punkte erfüllt sind:

*   **Betriebssystem:** Debian oder Ubuntu (auf aktuellen Versionen getestet – je neuer, desto besser!). 🐧
*   **Root-Rechte:** Du musst das Skript mit Root-Rechten ausführen (z.B. `sudo bash install.sh`). Denk dran: Große Power, große Verantwortung! 😉
*   **Internetverbindung:** Dein Node braucht Zugang zum Internet, um alle nötigen Pakete und Container-Images herunterzuladen. 🚀
*   **Netzwerkplanung:** Überlege dir vorher, welches Pod-Netzwerk-CIDR du für dein Cluster verwenden möchtest (z.B. `10.244.0.0/16` für Flannel). Dieses muss auf **allen** Nodes gleich sein! 🤝

## 🛠️ Verwendung des Skripts

Folge diesen Schritten auf **jedem** deiner zukünftigen Kubernetes-Nodes (egal ob Master oder Worker), um sie startklar zu machen.

### Schritt 1: Skript herunterladen ⬇️

Zuerst holst du dir das Skript auf deinen Server. Erstelle ein Verzeichnis und lade es direkt per `wget` herunter:

```bash
mkdir -p ~/k8s-setup && cd ~/k8s-setup
wget https://raw.githubusercontent.com/lucabmn/k8s/refs/heads/main/scripts/install.sh
chmod +x install.sh
```
### Schritt 2: Master Node vorbereiten und initialisieren 👑

Melde dich auf deinem vorgesehenen Master Node (z.B. `k8s-master-01`) an und starte das Skript:

```bash
sudo bash install.sh
```

**Wenn das Skript dich fragt:**

*   **Hostname:** Gib den coolen Hostnamen für deinen Master Node ein (z.B. `k8s-master-01`).
*   **Rolle:** Wähle `1` für "Kubernetes Master Node". Deine Krone wartet! 👑
*   **Pod-Netzwerk-CIDR:** Gib dein gewähltes Pod-Netzwerk-CIDR ein (z.B. `10.244.0.0/16`). **Ganz wichtig: Merk dir dieses CIDR gut!** Es muss auf allen Worker Nodes genau dasselbe sein. 📝

Nachdem das Skript auf dem Master Node seine Arbeit beendet hat, siehst du eine **sehr wichtige** Ausgabe.
**Nimm dir einen Moment Zeit und beachte besonders:**

*   **Der `kubeadm join`-Befehl:** Das ist der Zauberspruch, mit dem deine Worker Nodes später beitreten. Kopiere ihn und bewahre ihn sicher auf! ✨
*   **Die `kubectl`-Konfiguration:** Führe die drei `mkdir`, `cp`, und `chown`-Befehle aus, damit du `kubectl` als normaler Benutzer nutzen kannst.
*   **Installation des Pod-Netzwerk-Addons:** Das ist entscheidend für die Kommunikation deiner Pods. Führe den Befehl zum Installieren des Pod-Netzwerk-Addons (z.B. Flannel) auf dem **Master Node** aus. Beispiel für Flannel:
    ```bash
    kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
    ```

### Schritt 3: Worker Nodes vorbereiten 👷

Melde dich auf jedem deiner Worker Nodes (z.B. `k8s-worker-01`, `k8s-worker-02`) an. Gehe in das Verzeichnis, in das du das Skript heruntergeladen hast, und starte es:

```bash
cd ~/k8s-setup # Oder dein Download-Verzeichnis
sudo bash install.sh
```

**Wenn das Skript dich fragt:**

*   **Hostname:** Gib den passenden Hostnamen für deinen Worker Node ein (z.B. `k8s-worker-01` oder `k8s-worker-02`).
*   **Rolle:** Wähle `2` für "Kubernetes Worker Node". Lass uns arbeiten! 👷
*   **Pod-Netzwerk-CIDR:** Gib das **genau gleiche** Pod-Netzwerk-CIDR ein, das du für den Master Node verwendet hast (z.B. `10.244.0.0/16`). Konsistenz ist der Schlüssel! 🔑

Das Skript wird nun den Worker Node fleißig vorbereiten. Am Ende wird es dich daran erinnern, den `kubeadm join`-Befehl auszuführen.

### Schritt 4: Worker Nodes dem Cluster hinzufügen 🤝

Gehe zurück zu jedem Worker Node und führe den `kubeadm join`-Befehl aus, den du aus der Master-Node-Initialisierung kopiert hast. Denk daran: Das ist der Moment, in dem sie dem Team beitreten!

```bash
sudo <IHREN KUBEADM JOIN BEFEHL HIER EINFÜGEN>
# Beispiel: sudo kubeadm join 192.168.1.100:6443 --token abcdef.0123456789abcdef --discovery-token-ca-cert-hash sha256:xxxxxxxxxxxxxxxxxxxx
```

### Schritt 5: `/etc/hosts` Konfiguration (WICHTIG!) 🗺️

Damit deine Nodes sich gegenseitig mit ihren Namen verstehen und nicht nur mit schwer zu merkenden IPs, ist es **UNBEDINGT EMPFOHLEN**, die `/etc/hosts`-Datei auf **allen** Master- und Worker-Nodes anzupassen. Das ist super wichtig für eine stabile Kommunikation im Cluster! 🗣️

Bearbeite die Datei auf jedem Node:
```bash
sudo nano /etc/hosts
```

Füge am Ende der Datei die IP-Adressen und Hostnamen **aller** deiner Cluster-Nodes hinzu (ersetze die Platzhalter mit deinen tatsächlichen IPs):

```
# Beispiel für /etc/hosts Einträge
# So wissen deine Nodes, wer wer ist! 😉
<IP_DES_K8S_MASTER_01>   k8s-master-01
<IP_DES_K8S_WORKER_01>  k8s-worker-01
<IP_DES_K8S_WORKER_02>  k8s-worker-02
```

Speichern und schließen Sie die Datei.

### Schritt 6: Cluster Status überprüfen 👀

Sobald alle Worker Nodes beigetreten sind, gehe zurück zum Master Node. Es ist Zeit, deine brandneue Kubernetes-Umgebung zu bewundern! ✨

```bash
kubectl get nodes
kubectl get pods -A
```
Alle deine Nodes sollten stolz den Status `Ready` anzeigen, und alle wichtigen System-Pods sollten fröhlich `Running` sein. Herzlichen Glückwunsch, dein Cluster ist live! 🎉🥳

## 💡 Wichtige Hinweise

*   **Versions-Pinning:** Das Skript ist schlau! Es installiert Kubernetes-Komponenten und "pinnt" deren Versionen. Das verhindert, dass unerwartete Updates dein Cluster durcheinanderbringen. Die Standardversion ist `v1.29`, aber du kannst sie im Skript anpassen, wenn du möchtest. 📏
*   **Join-Token:** Der `kubeadm join`-Token, den der Master generiert, ist aus Sicherheitsgründen nur 24 Stunden gültig. Falls er abläuft, keine Panik! Du kannst auf dem Master ganz einfach einen neuen erstellen: `sudo kubeadm token create --print-join-command`. 👍

## ❓ Fehlerbehebung

Manchmal läuft nicht alles perfekt – das ist normal! Hier sind ein paar Tipps, wenn du auf Probleme stößt:

*   **Skript bricht ab:** Lies die Fehlermeldungen genau! Oft sind es fehlende Voraussetzungen oder Probleme beim Download von Paketen.
*   **`kubeadm init` / `kubeadm join` schlagen fehl:**
    *   Hast du wirklich Swap deaktiviert? Überprüfe mit `sudo swapoff -a`. 🚫
    *   Läuft `containerd` ordnungsgemäß und ist es korrekt konfiguriert? (`sudo systemctl status containerd`). 🐳
    *   Sind die Sysctl-Einstellungen korrekt angewendet? (`sudo sysctl --system`).
    *   Wenn ein Node in einem seltsamen Zustand ist und du neu anfangen möchtest, kann `sudo kubeadm reset` helfen, ihn komplett zurückzusetzen.
*   **Nodes bleiben im Status `NotReady`:**
    *   Schau dir die Pods im `kube-system` Namespace auf dem Master an: `kubectl get pods -n kube-system`.
    *   Ist dein Pod-Netzwerk-Addon (wie Flannel) richtig installiert und laufen seine Pods? 🤔
    *   Wirf einen Blick in die Logs von `kubelet` auf dem betreffenden Node: `sudo journalctl -u kubelet -f`.
    *   Überprüfe deine Firewall-Regeln (falls vorhanden) und stelle sicher, dass die `/etc/hosts`-Datei auf allen Nodes perfekt ist. 🔥