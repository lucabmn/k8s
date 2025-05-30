#!/bin/bash

# Exit on error
set -e

echo "🚀 Starting Argo CD installation..."

# Create namespace
echo "📦 Creating argocd namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install Argo CD
echo "📥 Installing Argo CD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
echo "⏳ Waiting for Argo CD pods to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get the initial admin password
echo "🔑 Getting initial admin password..."
INITIAL_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Get the Argo CD server address
echo "🌐 Getting Argo CD server address..."
SERVER=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ -z "$SERVER" ]; then
    SERVER=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
fi

echo "✅ Argo CD installation completed!"
echo "📝 Important information:"
echo "   - Argo CD Server: https://$SERVER"
echo "   - Username: admin"
echo "   - Password: $INITIAL_PASSWORD"
echo ""
echo "⚠️  Please change the admin password after first login using:"
echo "   argocd account update-password" 