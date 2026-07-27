# AGENTS.md — Kratix in Action

## Project Overview

Hands-on demo of **Kratix** — the open-source framework for building internal developer platforms on Kubernetes. Uses three NBA microservices to showcase Promises (self-service APIs), pipelines (resource transformation), and Destinations (multi-cluster scheduling) on a local Minikube cluster.

## Tech Stack

- **NBA Services**: Python/Flask (scoreboard-api, stats-service, schedule-service)
- **Pipeline**: Go (reads resource requests, generates K8s manifests)
- **Platform**: Minikube (profile: `kratix-demo`)
- **Tool**: Kratix v0.17
- **State Store**: MinIO (S3-compatible, in-cluster)
- **Container**: Docker (images built locally, loaded into Minikube)
- **CI/CD**: GitHub Actions (shellcheck, yamllint, go vet, hadolint, markdown lint)

## Project Structure

```
apps/                  # Application source code
  scoreboard-api/      # Public-facing API (calls stats + schedule internally)
  stats-service/       # Internal player statistics service
  schedule-service/    # Internal game schedules service
  pipeline/            # Promise pipeline container (Go)
kratix/                # Kratix resources
  promises/            # Promise definitions (NBA service, PostgreSQL, compound)
  requests/            # Resource requests (dev team claims)
  broken/              # Intentionally broken resources for troubleshooting demos
  destination.yaml     # Worker Destination registration
  statestore.yaml      # MinIO BucketStateStore configuration
k8s/                   # Base Kubernetes manifests (deployments, services)
scripts/               # Numbered automation scripts (01–05)
```

## Scripts Convention

All scripts are in `scripts/` and numbered sequentially:
- `01-install-prerequisites.sh` — Installs minikube, kubectl, helm via Homebrew
- `02-start-cluster.sh` — Creates Minikube cluster, installs Kratix + MinIO
- `03-deploy-app.sh` — Builds images and deploys the three NBA microservices
- `04-demo-scenarios.sh` — Interactive walkthrough of Promises and resource requests
- `05-teardown.sh` — Destroys cluster (has confirmation prompt)

Scripts use `#!/usr/bin/env bash` and `set -euo pipefail`.

## Key Concepts

- **Promises** in `kratix/promises/` define self-service platform capabilities
- **Resource Requests** in `kratix/requests/` are dev team claims against Promises
- **Pipelines** run as pods (Go container) that transform requests into K8s manifests
- **Destinations** register target clusters/environments for resource scheduling
- **MinIO** is the BucketStateStore bridging platform and worker
- `broken-*.yaml` files demonstrate common platform failures (bad pipeline, missing destination, invalid request)
- The pipeline container reads resource requests and outputs Deployment + Service + ConfigMap manifests

## Security Practices

- Pipeline containers run as non-root user
- Generated Deployments include security contexts (runAsNonRoot, readOnlyRootFilesystem)
- Resource requests and limits defined on all workloads
- No real cloud credentials in the repository

## Conventions

- All Kubernetes resources use the `kratix-demo` namespace (app resources)
- Kratix system components run in `kratix-platform-system` namespace
- Emoji prefixes in script output for readability (🏗️, ✅, 🗑️)
- Color-coded script output: GREEN=info, YELLOW=warn, RED=break, MAGENTA=fix, CYAN=header
- Docker images are built locally and loaded into Minikube (no registry push)
- Commit messages follow `[type] description` convention
- All shell scripts must pass `shellcheck`

# Behavioral Guidelines

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
