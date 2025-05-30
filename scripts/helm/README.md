# 🚢 Helm Installation

Dieses Skript installiert Helm auf deinem Kubernetes-Node.

## 📋 Voraussetzungen

* Debian oder Ubuntu
* Root-Rechte
* Internetverbindung

## ⚙️ Installation

1. Skript herunterladen und ausführen:
```bash
curl -sSL https://raw.githubusercontent.com/lucabmn/k8s/main/scripts/helm/install.sh | sudo bash
```

2. Autovervollständigung aktivieren:
* Für Bash: `source ~/.bashrc`
* Für Zsh: `source ~/.zshrc`

## ✅ Überprüfung

Teste die Installation mit:
```bash
helm version --short
```

## 🔧 Fehlerbehebung

* **Downloadfehler:** Internetverbindung prüfen
* **Berechtigungsfehler:** Skript mit `sudo` ausführen
* **Autovervollständigung:** Nach der Installation neues Terminal öffnen oder `source`-Befehl ausführen