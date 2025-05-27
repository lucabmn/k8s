# ⚓ Helm Installation Skript ⚓

Dieses Verzeichnis enthält das Bash-Skript `install.sh`, das dir hilft, Helm auf deinem Kubernetes-Node zu installieren und für eine reibungslose Nutzung vorzubereiten. 🚀

## 📚 Inhaltsverzeichnis

*   [🌟 Über das Skript](#-über-das-skript)
*   [✅ Voraussetzungen](#-voraussetzungen)
*   [🛠️ Verwendung des Skripts](#-verwendung-des-skripts)
    *   [Schritt 1: Skript herunterladen ⬇️](#schritt-1-skript-herunterladen-)
    *   [Schritt 2: Skript ausführen ▶️](#schritt-2-skript-ausführen-)
    *   [Schritt 3: Autovervollständigung aktivieren ✨](#schritt-3-autovervollständigung-aktivieren-)
*   [💡 Wichtige Hinweise](#-wichtige-hinweise)
*   [❓ Fehlerbehebung](#-fehlerbehebung)

## 🌟 Über das Skript

Das `install.sh`-Skript in diesem Ordner automatisiert die Installation des Helm-CLI-Tools, dem Paketmanager für Kubernetes. Es kümmert sich um:

*   Den Download der neuesten stabilen Helm-Version. 📦
*   Das Entpacken und Verschieben von Helm in den System-Pfad (`/usr/local/bin`).
*   Die Einrichtung der Autovervollständigung (Completion) für Bash- und Zsh-Shells, damit du Helm-Befehle schneller tippen kannst.  autocomplete
*   Es ist gedacht, auf deinem **Kubernetes Master Node** ausgeführt zu werden, da du Helm normalerweise von dort aus zur Verwaltung deines Clusters nutzen wirst. 👑

## ✅ Voraussetzungen

Bevor du das Skript verwendest, stelle sicher, dass die folgenden Voraussetzungen erfüllt sind:

*   **Betriebssystem:** Debian oder Ubuntu (getestet mit aktuellen Versionen). 🐧
*   **Root-Rechte:** Das Skript muss mit Root-Rechten ausgeführt werden (z.B. `sudo bash install.sh`).
*   **Internetverbindung:** Der Node benötigt eine Internetverbindung, um Helm herunterzuladen. 🌐
*   **Helm Version:** Die standardmäßig installierte Version ist `v3.15.2`. Du kannst diese bei Bedarf direkt im Skript anpassen. ⚙️

## 🛠️ Verwendung des Skripts

Führen Sie die folgenden Schritte auf dem Node aus, auf dem Sie Helm installieren möchten (typischerweise Ihr Kubernetes Master Node).

### Schritt 1: Skript herunterladen ⬇️

Navigiere zu einem temporären Verzeichnis auf deinem Server (z.B. deinem Home-Verzeichnis) und lade das Skript direkt von deinem GitHub-Repo herunter:

```bash
mkdir -p ~/helm-setup && cd ~/helm-setup
wget https://raw.githubusercontent.com/lucabmn/IhrRepoName/main/scripts/helm/install.sh
chmod +x install.sh
```
*(Stelle sicher, dass du `IhrRepoName` durch den tatsächlichen Namen deines GitHub-Repositorys ersetzt!)*

### Schritt 2: Skript ausführen ▶️

Starte das Installationsskript mit `sudo`:

```bash
sudo bash install.sh
```

Das Skript wird nun Helm herunterladen, installieren und die Autovervollständigung vorbereiten. Folge den Anweisungen in der Ausgabe.

### Schritt 3: Autovervollständigung aktivieren ✨

Nachdem das Skript ausgeführt wurde, musst du die Autovervollständigung in deiner aktuellen Shell aktivieren. Das Skript gibt dir dazu eine Meldung aus, typischerweise:

*   Für Bash: `source ~/.bashrc`
*   Für Zsh: `source ~/.zshrc`

Führe den entsprechenden Befehl aus. Danach kannst du ein neues Terminal öffnen oder einfach den `source`-Befehl ausführen. Teste die Autovervollständigung, indem du `helm` tippst und dann die `Tab`-Taste drückst – es sollten Vorschläge erscheinen! 🎉

Um die Helm-Installation zu überprüfen:
```bash
helm version --short
```
Dies sollte die installierte Helm-Version anzeigen.

## 💡 Wichtige Hinweise

*   **Speicherort:** Helm wird standardmäßig nach `/usr/local/bin/helm` installiert. Dies ist ein gängiger Ort für ausführbare Programme im Systempfad.
*   **User-spezifisch:** Die Autovervollständigung wird in der Konfigurationsdatei deines aktuellen Benutzers (z.B. `~/.bashrc` oder `~/.zshrc`) eingerichtet. Wenn andere Benutzer Helm mit Autovervollständigung nutzen sollen, müssen sie das Skript oder die `source` -Befehle in ihrer jeweiligen Shell-Konfiguration ausführen.

## ❓ Fehlerbehebung

*   **`curl` nicht gefunden:** Das Skript versucht, `curl` zu installieren, falls es fehlt. Sollte es trotzdem zu Problemen kommen, installiere es manuell: `sudo apt update && sudo apt install -y curl`.
*   **Downloadfehler:** Überprüfe deine Internetverbindung und stelle sicher, dass die in der Variablen `HELM_VERSION` angegebene Version auf `get.helm.sh` verfügbar ist.
*   **Berechtigungsfehler:** Wenn das Skript beim Verschieben von Dateien (`mv`) auf Berechtigungsfehler stößt, stelle sicher, dass du es mit `sudo` ausgeführt hast.
*   **Autovervollständigung funktioniert nicht:** Stelle sicher, dass du den `source`-Befehl ausgeführt oder ein neues Terminal geöffnet hast. Überprüfe die `.bashrc` oder `.zshrc`-Datei, ob die Zeilen für die Helm-Completion korrekt hinzugefügt wurden.