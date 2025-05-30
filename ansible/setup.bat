@echo off
setlocal enabledelayedexpansion

echo ===== Kubernetes Cluster Setup - Voraussetzungen Installation =====
echo.

:: Prüfen, ob wir Administrator-Rechte haben
echo Prüfe Administrator-Rechte...
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo FEHLER: Bitte führen Sie dieses Skript als Administrator aus
    echo Rechtsklick auf die Datei und "Als Administrator ausführen" wählen
    pause
    exit /b 1
)
echo Administrator-Rechte OK
echo.

:: Zeige System-Informationen
echo System-Informationen:
echo -------------------
echo Aktuelles Verzeichnis:
cd
echo Benutzerprofil: %USERPROFILE%
echo Benutzername: %USERNAME%
echo.

:: Python3 Installation prüfen
echo Prüfe Python3 Installation...
python --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo FEHLER: Python3 ist nicht installiert
    echo Bitte installieren Sie Python3 von https://www.python.org/downloads/
    echo Stellen Sie sicher, dass Sie die Option "Add Python to PATH" während der Installation aktivieren.
    pause
    exit /b 1
)
echo Python3 ist installiert
echo.

:: Ansible Installation prüfen
echo Prüfe Ansible Installation...
where ansible >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Prüfe pipx Installation...
    where pipx >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        echo Prüfe Ansible in pipx...
        pipx list | findstr ansible >nul
        if %ERRORLEVEL% EQU 0 (
            echo Ansible ist mit pipx installiert
            echo Füge pipx PATH hinzu...
            for /f "tokens=*" %%i in ('pipx environment --value PIPX_LOCAL_VENVS') do set "PIPX_VENV_PATH=%%i"
            for /f "tokens=*" %%i in ('pipx environment --value PIPX_BIN_DIR') do set "PIPX_BIN_PATH=%%i"
            set "PATH=%PIPX_BIN_PATH%;%PATH%"
        ) else (
            echo FEHLER: Ansible ist nicht mit pipx installiert
            echo Bitte installieren Sie Ansible mit pipx:
            echo pipx install ansible
            pause
            exit /b 1
        )
    ) else (
        echo FEHLER: Ansible ist nicht installiert
        echo Bitte installieren Sie Ansible mit pip:
        echo pip install ansible
        pause
        exit /b 1
    )
) else (
    echo Ansible ist installiert
)
echo.

:: OpenSSH Installation prüfen
echo Prüfe OpenSSH Installation...
where ssh >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo FEHLER: OpenSSH ist nicht installiert
    echo Bitte installieren Sie OpenSSH über Windows Features:
    echo 1. Windows Features öffnen
    echo 2. "OpenSSH Client" und "OpenSSH Server" aktivieren
    pause
    exit /b 1
)
echo OpenSSH ist installiert
echo.

:: SSH Key Setup
echo Richte SSH Keys ein...
echo.

:: .ssh Verzeichnis erstellen falls nicht vorhanden
echo Prüfe .ssh Verzeichnis...
if not exist "%USERPROFILE%\.ssh" (
    echo Erstelle .ssh Verzeichnis in %USERPROFILE%\.ssh
    mkdir "%USERPROFILE%\.ssh"
    if %ERRORLEVEL% EQU 0 (
        echo .ssh Verzeichnis erstellt
    ) else (
        echo FEHLER: Konnte .ssh Verzeichnis nicht erstellen
        pause
        exit /b 1
    )
) else (
    echo .ssh Verzeichnis existiert bereits
)
echo.

:: SSH Key generieren, falls noch nicht vorhanden
echo Prüfe SSH Keys...
if not exist "%USERPROFILE%\.ssh\id_rsa" (
    echo Generiere neuen SSH Key...
    ssh-keygen -t rsa -b 4096 -f "%USERPROFILE%\.ssh\id_rsa" -N ""
    if %ERRORLEVEL% EQU 0 (
        echo SSH Key erfolgreich generiert
        echo Überprüfe generierte Dateien:
        dir "%USERPROFILE%\.ssh\id_rsa*"
    ) else (
        echo FEHLER: SSH Key Generierung fehlgeschlagen
        pause
        exit /b 1
    )
) else (
    echo SSH Key existiert bereits
    echo Vorhandene SSH Keys:
    dir "%USERPROFILE%\.ssh\id_rsa*"
)
echo.

:: SSH Key anzeigen
echo Ihr öffentlicher SSH Key:
echo ------------------------
type "%USERPROFILE%\.ssh\id_rsa.pub"
echo.

echo ===== Installation abgeschlossen! =====
echo.
echo Nächste Schritte:
echo 1. Bearbeiten Sie die Datei 'inventory/hosts.yml' und tragen Sie die IP-Adressen Ihrer Server ein
echo 2. Kopieren Sie den oben angezeigten SSH Key auf Ihre Server mit:
echo    Get-Content "%%USERPROFILE%%\.ssh\id_rsa.pub" ^| ssh root@192.168.178.50 "mkdir -p ~/.ssh ^&^& cat ^>^> ~/.ssh/authorized_keys"
echo 3. Führen Sie das Ansible Playbook aus:
echo    ansible-playbook -i inventory/hosts.yml site.yml
echo.
echo Hinweis:
echo Stellen Sie sicher, dass Sie von diesem Computer aus per SSH auf alle Server zugreifen können.
echo Sie können die Verbindung testen mit:
echo ssh root@192.168.178.50

pause 