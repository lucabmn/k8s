# 🚀 Kubernetes Node Setup Skript 🚀

Ein einfaches Skript zur Installation und Konfiguration von Kubernetes Nodes.

## 📋 Schnellstart

1. **Skript herunterladen und ausführen:**
```bash
curl -sSL https://raw.githubusercontent.com/lucabmn/k8s/main/scripts/install.sh -o install.sh && chmod +x install.sh && sudo ./install.sh
```

2. **Master Node einrichten:**
- Führe das Skript aus
- Wähle "Master Node" als Rolle
- Notiere dir den `kubeadm join` Befehl
- Installiere das Pod-Netzwerk (z.B. Flannel):
```bash
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

3. **Worker Nodes einrichten:**
- Führe das Skript auf jedem Worker Node aus
- Wähle "Worker Node" als Rolle
- Verwende den `kubeadm join` Befehl vom Master

4. **Worker Nodes automatisch hinzufügen:**
```bash
sudo ./add-worker.sh <WORKER_IP> <USERNAME> <PASSWORD>
```

## ⚙️ Voraussetzungen

- Debian/Ubuntu System
- Root-Rechte
- Internetverbindung
- SSH-Zugriff zwischen den Nodes

## 🔧 Wichtige Konfigurationen

### /etc/hosts
Füge auf allen Nodes die IPs und Hostnamen hinzu:
```
<MASTER_IP> k8s-master-01
<WORKER_IP> k8s-worker-01
```

### Cluster Status prüfen
```bash
kubectl get nodes
kubectl get pods -A
```

## 🛠️ Fehlerbehebung

- **Node nicht erreichbar:** Prüfe Netzwerk und Firewall
- **Join fehlgeschlagen:** Token erneuern mit `kubeadm token create --print-join-command`
- **Node nicht Ready:** Pod-Netzwerk prüfen und Logs analysieren

## 🔄 Bestehende Installationen

Das Skript erkennt automatisch:
- Bereits installierte Kubernetes-Versionen
- Nodes die bereits Teil eines Clusters sind
- Bietet Optionen zum Zurücksetzen oder Beitreten