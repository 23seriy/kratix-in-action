# 🏗️ Kratix in Action

A hands-on project demonstrating **[Kratix](https://kratix.io/)** — the open-source framework for building
internal developer platforms on Kubernetes. Instead of teams filing tickets and waiting for ops to provision resources,
Kratix lets you define **Promises** — self-service APIs that platform teams offer and dev teams consume with `kubectl apply`.

The demo uses three NBA microservices to showcase how Kratix powers platform-as-a-product: dev teams request services,
databases, and monitoring through Promises, while pipelines handle validation, security hardening, and scheduling
— all running on your laptop.

![Kratix](https://img.shields.io/badge/Kratix-0.17-7B2D8E?logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.32-326CE5?logo=kubernetes&logoColor=white)
![Minikube](https://img.shields.io/badge/Minikube-local-F7B93E?logo=kubernetes&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python&logoColor=white)
![Go](https://img.shields.io/badge/Go-1.24-00ADD8?logo=go&logoColor=white)

> 📝 **Read the full walkthrough on Medium:** *(link to be added after publishing)*

## 📖 Documentation

- **[CLAUDE.md](CLAUDE.md)** — Architecture, file structure, and conventions for AI-assisted development
- **[CONTRIBUTING.md](CONTRIBUTING.md)** — How to contribute (features, fixes, docs)
- **[TESTING.md](TESTING.md)** — Manual and automated testing procedures
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** — Common issues and solutions
- **[SECURITY.md](SECURITY.md)** — Vulnerability reporting and responsible disclosure
- **[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)** — Community guidelines
- **[CHANGELOG.md](CHANGELOG.md)** — Release notes

## 🏗️ Architecture

```text
                 ┌──────────────────────────────────────────────────┐
                 │                 Minikube Cluster                  │
                 │           (Kratix Platform + Worker)              │
                 │                                                  │
 Platform ────►  │  Kratix Controller ──────► Promises              │
 Engineer        │  (reconciles requests)     (self-service APIs)   │
                 │       │                                          │
                 │       ├── 🏀 NBA Service Promise                 │
                 │       │    "I need a new microservice"           │
                 │       │                                          │
                 │       ├── 🗄️  PostgreSQL Promise                  │
                 │       │    "I need a database"                   │
                 │       │                                          │
                 │       └── 📦 Compound Promise                    │
                 │            "I need a service + its database"     │
                 │                                                  │
 Dev Team ────►  │  Resource Requests ────► Pipelines ────► Worker  │
 kubectl apply  │  (claims against       (validate,      (resources│
                 │   Promises)            harden,         deployed) │
                 │                        schedule)                 │
                 │                                                  │
                 │  MinIO (State Store) ◄──── GitOps Bridge         │
                 │                                                  │
                 │  scoreboard-api ──► stats-service ──► schedule-  │
                 │  (public)           (internal)        service    │
                 └──────────────────────────────────────────────────┘
```

**Kratix Controller** — The platform engine. Watches Promise definitions and Resource Requests. Runs pipelines to transform requests into scheduled resources.

**Promises** — Self-service APIs defined by the platform team. Each Promise includes an API schema
(what dev teams can request), pipelines (how requests are processed), and scheduling (where resources go).

**Pipelines** — Containers that run when a resource is requested. They validate input, add security contexts, inject labels, generate manifests, and write output for scheduling.

**Destinations** — Target environments where Kratix schedules resources. In this demo, the same cluster serves as both platform and worker.

**MinIO** — S3-compatible object storage used as the BucketStateStore. Kratix writes scheduled resources here; the worker reconciles them.

## 📋 What You'll Learn

| Kratix Concept | What It Does | Demo Scenario |
| --- | --- | --- |
| **Promises** | Define self-service platform capabilities as CRDs | Create an "NBA Service" Promise that generates Deployments + Services |
| **Resource Requests** | Dev teams claim resources from Promises | Request a scoreboard-api with `kubectl apply` |
| **Pipelines** | Transform and validate resource requests | Add security contexts, labels, and resource limits automatically |
| **Destinations** | Schedule resources to target clusters | Register the cluster as a worker Destination |
| **State Store** | Bridge between platform and worker | MinIO stores scheduled resources for GitOps reconciliation |
| **Compound Promises** | Combine multiple capabilities | Request a service + its PostgreSQL database together |
| **Promise Updates** | Evolve platform APIs without breaking consumers | Add monitoring sidecar to existing Promise |
| 🔥 **Pipeline Failure** | Bad pipeline container → stuck request | Diagnose pipeline pod failures |
| 🔥 **Missing Destination** | No destination registered → resources not scheduled | Compare destination names and fix |
| 🔥 **Invalid Request** | Schema validation catches bad input | Fix rejected resource request |

## 🚀 Quick Start

### Step 0: Clone the Repository

```bash
git clone https://github.com/23seriy/kratix-in-action.git
cd kratix-in-action
```

### Prerequisites

- **macOS** (scripts use Homebrew; adapt for Linux)
- **Docker Desktop** running
- ~8 GB RAM available for Minikube (Kratix + MinIO + demo services)

### Step 1: Install Tools

```bash
chmod +x scripts/*.sh
./scripts/01-install-prerequisites.sh
```

This installs or verifies `minikube`, `kubectl`, and `helm` via Homebrew.

### Step 2: Start Cluster + Install Kratix

```bash
./scripts/02-start-cluster.sh
```

Creates a Minikube profile called `kratix-demo` on **Kubernetes v1.32.0**, installs Kratix with Helm, deploys MinIO as the state store, and registers the cluster as a Destination.

### Step 3: Build & Deploy the NBA Services

```bash
./scripts/03-deploy-app.sh
```

Builds Docker images locally and loads them into Minikube, deploys the NBA services to demonstrate the platform capabilities.

### Step 4: Install Promises & Request Resources

```bash
./scripts/04-demo-scenarios.sh
```

This walks you through each Kratix feature interactively, installing Promises and making resource requests.

### Step 5: Access the Scoreboard

In a **separate terminal**:

```bash
kubectl port-forward svc/scoreboard-api 9080:8080 -n kratix-demo
```

Then try:

```bash
# Live scores
curl http://localhost:9080/scores

# Player stats
curl http://localhost:9080/scores/1

# Game schedule
curl http://localhost:9080/schedule

# Health check
curl http://localhost:9080/health
```

## 🎮 Demo Scenarios

### 1. Install Kratix + State Store

```bash
# Already done by 02-start-cluster.sh, but you can verify:
kubectl get pods -n kratix-platform-system
kubectl get pods -n kratix-demo -l app=minio
```

Kratix controller runs in the `kratix-platform-system` namespace. MinIO provides the BucketStateStore for scheduling.

### 2. Register a Destination

```bash
kubectl apply -f kratix/destination.yaml
kubectl get destinations
```

Registers the cluster itself as a worker Destination. In production, this would be a separate cluster — staging, production, or edge.

### 3. Deploy the NBA Service Promise

```bash
kubectl apply -f kratix/promises/nba-service-promise.yaml
kubectl get promises
```

The platform team publishes a Promise. Dev teams can now see it in the catalog and request NBA microservices. The Promise defines:
- **API schema** — service name, port, team, environment
- **Configure pipeline** — generates Deployment + Service + ConfigMap
- **Delete pipeline** — cleans up resources on deletion

### 4. Request a Scoreboard API (Self-Service)

```bash
kubectl apply -f kratix/requests/scoreboard-api-request.yaml
kubectl get nbaservices -n kratix-demo
```

A dev team requests a new scoreboard-api. The pipeline:
1. Validates the request against the schema
2. Generates a Deployment with security context (non-root, read-only filesystem)
3. Creates a matching Service and ConfigMap
4. Schedules everything to the worker Destination

```bash
# Watch the pipeline run
kubectl get pods -n kratix-demo -l kratix.io/promise-name=nba-service

# Check the deployed service
kubectl get deploy,svc -n kratix-demo -l app=scoreboard-api
```

### 5. Pipeline Customization — Security Hardening

```bash
kubectl apply -f kratix/promises/nba-service-promise-v2.yaml
```

Updated Promise pipeline that automatically:
- Adds `runAsNonRoot: true` security context
- Sets CPU/memory resource limits
- Injects standard labels (`app.kubernetes.io/*`)
- Adds `team` and `environment` annotations

Existing services get the new policies when re-requested.

### 6. PostgreSQL Promise — Database as a Platform Capability

```bash
kubectl apply -f kratix/promises/postgresql-promise.yaml
kubectl get promises
```

Platform team adds database provisioning. Dev teams request PostgreSQL instances:

```bash
kubectl apply -f kratix/requests/scoreboard-db-request.yaml
kubectl get postgresqls -n kratix-demo
```

The pipeline generates a PostgreSQL StatefulSet with persistent storage, credentials Secret, and a Service endpoint.

### 7. Compound Promise — Service + Database Together

```bash
kubectl apply -f kratix/promises/nba-platform-promise.yaml
kubectl apply -f kratix/requests/full-stack-request.yaml
kubectl get nbaplatforms -n kratix-demo
```

A single request provisions both the NBA service and its PostgreSQL database, with the service pre-configured
to connect to the database. This is the power of platform abstraction — dev teams don't need to know how to wire
services to databases.

### 8. Update a Running Resource Request

```bash
# Change the environment from "dev" to "staging"
kubectl apply -f kratix/requests/scoreboard-api-request-staging.yaml
kubectl get nbaservices -n kratix-demo
```

The pipeline re-runs with the updated request, modifying the deployed resources without downtime. The resource request is the single source of truth.

### 🔥 9. BREAK IT — Pipeline Failure

```bash
kubectl apply -f kratix/broken/broken-pipeline-promise.yaml
kubectl apply -f kratix/broken/broken-pipeline-request.yaml
kubectl get pods -n kratix-demo -l kratix.io/promise-name=broken-pipeline
kubectl logs -n kratix-demo -l kratix.io/pipeline-name=configure --tail=20
```

The pipeline container image doesn't exist. The pipeline pod is stuck in `ImagePullBackOff`. Learn to diagnose pipeline failures by checking pod status and logs.

**Fix:**

```bash
kubectl delete promise broken-pipeline
kubectl delete nbaservice broken-service -n kratix-demo
```

### 🔥 10. BREAK IT — Missing Destination

```bash
kubectl apply -f kratix/broken/broken-no-destination-promise.yaml
kubectl apply -f kratix/broken/broken-no-destination-request.yaml
kubectl describe nbaservice orphan-service -n kratix-demo
```

The Promise schedules to a Destination called `production` that doesn't exist. Resources are generated but never delivered. Learn to compare destination names with `kubectl get destinations`.

**Fix:**

```bash
kubectl delete promise broken-no-destination
kubectl delete nbaservice orphan-service -n kratix-demo
```

### 🔥 11. BREAK IT — Invalid Resource Request

```bash
kubectl apply -f kratix/broken/broken-invalid-request.yaml
```

The request violates the Promise's API schema (missing required fields, invalid port range). Kubernetes API validation rejects it. Learn to read validation errors and fix the request.

**Fix:** Review the error message and correct the request fields.

## 🔧 Useful Commands

```bash
# Kratix status
kubectl get pods -n kratix-platform-system
kubectl get promises
kubectl get destinations

# Resource requests
kubectl get nbaservices -n kratix-demo
kubectl get postgresqls -n kratix-demo
kubectl get nbaplatforms -n kratix-demo

# Pipeline pods
kubectl get pods -n kratix-demo -l kratix.io/promise-name=nba-service

# Pipeline logs
kubectl logs -n kratix-demo -l kratix.io/pipeline-name=configure --tail=30

# State store (MinIO)
kubectl port-forward svc/minio 9000:9000 -n kratix-demo
# Then open http://localhost:9000 (user: minioadmin / pass: minioadmin)

# Describe a resource request
kubectl describe nbaservice <name> -n kratix-demo

# Describe a Promise
kubectl describe promise nba-service
```

## 📁 Project Structure

```text
kratix-in-action/
├── apps/
│   ├── scoreboard-api/            # Public NBA scoreboard (Flask)
│   │   ├── app.py                 # Calls stats-service and schedule-service
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   ├── stats-service/             # Internal player statistics (Flask)
│   │   ├── app.py
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   ├── schedule-service/          # Internal game schedules (Flask)
│   │   ├── app.py
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   └── pipeline/                  # Promise pipeline container (Go)
│       ├── main.go                # Reads request, generates K8s manifests
│       ├── go.mod
│       └── Dockerfile
├── k8s/                           # Base Kubernetes manifests
│   ├── namespace.yaml
│   ├── scoreboard-api.yaml        # Deployment + Service
│   ├── stats-service.yaml         # Deployment + Service
│   └── schedule-service.yaml      # Deployment + Service
├── kratix/                        # Kratix resources
│   ├── destination.yaml                           # Worker Destination
│   ├── statestore.yaml                            # MinIO BucketStateStore
│   ├── promises/
│   │   ├── nba-service-promise.yaml               # NBA Service Promise (v1)
│   │   ├── nba-service-promise-v2.yaml            # NBA Service Promise (v2 — hardened)
│   │   ├── postgresql-promise.yaml                # PostgreSQL Promise
│   │   └── nba-platform-promise.yaml              # Compound: service + database
│   ├── requests/
│   │   ├── scoreboard-api-request.yaml            # Request scoreboard-api
│   │   ├── scoreboard-api-request-staging.yaml    # Updated request (staging)
│   │   ├── scoreboard-db-request.yaml             # Request PostgreSQL
│   │   └── full-stack-request.yaml                # Request service + database
│   └── broken/
│       ├── broken-pipeline-promise.yaml           # 🔥 Bad pipeline image
│       ├── broken-pipeline-request.yaml           # 🔥 Request for broken pipeline
│       ├── broken-no-destination-promise.yaml     # 🔥 Missing Destination
│       ├── broken-no-destination-request.yaml     # 🔥 Request for missing dest
│       └── broken-invalid-request.yaml            # 🔥 Schema validation failure
├── scripts/                       # Automation scripts
│   ├── 01-install-prerequisites.sh
│   ├── 02-start-cluster.sh
│   ├── 03-deploy-app.sh
│   ├── 04-demo-scenarios.sh
│   └── 05-teardown.sh
├── .github/                       # GitHub community and CI/CD
│   ├── workflows/validate.yml
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── GOVERNANCE.md
│   └── dependabot.yml
└── .gitignore
```

## 🧹 Teardown

```bash
./scripts/05-teardown.sh
```

Deletes all Kratix Promises, resource requests, MinIO, uninstalls Kratix, and removes the Minikube cluster.

## 💡 Key Takeaways

1. **Promises are your platform's API** — Each Promise defines what dev teams can request and how the platform fulfills it. The Promise is the contract between platform and application teams.

2. **Pipelines are the secret sauce** — Custom containers that transform a simple request into production-ready resources. Add security contexts, inject monitoring, wire databases — all automatically.

3. **Self-service reduces tickets to zero** — Dev teams don't file Jira tickets for a new service. They `kubectl apply` a resource request and the platform handles the rest.

4. **Compound Promises compose capabilities** — Request a service + database + monitoring as a single resource. The platform team defines the golden path; dev teams follow it.

5. **Platform evolves without breaking consumers** — Update a Promise pipeline to add new security policies. Existing services get the new policies when re-requested — no migration needed.

6. **Troubleshooting is a skill** — Pipeline failures, missing destinations, and schema violations are the real-world issues platform engineers face. This project teaches you to diagnose them.

## 📚 Resources

- [Kratix Documentation](https://kratix.io/docs/)
- [Kratix — Promises](https://kratix.io/docs/main/guides/writing-a-promise)
- [Kratix — Pipelines](https://kratix.io/docs/main/guides/pipelines)
- [Kratix — Compound Promises](https://kratix.io/docs/main/guides/compound-promises)
- [Kratix GitHub Repository](https://github.com/syntasso/kratix)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)

## 📝 License

MIT — Use freely for learning, demos, and presentations.
