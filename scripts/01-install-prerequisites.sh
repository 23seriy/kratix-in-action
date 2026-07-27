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

header "🏗️ Kratix in Action — Install Prerequisites"

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    warn "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install tools
TOOLS=("minikube" "kubectl" "helm")

for tool in "${TOOLS[@]}"; do
    if command -v "$tool" &> /dev/null; then
        info "$tool is already installed: $($tool version --short 2>/dev/null || $tool version 2>/dev/null | head -1)"
    else
        info "Installing $tool..."
        brew install "$tool"
        info "$tool installed successfully"
    fi
done

# Check Docker
if ! command -v docker &> /dev/null; then
    warn "Docker not found. Please install Docker Desktop from https://www.docker.com/products/docker-desktop/"
    exit 1
fi

if ! docker info &> /dev/null; then
    warn "Docker is not running. Please start Docker Desktop."
    exit 1
fi

info "Docker is running: $(docker version --format '{{.Server.Version}}' 2>/dev/null)"

echo ""
info "✅ All prerequisites installed successfully!"
echo ""
info "Versions:"
info "  minikube: $(minikube version --short 2>/dev/null)"
info "  kubectl:  $(kubectl version --client --short 2>/dev/null || kubectl version --client -o json 2>/dev/null | grep gitVersion | head -1 | awk -F'"' '{print $4}')"
info "  helm:     $(helm version --short 2>/dev/null)"
info "  docker:   $(docker version --format '{{.Server.Version}}' 2>/dev/null)"
echo ""
info "Next: ./scripts/02-start-cluster.sh"
