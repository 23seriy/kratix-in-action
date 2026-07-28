#!/usr/bin/env bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }
header() { echo -e "\n${CYAN}═══════════════════════════════════════════${NC}"; echo -e "${CYAN}  $*${NC}"; echo -e "${CYAN}═══════════════════════════════════════════${NC}\n"; }

PROFILE="kratix-demo"
K8S_VERSION="v1.32.0"
NAMESPACE="kratix-demo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

header "🏗️ Kratix in Action — Start Cluster"

# ─── Step 1: Create Minikube Cluster ───
info "Creating Minikube cluster: $PROFILE (Kubernetes $K8S_VERSION)"

if minikube status -p "$PROFILE" &> /dev/null; then
    warn "Cluster $PROFILE already exists. Deleting and recreating..."
    minikube delete -p "$PROFILE"
fi

minikube start \
    --profile="$PROFILE" \
    --cpus=4 \
    --memory=8192 \
    --driver=docker \
    --kubernetes-version="$K8S_VERSION"

info "✅ Minikube cluster started"

# ─── Step 2: Create Namespace ───
info "Creating namespace: $NAMESPACE"
kubectl apply -f "$SCRIPT_DIR/k8s/namespace.yaml"

# ─── Step 3: Deploy MinIO (State Store) ───
info "Deploying MinIO as BucketStateStore..."

kubectl apply -n "$NAMESPACE" -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: minio
  labels:
    app: minio
spec:
  replicas: 1
  selector:
    matchLabels:
      app: minio
  template:
    metadata:
      labels:
        app: minio
    spec:
      containers:
        - name: minio
          image: minio/minio:latest
          args: ["server", "/data", "--console-address", ":9001"]
          ports:
            - containerPort: 9000
            - containerPort: 9001
          env:
            - name: MINIO_ROOT_USER
              value: minioadmin
            - name: MINIO_ROOT_PASSWORD
              value: minioadmin
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
---
apiVersion: v1
kind: Service
metadata:
  name: minio
  labels:
    app: minio
spec:
  selector:
    app: minio
  ports:
    - name: api
      port: 9000
      targetPort: 9000
    - name: console
      port: 9001
      targetPort: 9001
  type: ClusterIP
EOF

info "Waiting for MinIO to be ready..."
kubectl wait --for=condition=available deployment/minio -n "$NAMESPACE" --timeout=120s

# Create the kratix bucket in MinIO
info "Creating 'kratix' bucket in MinIO..."
kubectl run minio-setup --rm -i --restart=Never -n "$NAMESPACE" \
    --image=minio/mc:latest -- \
    sh -c "mc alias set myminio http://minio:9000 minioadmin minioadmin && mc mb --ignore-existing myminio/kratix" \
    2>/dev/null || true

info "✅ MinIO deployed and bucket created"

# ─── Step 4: Install cert-manager (Kratix prerequisite) ───
info "Installing cert-manager..."

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml

info "Waiting for cert-manager to be ready..."
kubectl wait --for=condition=available deployment/cert-manager -n cert-manager --timeout=120s
kubectl wait --for=condition=available deployment/cert-manager-webhook -n cert-manager --timeout=120s
kubectl wait --for=condition=available deployment/cert-manager-cainjector -n cert-manager --timeout=120s

info "✅ cert-manager installed"

# ─── Step 5: Install Kratix ───
info "Installing Kratix..."

kubectl apply --filename https://github.com/syntasso/kratix/releases/latest/download/kratix.yaml

info "Waiting for Kratix controller to be ready..."
kubectl wait --for=condition=available deployment/kratix-platform-controller-manager \
    -n kratix-platform-system --timeout=300s

info "✅ Kratix installed"

# ─── Step 6: Configure State Store + Destination ───
info "Configuring BucketStateStore..."
kubectl apply -f "$SCRIPT_DIR/kratix/statestore.yaml"

info "Registering worker Destination..."
kubectl apply -f "$SCRIPT_DIR/kratix/destination.yaml"

info "Verifying Destination..."
kubectl get destinations

echo ""
info "✅ Cluster setup complete!"
echo ""
info "  Minikube profile:  $PROFILE"
info "  Kubernetes:        $K8S_VERSION"
info "  Kratix:            installed"
info "  MinIO:             running (state store)"
info "  Destination:       worker (registered)"
echo ""
info "Next: ./scripts/03-deploy-app.sh"
