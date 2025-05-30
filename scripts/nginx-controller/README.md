# 🌐 NGINX Ingress Controller

Ein einfaches Skript zur Installation des NGINX Ingress Controllers in einem Kubernetes Cluster.

## 📋 Schnellstart

1. **Skript herunterladen und ausführen:**
```bash
curl -sSL https://raw.githubusercontent.com/lucabmn/k8s/main/scripts/nginx-controller/install.sh -o install.sh && chmod +x install.sh && sudo ./install.sh
```

## ⚙️ Voraussetzungen

- Laufendes Kubernetes Cluster
- Helm installiert
- Root-Rechte
- Internetverbindung

## 🔧 Installation

Das Skript:
1. Prüft ob Helm installiert ist
2. Fügt das NGINX Ingress Repository hinzu
3. Erstellt den ingress-nginx Namespace
4. Installiert den Ingress Controller mit NodePort

## 📊 Status prüfen

```bash
# Pods überprüfen
kubectl get pods -n ingress-nginx

# Services überprüfen
kubectl get svc -n ingress-nginx
```

## 🛠️ Fehlerbehebung

- **Helm nicht installiert:** 
  ```bash
  curl -sSL https://raw.githubusercontent.com/lucabmn/k8s/main/scripts/helm/install.sh | sudo bash
  ```
- **Installation fehlgeschlagen:**
  ```bash
  helm uninstall ingress-nginx --namespace ingress-nginx
  ```
  Dann Skript erneut ausführen