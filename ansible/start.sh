ansible-playbook -i inventory/hosts.yml site.yml

# Insalliere Helm, ArgoCD, NGINX Ingress
# ansible-playbook -i inventory/hosts.yml site.yml --tags "helm,nginx-ingress,argocd"