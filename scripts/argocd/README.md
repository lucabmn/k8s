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
curl -sSL https://raw.githubusercontent.com/lucabmn/k8s/main/scripts/argocd/install.sh | sudo bash
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

Die Argo CD Web UI ist über den LoadBalancer-Service erreichbar:
* URL: https://<ARGOCD_SERVER>
* Benutzer: admin
* Passwort: (wird bei der Installation angezeigt)

## 🔧 Fehlerbehebung

* **Namespace-Fehler:** Stelle sicher, dass du die nötigen Rechte hast
* **Pod-Start-Fehler:** Prüfe die Pod-Logs mit `kubectl logs -n argocd`
* **Zugriffsfehler:** Stelle sicher, dass der LoadBalancer korrekt konfiguriert ist

## 📚 Weitere Informationen

* [Offizielle Dokumentation](https://argo-cd.readthedocs.io/)
* [GitHub Repository](https://github.com/argoproj/argo-cd) 