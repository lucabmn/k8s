#!/bin/bash

# --- Variablen ---
INGRESS_NGINX_NAMESPACE="ingress-nginx"
INGRESS_NGINX_RELEASE_NAME="ingress-nginx"
# Verwende die offizielle Helm Chart URL
INGRESS_NGINX_CHART_URL="https://kubernetes.github.io/ingress-nginx"
INGRESS_NGINX_CHART_NAME="ingress-nginx"

# --- Funktionen ---

# Funktion zur Überprüfung von Helm
check_helm_installed() {
    if ! command -v helm &> /dev/null; then
        echo "FEHLER: Helm ist nicht installiert. Bitte installiere Helm zuerst, bevor du diesen Skript ausführst. 🚨"
        echo "Siehe https://helm.sh/docs/intro/install/ für Installationsanweisungen."
        exit 1
    fi
    echo "Helm ist installiert. Weiter geht's! 🎉"
}

# --- Hauptskript Start ---

echo "=== NGINX Ingress Controller Installationsskript mit Helm ==="
echo "Dieses Skript installiert den NGINX Ingress Controller in deinem Kubernetes Cluster. 🌐"
echo "Es wird davon ausgegangen, dass du dies auf deinem Master Node ausführst und 'kubectl' sowie 'helm' bereits konfiguriert sind. 👑"

echo ""
echo "1. Überprüfe, ob Helm installiert ist..."
check_helm_installed

echo ""
echo "2. Füge das Ingress-Nginx Helm Repository hinzu..."
helm repo add ${INGRESS_NGINX_CHART_NAME} ${INGRESS_NGINX_CHART_URL}
if [ $? -ne 0 ]; then
    echo "Fehler: Konnte das Helm Repository nicht hinzufügen. Abbruch. 😢"
    exit 1
fi
echo "Helm Repository erfolgreich hinzugefügt. ✨"

echo ""
echo "3. Aktualisiere deine Helm Repositories..."
helm repo update
if [ $? -ne 0 ]; then
    echo "Fehler: Konnte Helm Repositories nicht aktualisieren. Abbruch. 😢"
    exit 1
fi
echo "Helm Repositories aktualisiert. ✅"

echo ""
echo "4. Erstelle den '${INGRESS_NGINX_NAMESPACE}' Namespace, falls er noch nicht existiert..."
kubectl create namespace ${INGRESS_NGINX_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
if [ $? -ne 0 ]; then
    echo "Fehler: Konnte den Namespace '${INGRESS_NGINX_NAMESPACE}' nicht erstellen. Abbruch. 😢"
    exit 1
fi
echo "Namespace '${INGRESS_NGINX_NAMESPACE}' ist bereit. 📁"

echo ""
echo "5. Installiere den NGINX Ingress Controller mit Helm. (Verwende NodePort für Bare-Metal)"
echo "   Dies wird den Ingress Controller als Deployment und einen Service vom Typ NodePort erstellen."

helm install ${INGRESS_NGINX_RELEASE_NAME} ${INGRESS_NGINX_CHART_NAME}/${INGRESS_NGINX_CHART_NAME} \
  --namespace ${INGRESS_NGINX_NAMESPACE} \
  --set controller.service.type=NodePort \
  --set controller.service.externalTrafficPolicy=Local \
  --wait # Warte, bis die Installation abgeschlossen ist

if [ $? -ne 0 ]; then
    echo "Fehler: Die Helm-Installation des NGINX Ingress Controllers ist fehlgeschlagen. Abbruch. ❌"
    echo "Bitte überprüfe die Helm-Ausgabe oben auf weitere Details."
    exit 1
fi

echo ""
echo "=== NGINX Ingress Controller Installation erfolgreich! 🎉 ==="
echo "Du kannst den Status überprüfen mit: "
echo "  kubectl get pods -n ${INGRESS_NGINX_NAMESPACE}"
echo "  kubectl get svc -n ${INGRESS_NGINX_NAMESPACE}"
echo ""
echo "Der Ingress Controller läuft jetzt. Um Anwendungen extern zugänglich zu machen, musst du:"
echo "1. Ingress-Ressourcen für deine Anwendungen erstellen. 📝"
echo "2. Die IP-Adresse deiner Worker-Nodes und die zugewiesenen NodePorts des Ingress-Services verwenden,"
echo "   um den Ingress Controller von außen zu erreichen. Suche nach den NodePorts mit:"
echo "   kubectl get svc ${INGRESS_NGINX_RELEASE_NAME}-controller -n ${INGRESS_NGINX_NAMESPACE}"
echo ""
echo "Viel Spaß beim Routen deines Traffics! 🚦"