# Kubernetes Cluster Setup mit Ansible

Dieses Projekt automatisiert die Installation und Konfiguration eines Kubernetes Clusters mit folgenden Komponenten:
- Kubernetes (v1.29)
- Helm (v3)
- NGINX Ingress Controller
- ArgoCD

## 🚀 Schnellstart

1. **Repository klonen:**
   ```bash
   git clone <repository-url>
   cd ansible
   ```

2. **Setup-Skript ausführen:**
   ```bash
   sudo ./setup.sh
   ```
   Dieses Skript installiert automatisch alle benötigten Voraussetzungen:
   - Python3
   - Ansible
   - SSH Server
   - SSH Keys

3. **Server-Konfiguration:**
   - Öffnen Sie die Datei `inventory/hosts.yml`
   - Tragen Sie die IP-Adressen Ihrer Server ein:
     ```yaml
     master:
       hosts:
         master1:
           ansible_host: 192.168.1.10  # Ihre Master-IP hier eintragen
           ansible_user: ubuntu        # Ihr SSH-Benutzer
     worker:
       hosts:
         worker1:
           ansible_host: 192.168.1.11  # Ihre Worker1-IP hier eintragen
           ansible_user: ubuntu        # Ihr SSH-Benutzer
         worker2:
           ansible_host: 192.168.1.12  # Ihre Worker2-IP hier eintragen
           ansible_user: ubuntu        # Ihr SSH-Benutzer
     ```

4. **SSH-Zugriff einrichten:**
   ```bash
   # SSH-Key auf alle Server kopieren
   ssh-copy-id ubuntu@192.168.1.10  # Master
   ssh-copy-id ubuntu@192.168.1.11  # Worker1
   ssh-copy-id ubuntu@192.168.1.12  # Worker2
   ```

5. **Kubernetes Cluster installieren:**
   ```bash
   ansible-playbook -i inventory/hosts.yml site.yml
   ```

## 📋 Systemanforderungen

### Master Node:
- 2 CPU Kerne
- 2 GB RAM
- 20 GB Festplattenspeicher
- Ubuntu 20.04 LTS oder neuer

### Worker Nodes:
- 2 CPU Kerne
- 2 GB RAM
- 20 GB Festplattenspeicher
- Ubuntu 20.04 LTS oder neuer

## 🔍 Was wird installiert?

1. **Kubernetes Cluster:**
   - kubeadm, kubelet, kubectl
   - Container Runtime (containerd)
   - Pod Network (Calico)

2. **Helm:**
   - Helm v3 Package Manager
   - Stable Repository

3. **NGINX Ingress Controller:**
   - Installiert im `ingress-nginx` Namespace
   - LoadBalancer Service

4. **ArgoCD:**
   - GitOps Tool für Kubernetes
   - Installiert im `argocd` Namespace
   - LoadBalancer Service

## ✅ Nach der Installation

1. **Cluster-Status prüfen:**
   ```bash
   # Auf dem Master Node ausführen
   kubectl get nodes
   ```

2. **ArgoCD Passwort abrufen:**
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```

3. **ArgoCD UI aufrufen:**
   ```bash
   # IP-Adresse des LoadBalancers anzeigen
   kubectl -n argocd get svc argocd-server
   ```
   - Öffnen Sie die angezeigte IP-Adresse im Browser
   - Login mit:
     - Benutzer: admin
     - Passwort: (aus Schritt 2)

## 🔧 Fehlerbehebung

### Häufige Probleme:

1. **SSH-Verbindung fehlgeschlagen:**
   ```bash
   # SSH-Key erneut kopieren
   ssh-copy-id <benutzer>@<server-ip>
   ```

2. **Ansible Playbook fehlgeschlagen:**
   ```bash
   # Ansible im Debug-Modus ausführen
   ansible-playbook -i inventory/hosts.yml site.yml -vvv
   ```

3. **Kubernetes Node nicht bereit:**
   ```bash
   # Node-Status prüfen
   kubectl describe node <node-name>
   ```

## 📚 Nützliche Befehle

```bash
# Cluster-Status
kubectl get nodes
kubectl get pods --all-namespaces

# ArgoCD Status
kubectl get pods -n argocd
kubectl get svc -n argocd

# NGINX Ingress Status
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

## 🔒 Sicherheitshinweise

- Ändern Sie das Standard-ArgoCD-Passwort nach der Installation
- Konfigurieren Sie Firewall-Regeln für Ihre Server
- Halten Sie alle Komponenten regelmäßig aktuell
- Sichern Sie Ihre Kubernetes-Konfiguration regelmäßig

## 📞 Support

Bei Problemen:
1. Prüfen Sie die Fehlerbehebung
2. Schauen Sie in die Ansible-Logs
3. Erstellen Sie ein Issue im Repository 