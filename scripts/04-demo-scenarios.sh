#!/usr/bin/env bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[BREAK]${NC} $*"; }
fix()     { echo -e "${MAGENTA}[FIX]${NC} $*"; }
header()  { echo -e "\n${CYAN}═══════════════════════════════════════════${NC}"; echo -e "${CYAN}  $*${NC}"; echo -e "${CYAN}═══════════════════════════════════════════${NC}\n"; }
pause()   { echo -e "\n${YELLOW}Press Enter to continue to the next scenario...${NC}"; read -r; }

NAMESPACE="kratix-demo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

header "🏗️ Kratix in Action — Demo Scenarios"

# ═══════════════════════════════════════════
# Scenario 1: Verify Kratix + State Store
# ═══════════════════════════════════════════
header "Scenario 1: Verify Kratix + State Store"

info "Checking Kratix controller..."
kubectl get pods -n kratix-platform-system

info "Checking MinIO state store..."
kubectl get pods -n "$NAMESPACE" -l app=minio

info "Checking Destinations..."
kubectl get destinations

info "✅ Kratix platform is running"
pause

# ═══════════════════════════════════════════
# Scenario 2: Deploy the NBA Service Promise
# ═══════════════════════════════════════════
header "Scenario 2: Deploy the NBA Service Promise"

info "Installing the NBA Service Promise..."
kubectl apply -f "$SCRIPT_DIR/kratix/promises/nba-service-promise.yaml"

info "Waiting for Promise to be available..."
sleep 5
kubectl get promises

info "The NBAService CRD is now available:"
kubectl get crd | grep nbaservice || true

info "✅ Promise installed — dev teams can now request NBA services"
pause

# ═══════════════════════════════════════════
# Scenario 3: Request a Scoreboard API
# ═══════════════════════════════════════════
header "Scenario 3: Request a Scoreboard API (Self-Service)"

info "Dev team requests a scoreboard-api..."
kubectl apply -f "$SCRIPT_DIR/kratix/requests/scoreboard-api-request.yaml"

info "Watching resource request status..."
sleep 3
kubectl get nbaservices -n "$NAMESPACE"

info "Checking pipeline pods..."
kubectl get pods -n "$NAMESPACE" -l kratix.io/promise-name=nba-service 2>/dev/null || true

info "Waiting for pipeline to complete..."
sleep 15

info "Checking generated resources..."
kubectl get deploy,svc -n "$NAMESPACE" -l app.kubernetes.io/managed-by=kratix 2>/dev/null || true

info "✅ Scoreboard API provisioned via Kratix Promise"
pause

# ═══════════════════════════════════════════
# Scenario 4: Pipeline Customization (v2)
# ═══════════════════════════════════════════
header "Scenario 4: Pipeline Customization — Security Hardening"

info "Upgrading Promise to v2 with security hardening pipeline..."
kubectl apply -f "$SCRIPT_DIR/kratix/promises/nba-service-promise-v2.yaml"

info "The updated Promise adds:"
info "  • NetworkPolicy for each service"
info "  • Security context enforcement"
info "  • Standard Kubernetes labels"

info "Re-requesting scoreboard-api to get new policies..."
kubectl apply -f "$SCRIPT_DIR/kratix/requests/scoreboard-api-request.yaml"
sleep 10

info "Checking for NetworkPolicy..."
kubectl get networkpolicy -n "$NAMESPACE" 2>/dev/null || info "  (NetworkPolicy will appear after pipeline runs)"

info "✅ Promise upgraded — existing services get new policies on re-request"
pause

# ═══════════════════════════════════════════
# Scenario 5: PostgreSQL Promise
# ═══════════════════════════════════════════
header "Scenario 5: PostgreSQL Promise — Database as a Platform Capability"

info "Installing the PostgreSQL Promise..."
kubectl apply -f "$SCRIPT_DIR/kratix/promises/postgresql-promise.yaml"
sleep 5
kubectl get promises

info "Dev team requests a database..."
kubectl apply -f "$SCRIPT_DIR/kratix/requests/scoreboard-db-request.yaml"
sleep 15

info "Checking database resources..."
kubectl get postgresqls -n "$NAMESPACE"
kubectl get statefulset,svc,secret -n "$NAMESPACE" -l app.kubernetes.io/managed-by=kratix 2>/dev/null || true

info "✅ PostgreSQL database provisioned via Promise"
pause

# ═══════════════════════════════════════════
# Scenario 6: Compound Promise
# ═══════════════════════════════════════════
header "Scenario 6: Compound Promise — Service + Database Together"

info "Installing the NBA Platform compound Promise..."
kubectl apply -f "$SCRIPT_DIR/kratix/promises/nba-platform-promise.yaml"
sleep 5
kubectl get promises

info "Requesting a full-stack deployment (service + database)..."
kubectl apply -f "$SCRIPT_DIR/kratix/requests/full-stack-request.yaml"
sleep 15

kubectl get nbaplatforms -n "$NAMESPACE"

info "✅ Compound Promise provisions service + database with one request"
pause

# ═══════════════════════════════════════════
# Scenario 7: Update a Running Request
# ═══════════════════════════════════════════
header "Scenario 7: Update a Running Resource Request"

info "Updating scoreboard-api from dev → staging with 2 replicas..."
kubectl apply -f "$SCRIPT_DIR/kratix/requests/scoreboard-api-request-staging.yaml"
sleep 10

kubectl get nbaservices -n "$NAMESPACE"

info "✅ Resource request updated — pipeline re-runs with new parameters"
pause

# ═══════════════════════════════════════════
# Scenario 8: 🔥 BREAK IT — Pipeline Failure
# ═══════════════════════════════════════════
header "🔥 Scenario 8: BREAK IT — Pipeline Failure"

error "Installing a Promise with a broken pipeline image..."
kubectl apply -f "$SCRIPT_DIR/kratix/broken/broken-pipeline-promise.yaml"
sleep 3

error "Requesting a service (this will fail)..."
kubectl apply -f "$SCRIPT_DIR/kratix/broken/broken-pipeline-request.yaml"
sleep 10

error "Check the pipeline pod status:"
kubectl get pods -n "$NAMESPACE" -l kratix.io/promise-name=broken-pipeline 2>/dev/null || true

error "The pipeline pod is stuck — the container image doesn't exist"
error "Diagnosis: kubectl describe pod -n $NAMESPACE -l kratix.io/promise-name=broken-pipeline"

fix "Cleaning up broken resources..."
kubectl delete promise broken-pipeline --ignore-not-found=true 2>/dev/null || true
kubectl delete brokenpipeline broken-service -n "$NAMESPACE" --ignore-not-found=true 2>/dev/null || true
sleep 5

info "✅ Lesson: Always verify pipeline container images exist before publishing a Promise"
pause

# ═══════════════════════════════════════════
# Scenario 9: 🔥 BREAK IT — Missing Destination
# ═══════════════════════════════════════════
header "🔥 Scenario 9: BREAK IT — Missing Destination"

error "Installing a Promise that targets a 'production' Destination..."
kubectl apply -f "$SCRIPT_DIR/kratix/broken/broken-no-destination-promise.yaml"
sleep 3

error "Requesting a service..."
kubectl apply -f "$SCRIPT_DIR/kratix/broken/broken-no-destination-request.yaml"
sleep 10

error "Compare available Destinations with what the Promise expects:"
kubectl get destinations
error "The Promise expects environment=production, but our Destination has environment=dev"

fix "Cleaning up..."
kubectl delete promise broken-no-destination --ignore-not-found=true 2>/dev/null || true
kubectl delete orphanservice orphan-service -n "$NAMESPACE" --ignore-not-found=true 2>/dev/null || true
sleep 5

info "✅ Lesson: Ensure Destination labels match Promise destinationSelectors"
pause

# ═══════════════════════════════════════════
# Scenario 10: 🔥 BREAK IT — Invalid Request
# ═══════════════════════════════════════════
header "🔥 Scenario 10: BREAK IT — Invalid Resource Request"

error "Submitting a request that violates the Promise schema..."
error "  - name: 'ab' (too short, min 3)"
error "  - port: 80 (out of range, min 1024)"
error "  - environment: 'invalid-env' (not in enum)"
error "  - team: missing (required field)"
echo ""

if kubectl apply -f "$SCRIPT_DIR/kratix/broken/broken-invalid-request.yaml" 2>&1; then
    warn "Request was accepted (schema validation may be lenient)"
else
    info "Request was rejected by schema validation — this is the expected behavior"
fi

info "✅ Lesson: Promise API schemas catch invalid requests at admission time"

echo ""
header "🏆 All Demo Scenarios Complete!"
echo ""
info "Summary:"
info "  ✅ Scenario 1:  Kratix + State Store verified"
info "  ✅ Scenario 2:  NBA Service Promise deployed"
info "  ✅ Scenario 3:  Scoreboard API self-service request"
info "  ✅ Scenario 4:  Pipeline v2 security hardening"
info "  ✅ Scenario 5:  PostgreSQL database Promise"
info "  ✅ Scenario 6:  Compound Promise (service + database)"
info "  ✅ Scenario 7:  Resource request update"
info "  🔥 Scenario 8:  Pipeline failure (diagnosed + fixed)"
info "  🔥 Scenario 9:  Missing Destination (diagnosed + fixed)"
info "  🔥 Scenario 10: Invalid request (schema validation)"
echo ""
info "To clean up: ./scripts/05-teardown.sh"
