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
header() { echo -e "\n${CYAN}═══════════════════════════════════════════${NC}"; echo -e "${CYAN}  $*${NC}"; echo -e "${CYAN}═══════════════════════════════════════════${NC}\n"; }

PROFILE="kratix-demo"
NAMESPACE="kratix-demo"

header "🗑️ Kratix in Action — Teardown"

echo -e "${RED}This will delete the Minikube cluster '$PROFILE' and all resources.${NC}"
read -rp "Are you sure? (y/N): " confirm

if [[ "${confirm,,}" != "y" ]]; then
    info "Teardown cancelled."
    exit 0
fi

# ─── Step 1: Delete Resource Requests ───
info "Deleting resource requests..."
kubectl delete nbaservices --all -n "$NAMESPACE" --ignore-not-found=true 2>/dev/null || true
kubectl delete postgresqls --all -n "$NAMESPACE" --ignore-not-found=true 2>/dev/null || true
kubectl delete nbaplatforms --all -n "$NAMESPACE" --ignore-not-found=true 2>/dev/null || true
sleep 5

# ─── Step 2: Delete Promises ───
info "Deleting Promises..."
kubectl delete promises --all --ignore-not-found=true 2>/dev/null || true
sleep 5

# ─── Step 3: Delete Destinations and State Store ───
info "Deleting Destinations and State Store..."
kubectl delete destinations --all --ignore-not-found=true 2>/dev/null || true
kubectl delete bucketstatestores --all --ignore-not-found=true 2>/dev/null || true

# ─── Step 4: Uninstall Kratix ───
info "Uninstalling Kratix..."
kubectl delete --filename https://github.com/syntasso/kratix/releases/latest/download/kratix.yaml --ignore-not-found=true 2>/dev/null || true

# ─── Step 5: Delete Minikube Cluster ───
info "Deleting Minikube cluster: $PROFILE..."
minikube delete -p "$PROFILE"

echo ""
info "✅ Teardown complete — cluster removed"
info "Your system is back to a clean state."
