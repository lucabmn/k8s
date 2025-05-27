# 🚀 Kubernetes Cluster Resource Repository 🚀

Willkommen in deinem zentralen Ort für alles, was du zum Aufbau und zur Verwaltung deines Kubernetes-Clusters brauchst! 🎉 Dieses Repository ist dazu gedacht, dir den Einstieg in die On-Premise-Kubernetes-Welt so einfach und effizient wie möglich zu machen.

## 📚 Inhaltsverzeichnis

*   [🌟 Über dieses Repository](#-über-dieses-repository)
*   [📂 Repository-Struktur](#-repository-struktur)
*   [✅ Voraussetzungen](#-voraussetzungen)
*   [🛠️ Schnellstart: Cluster aufbauen](#-schnellstart-cluster-aufbauen)
*   [💡 Wichtige Hinweise & Empfehlungen](#-wichtige-hinweise--empfehlungen)
*   [❓ Fehlerbehebung](#-fehlerbehebung)
*   [🤝 Beitrag](#-beitrag)
*   [📜 Lizenz](#-lizenz)

## 🌟 Über dieses Repository

Dieses Repository ist deine Go-To-Quelle für Skripte, Vorlagen und Anleitungen, die den Prozess der Bereitstellung und Konfiguration deines Kubernetes-Clusters vereinfachen. Ob du einen Master Node initialisierst, Worker Nodes hinzufügst oder grundlegende Komponenten einrichtest – hier findest du die nötigen Ressourcen.

Unser Ziel ist es, dir eine klare, wiederholbare und automatisierte Methode für dein Kubernetes-Setup zu bieten. Lass uns gemeinsam die Container-Welt erobern! 🐳✨

## 📂 Repository-Struktur

Um dir die Orientierung zu erleichtern, ist das Repository in logische Ordner unterteilt:

*   **`./scripts/`**: ⚙️ Hier findest du alle ausführbaren Bash-Skripte. Diese Skripte automatisieren Aufgaben wie die Node-Vorbereitung, Installation von Komponenten oder spezifische Konfigurationen.
    *   **Beispiel:** `install.sh` für die Basis-Installation jedes Nodes.
*   **`./templates/`**: 📝 Dieser Ordner beherbergt YAML-Manifeste und andere Vorlagen. Sie dienen als Blaupausen für Kubernetes-Objekte (Pods, Deployments, Services) oder Konfigurationsdateien, die du an deine spezifischen Bedürfnisse anpassen kannst.
    *   **Beispiel:** Basis-Manifeste für Flannel, NGINX Ingress Controller oder einfache Beispielanwendungen.
*   **`./docs/`**: 📖 Hier liegen ausführliche Anleitungen und How-Tos. Diese Dokumente führen dich durch komplexere Themen oder spezifische Workflows, die über die reinen Skripte hinausgehen.
    *   **Beispiel:** Schritt-für-Schritt-Anleitungen für die Installation von Monitoring-Tools, Storage-Lösungen oder die Einrichtung eines HA-Control-Planes.
*   **`README.md`** (diese Datei): Deine Starthilfe und Übersicht über das gesamte Repository.

## ✅ Voraussetzungen

Bevor du mit dem Setup deines Clusters beginnst, stelle sicher, dass die folgenden grundlegenden Voraussetzungen erfüllt sind:

*   **Mindestens 2 VMs/Server:** Ein Master Node und mindestens ein Worker Node sind das absolute Minimum für ein funktionsfähiges Cluster. 🖥️🖥️
*   **Betriebssystem:** Alle Server sollten Debian- oder Ubuntu-basiert sein (getestet mit aktuellen LTS-Versionen). 🐧
*   **Root-Zugriff:** Für die Ausführung der Skripte benötigst du Root-Rechte oder `sudo`-Berechtigungen auf allen Servern.
*   **Netzwerkkonnektivität:** Alle Nodes müssen sich gegenseitig erreichen können, ohne dass Firewalls kritische Kubernetes-Ports blockieren. Eine dedizierte Netzwerkkarte/VLAN für den Cluster wird empfohlen. 🌐
*   **Internetverbindung:** Alle Nodes benötigen Internetzugang, um Pakete und Container-Images herunterzuladen. 🚀

## 🛠️ Schnellstart: Cluster aufbauen

Folge dieser allgemeinen Abfolge, um dein Kubernetes-Cluster mit den Skripten in diesem Repo aufzubauen. Detailliertere Anweisungen findest du in den jeweiligen Unterordner-READMEs und in `/docs`.

1.  **Repository klonen:**
    Klonen Sie dieses Repository auf **jedem** Ihrer geplanten Master- und Worker-Nodes:
    ```bash
    git clone https://github.com/lucabmn/k8s.git
    cd IhrRepoName
    ```
    
2.  **Master Node vorbereiten & initialisieren:** 👑
    *   Wechsle in das `scripts`-Verzeichnis: `cd scripts/`
    *   Führe das `install.sh`-Skript aus: `sudo bash install.sh`
    *   Wähle die Rolle `Master Node` und gib deinen Hostnamen und das Pod-Netzwerk-CIDR an (z.B. `10.244.0.0/16`).
    *   **WICHTIG:** Speichere den `kubeadm join`-Befehl, der am Ende der Master-Initialisierung ausgegeben wird! Und installiere das Pod-Netzwerk-Addon (siehe Anleitung des Skripts).

3.  **Worker Nodes vorbereiten:** 👷
    *   Gehe auf jedem Worker Node in das `scripts`-Verzeichnis: `cd scripts/`
    *   Führe das `install.sh`-Skript aus: `sudo bash install.sh`
    *   Wähle die Rolle `Worker Node` und gib den jeweiligen Hostnamen an. **Verwende das GLEICHE Pod-Netzwerk-CIDR wie auf dem Master!**

4.  **Worker Nodes dem Cluster hinzufügen:** 🤝
    *   Führe auf **jedem Worker Node** den `kubeadm join`-Befehl aus, den du zuvor vom Master kopiert hast.

5.  **`/etc/hosts` Konfiguration (WICHTIG!)** 🗺️
    *   Passe die `/etc/hosts`-Datei auf **allen** Master- und Worker-Nodes an, um die Hostnamen und IPs aller Cluster-Mitglieder einzutragen. Dies stellt sicher, dass sich die Nodes korrekt auflösen können. Ein Beispiel findest du in der `/scripts/README.md`.

6.  **Cluster Status überprüfen:** 👀
    *   Gehe zum Master Node und überprüfe den Status deines neuen Clusters:
        ```bash
        kubectl get nodes
        kubectl get pods -A
        ```
        Alle Nodes sollten den Status `Ready` anzeigen, und alle System-Pods sollten `Running` sein. Herzlichen Glückwunsch! 🥳

## 💡 Wichtige Hinweise & Empfehlungen

*   **Dokumentation ist dein Freund:** Für detailliertere Anleitungen zu spezifischen Themen (z.B. Ingress, Storage, Monitoring) schau dir die Dokumente im `/docs/` Ordner an! 📖
*   **Versionierung:** Achte auf die Kubernetes-Versionen, die im Skript festgelegt sind. Halte sie aktuell, aber weiche nicht zu stark von den gängigen Versionen ab, es sei denn, du weißt genau, was du tust. 📏
*   **Sicherheit:** Dies ist ein Basis-Setup. Für den Produktionseinsatz solltest du zusätzliche Sicherheitsmaßnahmen in Betracht ziehen (z.B. Firewall-Regeln, RBAC, Harden der Nodes). 🔐

## ❓ Fehlerbehebung

Manchmal läuft nicht alles wie am Schnürchen. Kein Problem! Hier sind ein paar allgemeine Tipps zur Fehlerbehebung:

*   **Log-Dateien:** Die Logs sind deine besten Freunde! Überprüfe die Ausgaben des Skripts und die Logs von `kubelet` (`sudo journalctl -u kubelet -f`) oder `containerd` (`sudo journalctl -u containerd -f`).
*   **Reset:** Wenn ein Node nicht richtig will, kann `sudo kubeadm reset` oft helfen, ihn in einen sauberen Zustand zurückzusetzen, bevor du das Skript erneut ausführst.
*   **Community:** Die Kubernetes-Community ist riesig! Such nach deinem Fehler online, oft haben andere das Problem schon gelöst. 🌐💬

## 🤝 Beitrag

Wir freuen uns über jeden Beitrag! Wenn du Ideen für Verbesserungen hast, Fehler findest oder neue Skripte/Vorlagen hinzufügen möchtest, zögere nicht, ein Issue zu öffnen oder einen Pull Request einzureichen. Lass uns dieses Repo gemeinsam besser machen! 💪

## 📜 Lizenz

Dieses Projekt ist unter der [MIT Lizenz](LICENSE) lizenziert. Du kannst es gerne nutzen und anpassen!