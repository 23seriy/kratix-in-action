# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- (Unreleased items go here)

### Changed
- (Changes go here)

### Fixed
- (Bug fixes go here)

---

## [1.0.0] — 2026-07-27

### Added

#### Documentation
- **CONTRIBUTING.md** — Contribution guidelines and development workflow
- **TESTING.md** — Manual and automated testing procedures
- **TROUBLESHOOTING.md** — Comprehensive troubleshooting guide for common issues
- **SECURITY.md** — Security policies and responsible disclosure process
- **CODE_OF_CONDUCT.md** — Community standards and code of conduct
- **CHANGELOG.md** — This file

#### CI/CD
- **GitHub Actions workflow** (`.github/workflows/validate.yml`) with:
  - Shell script linting (shellcheck)
  - YAML validation (yamllint)
  - Go build and vet
  - Dockerfile linting (hadolint)
  - Markdown linting
- **GitHub issue templates** for bug reports and feature requests
- **GitHub pull request template** with testing checklist
- **Dependabot configuration** for automated dependency updates
- **Project governance document** (`.github/GOVERNANCE.md`)

#### Development Tools
- **Shell configuration** (`.shellcheckrc`) for script validation
- **Markdown linting configuration** (`.markdownlint.json`)
- **Enhanced `.gitignore`** with Go, Python, Kubernetes, and IDE patterns

#### Security Improvements
- **Non-root containers** — All Dockerfiles run as UID 10001
- **Resource limits** — Deployments include CPU/memory requests and limits
- **Security contexts** — Pods run with `runAsNonRoot`, `readOnlyRootFilesystem`, dropped capabilities

### Core Features (Initial Release)

#### Scripts
- `01-install-prerequisites.sh` — Install Homebrew tools (minikube, kubectl, helm)
- `02-start-cluster.sh` — Create Minikube cluster, install Kratix + MinIO
- `03-deploy-app.sh` — Build images and deploy NBA services
- `04-demo-scenarios.sh` — 10 interactive scenarios (7 happy-path + 3 troubleshooting)
- `05-teardown.sh` — Clean up cluster (with confirmation prompt)

#### Demo Scenarios
1. **Verify Kratix + State Store** — Confirm platform is running
2. **Deploy NBA Service Promise** — Platform team publishes self-service API
3. **Request Scoreboard API** — Dev team self-service request
4. **Pipeline Customization** — v2 with security hardening
5. **PostgreSQL Promise** — Database as a platform capability
6. **Compound Promise** — Service + database together
7. **Update Resource Request** — Modify running service
8. **🔥 Pipeline Failure** — Bad container image diagnosis
9. **🔥 Missing Destination** — Unmatched label diagnosis
10. **🔥 Invalid Request** — Schema validation failure

#### Promises
- `nba-service-promise.yaml` — NBA Service Promise (v1)
- `nba-service-promise-v2.yaml` — NBA Service Promise (v2 — security hardened)
- `postgresql-promise.yaml` — PostgreSQL database Promise
- `nba-platform-promise.yaml` — Compound: service + database
- `broken-pipeline-promise.yaml` — 🔥 Bad pipeline image
- `broken-no-destination-promise.yaml` — 🔥 Missing Destination
- `broken-invalid-request.yaml` — 🔥 Schema violation

#### Applications
- **scoreboard-api** — Public NBA scoreboard (Flask, calls stats + schedule)
- **stats-service** — Internal player statistics (Flask)
- **schedule-service** — Internal game schedules (Flask)
- **pipeline** — Promise pipeline container (Go, generates K8s manifests)

### Tested With

- **Kubernetes** — v1.32.0
- **Kratix** — v0.17 (latest)
- **Minikube** — latest
- **macOS** — 13.0+
- **Docker Desktop** — latest
- **Go** — 1.24
- **Python** — 3.12

---

## Semantic Versioning

- **MAJOR** (1.x.0) — Breaking changes (incompatible script changes, major Kratix version)
- **MINOR** (x.1.0) — New features (new Promises, scenarios, pipeline steps)
- **PATCH** (x.x.1) — Bug fixes (script fixes, documentation, typos)

---

[Unreleased]: https://github.com/23seriy/kratix-in-action/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/23seriy/kratix-in-action/releases/tag/v1.0.0
