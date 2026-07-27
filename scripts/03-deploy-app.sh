#!/usr/bin/env bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
header() { echo -e "\n${CYAN}═══════════════════════════════════════════${NC}"; echo -e "${CYAN}  $*${NC}"; echo -e "${CYAN}═══════════════════════════════════════════${NC}\n"; }

PROFILE="kratix-demo"
NAMESPACE="kratix-demo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

header "🏗️ Kratix in Action — Build & Deploy"

# ─── Step 1: Use Minikube's Docker Daemon ───
info "Switching to Minikube's Docker daemon..."
eval "$(minikube -p "$PROFILE" docker-env)"

# ─── Step 2: Build Docker Images ───
info "Building NBA service images..."

SERVICES=("scoreboard-api" "stats-service" "schedule-service")
for svc in "${SERVICES[@]}"; do
    info "  Building $svc..."
    docker build -t "kratix-demo/$svc:latest" "$SCRIPT_DIR/apps/$svc"
done

info "Building pipeline image..."
docker build -t "kratix-demo/nba-pipeline:latest" "$SCRIPT_DIR/apps/pipeline"

info "✅ All images built"

# ─── Step 3: Deploy NBA Services ───
info "Deploying NBA services..."

for svc in "${SERVICES[@]}"; do
    info "  Deploying $svc..."
    kubectl apply -f "$SCRIPT_DIR/k8s/$svc.yaml"
done

info "Waiting for deployments to be ready..."
for svc in "${SERVICES[@]}"; do
    kubectl wait --for=condition=available "deployment/$svc" -n "$NAMESPACE" --timeout=120s
done

info "✅ All NBA services deployed"

# ─── Step 4: Verify ───
echo ""
info "Deployed services:"
kubectl get deploy,svc -n "$NAMESPACE" -l app.kubernetes.io/part-of=nba-platform
echo ""

info "✅ Deployment complete!"
echo ""
info "To access the scoreboard API, run in a separate terminal:"
info "  kubectl port-forward svc/scoreboard-api 9080:8080 -n $NAMESPACE"
info "  curl http://localhost:9080/scores"
echo ""
info "Next: ./scripts/04-demo-scenarios.sh"
