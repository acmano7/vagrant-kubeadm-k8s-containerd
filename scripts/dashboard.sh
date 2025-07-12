#!/bin/bash
#
# Deploys the Kubernetes dashboard when enabled in settings.yaml

set -euxo pipefail

config_path="/vagrant/configs"

DASHBOARD_VERSION=$(grep -E '^\s*dashboard:' /vagrant/settings.yaml | sed -E -e 's/[^:]+: *//' -e 's/\r$//')
if [ -n "${DASHBOARD_VERSION}" ]; then
  sudo -i -u vagrant kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

  ### FOR LAB PURPOSE ONLY ###
  sudo -i -u vagrant kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--kubelet-insecure-tls"
  }
]'

  while sudo -i -u vagrant kubectl get pods -A -l k8s-app=metrics-server | awk 'split($3, a, "/") && a[1] != a[2] { print $0; }' | grep -v "RESTARTS"; do
    echo 'Waiting for metrics server to be ready...'
    sleep 5
  done
  echo 'Metrics server is ready. Installing dashboard...'

  sudo -i -u vagrant kubectl create namespace kubernetes-dashboard

  echo "Creating the dashboard user..."

  cat <<EOF | sudo -i -u vagrant kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dashboard-admin-user
  namespace: kubernetes-dashboard
EOF

  cat <<EOF | sudo -i -u vagrant kubectl apply -f -
apiVersion: v1
kind: Secret
type: kubernetes.io/service-account-token
metadata:
  name: dashboard-admin-user
  namespace: kubernetes-dashboard
  annotations:
    kubernetes.io/service-account.name: dashboard-admin-user
EOF

  cat <<EOF | sudo -i -u vagrant kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dashboard-admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: dashboard-admin-user
  namespace: kubernetes-dashboard
EOF

echo "Deploying the dashboard..."

sudo -i -u vagrant helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
sudo -i -u vagrant helm install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --namespace kubernetes-dashboard --version "${DASHBOARD_VERSION}"

  while sudo -i -u vagrant kubectl get pods -A -l app=kubernetes-dashboard-kong | awk 'split($3, a, "/") && a[1] != a[2] { print $0; }' | grep -v "RESTARTS"; do
    echo 'Waiting for dashboard to be ready...'
    sleep 5
  done

sudo -i -u vagrant kubectl -n kubernetes-dashboard get secret/dashboard-admin-user -o go-template="{{.data.token | base64decode}}" >> "${config_path}/token"
echo "The following token was also saved to: configs/token"
cat "${config_path}/token"
echo "
Use it to log in at:
kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443

https://localhost:8443
"
fi
