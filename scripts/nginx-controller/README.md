# 🌐 NGINX Ingress Controller Installation

Dieses Skript installiert den NGINX Ingress Controller in deinem Kubernetes Cluster.

## 🚀 Schnellstart

```bash
curl -sSL https://raw.githubusercontent.com/lucabmn/k8s/main/scripts/nginx-controller/install.sh -o install.sh
chmod +x install.sh
sudo ./install.sh
```

## 📋 Voraussetzungen

- Kubernetes Cluster
- Helm (v3.x)
- Root-Rechte
- Internetverbindung

## 🛠️ Installation

Das Skript führt folgende Schritte aus:

1. Prüft auf existierende Installation
2. Fügt das Helm Repository hinzu
3. Aktualisiert die Helm Repositories
4. Erstellt den benötigten Namespace
5. Installiert den NGINX Ingress Controller

## ✅ Überprüfung

Nach der Installation kannst du den Status überprüfen mit:

```bash
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

## ⚠️ Hinweise

- Der Ingress Controller wird als NodePort Service installiert
- Die Installation kann einige Minuten dauern
- Bei einer existierenden Installation wird gefragt, ob diese entfernt werden soll

## 🔧 Fehlerbehebung

Falls die Installation fehlschlägt:
1. Prüfe die Logs: `kubectl logs -n ingress-nginx`
2. Stelle sicher, dass Helm korrekt installiert ist
3. Überprüfe die Netzwerkverbindung