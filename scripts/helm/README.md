# 🚢 Helm Installation

Dieses Skript installiert Helm auf deinem Kubernetes-Node.

## 🎯 Wo ausführen?

**Helm sollte auf allen Nodes installiert werden, auf denen du Kubernetes-Befehle ausführen möchtest:**

- **Master Node:** Für Cluster-Management und Deployment von Anwendungen
- **Worker Nodes:** Falls du direkt von den Worker Nodes aus mit dem Cluster interagieren möchtest
- **Client Machine:** Auf deinem lokalen Entwicklungsrechner für Remote-Zugriff auf den Cluster

**Hinweis:** Helm ist ein Client-Tool und muss nicht auf jedem Node im Cluster laufen. Es reicht aus, es auf den Maschinen zu installieren, von denen aus du Helm-Befehle ausführen möchtest.

## 📋 Voraussetzungen

- Debian oder Ubuntu
- Root-Rechte
- Internetverbindung

## ⚙️ Installation

1. Skript herunterladen und ausführen:

```bash
curl -sSL https://raw.githubusercontent.com/lucabmn/k8s/main/scripts/helm/install.sh | sudo bash
```

2. Autovervollständigung aktivieren:

- Für Bash: `source ~/.bashrc`
- Für Zsh: `source ~/.zshrc`

## ✅ Überprüfung

Teste die Installation mit:

```bash
helm version --short
```

## 🔧 Fehlerbehebung

- **Downloadfehler:** Internetverbindung prüfen
- **Berechtigungsfehler:** Skript mit `sudo` ausführen
- **Autovervollständigung:** Nach der Installation neues Terminal öffnen oder `source`-Befehl ausführen
