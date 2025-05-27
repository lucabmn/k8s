# 🌐 NGINX Ingress Controller Installation Skript 🌐

Willkommen in diesem Verzeichnis! Hier findest du das `install.sh`-Skript, das dir den Weg zum Laufen des NGINX Ingress Controllers in deinem Kubernetes-Cluster ebnet. Mach dich bereit, deinen Service-Traffic elegant zu leiten! 🚦✨

## 📚 Inhaltsverzeichnis

*   [🌟 Über das Skript](#-über-das-skript)
*   [✅ Voraussetzungen](#-voraussetzungen)
*   [📍 Server-Anforderungen (Wo ausführen?)](#-server-anforderungen-wo-ausführen)
*   [🛠️ Verwendung des Skripts](#-verwendung-des-skripts)
    *   [Schritt 1: Skript herunterladen ⬇️](#schritt-1-skript-herunterladen-)
    *   [Schritt 2: Skript ausführen ▶️](#schritt-2-skript-ausführen-)
*   [💡 Wichtige Hinweise nach der Installation](#-wichtige-hinweise-nach-der-installation)
*   [❓ Fehlerbehebung](#-fehlerbehebung)

## 🌟 Über das Skript

Das `install.sh`-Skript in diesem Ordner ist dein Helfer, um den NGINX Ingress Controller in deinem Kubernetes-Cluster zu installieren. Es nutzt Helm, um diesen essenziellen Traffic-Manager schnell und zuverlässig aufzusetzen. Das Skript kümmert sich um:

*   Die Überprüfung, ob Helm bereits installiert ist (ein Muss! 👍).
*   Das Hinzufügen des offiziellen NGINX Ingress Controller Helm-Repositories. 📦
*   Das Aktualisieren der Helm-Repositories.
*   Das Erstellen des `ingress-nginx` Namespaces, falls er noch nicht existiert.
*   Die Installation des Ingress Controllers über Helm, konfiguriert für Bare-Metal-Umgebungen mit `NodePort` Service-Typ (ideal für Proxmox). 💡

## ✅ Voraussetzungen

Bevor du dieses Skript startest, vergewissere dich, dass die folgenden Punkte erfüllt sind:

*   **Laufendes Kubernetes-Cluster:** Dein Kubernetes-Cluster (Master & Worker Nodes) sollte bereits betriebsbereit sein.
*   **Helm installiert:** Helm muss auf dem Server, auf dem du dieses Skript ausführst, installiert und konfiguriert sein. **Dieses Skript wird mit einem Fehler abbrechen, wenn Helm nicht gefunden wird!** Siehe die `README.md` im `/scripts/helm/` Ordner für die Installation von Helm. ⚓
*   **Root-Rechte:** Das Skript muss mit `sudo` ausgeführt werden.
*   **Internetverbindung:** Der Server benötigt Internetzugang, um Helm Charts herunterzuladen. 🌐

## 📍 Server-Anforderungen (Wo ausführen?)

Dieses Skript muss auf einem Server ausgeführt werden, auf dem `kubectl` für den Zugriff auf dein Cluster konfiguriert ist und **Helm installiert ist**.

Typischerweise ist das dein **Kubernetes Master Node (z.B. `k8s-master-01`)**. 👑
Es könnte auch ein separater "Operations"-Server sein, solange er die oben genannten Voraussetzungen erfüllt.

## 🛠️ Verwendung des Skripts

Folge diesen einfachen Schritten, um deinen NGINX Ingress Controller zu installieren.

### Schritt 1: Skript herunterladen ⬇️

Navigiere auf deinem vorgesehenen Server (wahrscheinlich dem Master Node) zu einem geeigneten Verzeichnis und lade das Skript herunter:

```bash
mkdir -p ~/nginx-ingress-setup && cd ~/nginx-ingress-setup
wget https://raw.githubusercontent.com/lucabmn/k8s/main/scripts/nginx-controller/install.sh
chmod +x install.sh
```
*(Stelle sicher, dass du dich in einem Verzeichnis befindest, in dem du Schreibrechte hast, z.B. in deinem Home-Verzeichnis.)*

### Schritt 2: Skript ausführen ▶️

Starte das Installationsskript mit `sudo`:

```bash
sudo bash install.sh
```

Das Skript wird nun prüfen, ob Helm vorhanden ist, das NGINX Ingress Controller Helm Repository hinzufügen, aktualisieren und den Controller in deinem Cluster bereitstellen. Es wird warten, bis die Installation abgeschlossen ist. 😊

## 💡 Wichtige Hinweise nach der Installation

*   **Status überprüfen:** Nach der Installation kannst du den Status des Ingress Controllers und seiner Pods überprüfen:
    ```bash
    kubectl get pods -n ingress-nginx
    kubectl get svc -n ingress-nginx
    ```
    Du solltest sehen, dass Pods laufen und ein `Service` vom Typ `NodePort` erstellt wurde.
*   **Zugriff auf Ingress:**
    *   Der Ingress Controller wird auf einem der NodePorts deiner Worker-Nodes zugänglich sein.
    *   Finde die zugewiesenen Ports für HTTP (Port 80) und HTTPS (Port 443) mit:
        ```bash
        kubectl get svc ingress-nginx-controller -n ingress-nginx -o custom-columns=NAME:.metadata.name,TYPE:.spec.type,CLUSTER-IP:.spec.clusterIP,EXTERNAL-IP:.status.loadBalancer.ingress[*].ip,PORTS:.spec.ports[*].nodePort,APP_PORT:.spec.ports[*].port
        ```
    *   Du kannst dann von externen Clients auf die IP-Adresse eines deiner Worker-Nodes und den entsprechenden NodePort zugreifen.
*   **Ingress-Ressourcen:** Um deine Anwendungen über den Ingress Controller erreichbar zu machen, musst du `Ingress`-Ressourcen für deine Deployments erstellen. Diese definieren, wie der Traffic zu deinen Services geroutet wird. Beispiele hierfür findest du möglicherweise im `templates`-Ordner deines Haupt-Repos oder in der offiziellen Kubernetes-Dokumentation. 📝

## ❓ Fehlerbehebung

*   **"Helm ist nicht installiert. FEHLER!" 🚨:** Das ist Absicht! Installiere zuerst Helm mit dem Skript unter `/scripts/helm/install.sh`, bevor du dieses Skript ausführst.
*   **Installation hängt oder schlägt fehl:**
    *   Überprüfe die Helm-Ausgabe im Terminal auf spezifische Fehlermeldungen.
    *   Stelle sicher, dass dein Cluster gesund ist (`kubectl get nodes`, `kubectl get pods -A`).
    *   Überprüfe die Logs der Ingress-Controller-Pods: `kubectl logs -f <POD_NAME> -n ingress-nginx`.
    *   Manchmal hilft ein `helm uninstall ingress-nginx --namespace ingress-nginx` und ein erneuter Versuch.