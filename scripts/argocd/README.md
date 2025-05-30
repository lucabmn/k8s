# 🚢 Argo CD Installation

Dieses Skript installiert Argo CD auf deinem Kubernetes-Cluster.

## 📋 Voraussetzungen

* Kubernetes Cluster
* kubectl CLI Tool
* Internetverbindung
* Root-Rechte

## ⚙️ Installation

1. Skript herunterladen und ausführen:
```bash
# Mit Standard-Port (8080)
curl -sSL https://raw.githubusercontent.com/lucabmn/k8s/main/scripts/argocd/install.sh | sudo bash

# Mit benutzerdefiniertem Port (z.B. 9090)
curl -sSL https://raw.githubusercontent.com/lucabmn/k8s/main/scripts/argocd/install.sh | sudo bash 9090
```

2. Argo CD CLI installieren:
```bash
# Für Linux
sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo chmod +x /usr/local/bin/argocd

# Für macOS
brew install argocd
```

## 🔐 Erste Schritte

1. Melde dich bei Argo CD an:
```bash
argocd login <ARGOCD_SERVER>
```

2. Ändere das Admin-Passwort:
```bash
argocd account update-password
```

## 🌐 Zugriff auf die Web UI

Die Argo CD Web UI kann auf zwei Arten erreicht werden:

### Option 1: Über LoadBalancer (falls verfügbar)
* URL: https://<ARGOCD_SERVER>
* Benutzer: admin
* Passwort: (wird bei der Installation angezeigt)

### Option 2: Über Port-Forwarding (empfohlen für lokale Entwicklung)
1. Starte Port-Forwarding in einem separaten Terminal:
```bash
# Mit Standard-Port (8080)
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Oder mit benutzerdefiniertem Port (z.B. 9090)
kubectl port-forward svc/argocd-server -n argocd 9090:443
```
2. Öffne die Web UI im Browser:
* URL: https://localhost:<PORT>
* Benutzer: admin
* Passwort: (wird bei der Installation angezeigt)

## 🔧 Fehlerbehebung

* **Namespace-Fehler:** Stelle sicher, dass du die nötigen Rechte hast
* **Pod-Start-Fehler:** Prüfe die Pod-Logs mit `kubectl logs -n argocd`
* **Zugriffsfehler:** Stelle sicher, dass der LoadBalancer korrekt konfiguriert ist
* **Port-Forwarding-Fehler:** Stelle sicher, dass der gewählte Port nicht bereits verwendet wird

## 📚 Weitere Informationen

* [Offizielle Dokumentation](https://argo-cd.readthedocs.io/)
* [GitHub Repository](https://github.com/argoproj/argo-cd) 