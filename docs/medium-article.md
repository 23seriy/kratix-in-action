# I Replaced Our Entire Ticketing System With 4 Lines of YAML

## How Kratix Promises turned "file a Jira ticket and wait 3 days" into `kubectl apply` — and why your platform team should care

---

Last quarter, a developer on my team needed a new microservice. They opened a Jira ticket. It sat in a queue for two days. An ops engineer provisioned a Deployment, a Service, a ConfigMap, a Secret, set up resource limits, added security contexts, wired DNS, and tagged everything with the right labels.

Total time: 3 days. Total human effort: 4 hours across two people.

The service was identical to the last seven we'd deployed.

This is the moment I realized we didn't have a platform — we had a ticketing system with Kubernetes underneath.

---

## The Problem Nobody Talks About

Platform engineering is the hottest topic in DevOps right now. Every conference has a talk about it. Every company wants an "internal developer platform." But here's what nobody admits:

**Most "platforms" are just a pile of Terraform modules, Helm charts, and tribal knowledge held together by Slack threads and good intentions.**

Developers don't want to learn your custom tooling. They don't want to read a 40-page wiki. They don't want to open a ticket and wait. They want to say *"I need a service"* and get one.

That's exactly what Kratix does.

---

## What Is Kratix (and Why Should You Care)?

[Kratix](https://kratix.io/) is an open-source framework by [Syntasso](https://www.syntasso.io/) for building internal developer platforms on Kubernetes. But calling it "a framework" undersells it. Here's the pitch:

> **Kratix lets platform teams define self-service APIs called Promises. Developers consume them with `kubectl apply`. The platform handles everything else.**

Think of it this way:

- **Without Kratix**: Dev opens ticket → Ops reads ticket → Ops writes YAML → Ops applies YAML → Dev waits → Dev gets access
- **With Kratix**: Dev runs `kubectl apply -f my-service.yaml` → Pipeline validates, hardens, and deploys → Done

No tickets. No queues. No back-and-forth on Slack.

---

## I Built a Full Demo to Prove It Works

I created **[kratix-in-action](https://github.com/23seriy/kratix-in-action)** — a hands-on project that demonstrates every major Kratix concept using NBA microservices. Why NBA? Because if I'm going to stare at terminal output for hours, I want it to show basketball scores, not "hello world."

The project includes:

- **3 NBA microservices** (Python/Flask) — a scoreboard API, stats service, and schedule service
- **4 Kratix Promises** — single service, PostgreSQL database, compound (service + DB), and security-hardened variants
- **A Go pipeline container** — that transforms resource requests into production-ready Kubernetes manifests
- **3 intentionally broken scenarios** — because platform engineering is 50% building and 50% debugging
- **5 numbered automation scripts** — clone, run, learn

Everything runs on your laptop with Minikube. No cloud account needed.

---

## The Architecture (Keep It Simple)

```
┌──────────────────────────────────────────────────┐
│                 Minikube Cluster                  │
│           (Kratix Platform + Worker)              │
│                                                  │
│  Kratix Controller ──────► Promises              │
│  (reconciles requests)     (self-service APIs)   │
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
│  Resource Requests ────► Pipelines ────► Worker  │
│  (dev team claims)      (validate,     (deployed)│
│                          harden,                 │
│                          schedule)               │
└──────────────────────────────────────────────────┘
```

The key insight: **Kratix separates *what* from *how*.** Dev teams say *what* they need (a service, a database). The platform defines *how* it's delivered (with security contexts, resource limits, labels, monitoring — baked into pipelines).

---

## Let's Build It: From Zero to Self-Service in 20 Minutes

### Step 1: Set up the cluster

```bash
git clone https://github.com/23seriy/kratix-in-action.git
cd kratix-in-action
./scripts/01-install-prerequisites.sh
./scripts/02-start-cluster.sh
```

This creates a Minikube cluster, installs Kratix, deploys MinIO as the state store, and registers the cluster as a Destination. One script. Two minutes.

### Step 2: Create your first Promise

A Promise is the heart of Kratix. It defines:

1. **An API** — what fields developers can set (service name, port, team, environment)
2. **A pipeline** — containers that transform the request into Kubernetes resources
3. **Scheduling** — where the resources should be deployed

```bash
kubectl apply -f kratix/promises/nba-service-promise.yaml
kubectl get promises
```

```
NAME          STATUS      AGE
nba-service   Available   5s
```

That's it. Your platform now offers "NBA Service" as a self-service capability. Dev teams can see it. They can request it. They don't need to know what happens inside.

### Step 3: A developer requests a service

Here's where the magic happens. A developer creates a 4-line resource request:

```yaml
apiVersion: demo.kratix.io/v1alpha1
kind: NBAService
metadata:
  name: scoreboard-api
  namespace: kratix-demo
spec:
  name: scoreboard-api
  port: 8080
  team: platform-demo
  environment: dev
```

```bash
kubectl apply -f kratix/requests/scoreboard-api-request.yaml
```

Behind the scenes, Kratix:

1. **Validates** the request against the Promise schema
2. **Runs the pipeline** — a Go container that generates a Deployment, Service, and ConfigMap with security contexts, resource limits, and standard labels
3. **Schedules** the resources to the worker Destination
4. **Deploys** everything automatically

The developer didn't write a single line of Kubernetes YAML. They didn't need to know about security contexts, resource limits, or label conventions. The platform handled it.

```bash
kubectl get deploy,svc -n kratix-demo -l app=scoreboard-api
```

```
NAME                             READY   UP-TO-DATE
deployment.apps/scoreboard-api   1/1     1

NAME                     TYPE        CLUSTER-IP     PORT(S)
service/scoreboard-api   ClusterIP   10.96.45.123   8080/TCP
```

**From request to running service: under 30 seconds.**

---

## The Pipeline: Where Platform Engineering Actually Happens

The pipeline is where you encode your organization's standards. In my demo, the pipeline container is written in Go and does the following:

1. Reads the resource request from `/kratix/input/object.yaml`
2. Generates a **Deployment** with:
   - `runAsNonRoot: true`
   - `readOnlyRootFilesystem: true`
   - CPU/memory requests and limits
   - Standard `app.kubernetes.io/*` labels
3. Generates a **Service** matching the requested port
4. Generates a **ConfigMap** with environment-specific configuration
5. Writes everything to `/kratix/output/`

Every service that comes through this pipeline automatically gets security hardening, resource governance, and consistent labeling. **No developer effort. No ops tickets. No exceptions.**

And when you update the pipeline? Every service gets the new standards when it's re-requested. Zero migration.

---

## Compound Promises: The Real Power

Individual Promises are useful. Compound Promises are transformative.

Imagine a developer needs a service *and* a database. Without Kratix, that's two tickets, two provisioning workflows, and manual wiring between them. With a Compound Promise:

```bash
kubectl apply -f kratix/promises/nba-platform-promise.yaml
kubectl apply -f kratix/requests/full-stack-request.yaml
```

One request. The platform provisions the service, provisions PostgreSQL, generates the connection credentials, and wires them together. The developer gets a fully connected stack without knowing how any of it works.

**This is the promise (pun intended) of platform engineering: composable, self-service infrastructure.**

---

## Break Things on Purpose (Seriously)

Here's what separates this project from most Kratix tutorials: **I intentionally built broken scenarios.**

Real platform engineering isn't just about the happy path. It's about diagnosing failures. The demo includes three deliberately broken scenarios:

### 🔥 Broken Pipeline

```bash
kubectl apply -f kratix/broken/broken-pipeline-promise.yaml
kubectl apply -f kratix/broken/broken-pipeline-request.yaml
```

The pipeline container image doesn't exist. The pod gets stuck in `ImagePullBackOff`. You learn to diagnose it:

```bash
kubectl get pods -n kratix-demo -l kratix.io/promise-name=broken-pipeline
kubectl describe pod <pod-name> -n kratix-demo
```

### 🔥 Missing Destination

The Promise targets a "production" Destination that doesn't exist. Resources are generated but never delivered. You learn to check destination registration and label matching.

### 🔥 Invalid Request

The request violates the schema — missing required fields, port out of range. Kubernetes API validation rejects it. You learn to read validation errors.

**These aren't edge cases. These are the problems platform engineers face every week.** Teaching people to debug them is just as valuable as teaching them to build.

---

## Why Kratix Over Crossplane, Backstage, or Custom Tools?

This comes up a lot. Here's my take:

| Tool | What It Does | When to Use It |
|------|-------------|----------------|
| **Crossplane** | Provisions cloud resources via Kubernetes CRDs | You need to manage AWS/GCP/Azure resources declaratively |
| **Backstage** | Developer portal with service catalog and templates | You need a UI for discoverability and documentation |
| **Kratix** | Self-service platform APIs with pipeline-based fulfillment | You need to encode platform standards into automated workflows |
| **Custom scripts** | Whatever you duct-tape together | Please don't |

They're not competitors — they're complementary. Kratix handles the *fulfillment layer*: what happens when someone requests a resource. It can trigger Crossplane compositions, Helm releases, Terraform runs, or plain Kubernetes manifests. Backstage can serve as the frontend.

But if I had to pick one tool to start building a platform? **Kratix.** Because it solves the hardest problem: turning organizational standards into automated, self-service workflows.

---

## 6 Things I Learned Building This

1. **Promises are your platform's API contract.** They define what dev teams can request and how the platform fulfills it. Get the API right, and adoption follows.

2. **Pipelines are the secret sauce.** Every org has standards — security contexts, resource limits, label conventions, monitoring. Pipelines encode them once and enforce them everywhere.

3. **Self-service eliminates tickets.** Once the Promise exists, developers don't need ops. They `kubectl apply` and move on. The platform handles the rest.

4. **Compound Promises create golden paths.** "I need a service with a database" becomes a single request. The platform wires everything together.

5. **Platform evolution doesn't break consumers.** Update a pipeline to add new security policies. Existing services get them on re-request. No migration scripts.

6. **Troubleshooting is a first-class skill.** Pipeline failures, missing destinations, and schema violations are the daily reality of platform engineering. Teach your team to diagnose them.

---

## Try It Yourself

The entire project is open source and runs on your laptop:

```bash
git clone https://github.com/23seriy/kratix-in-action.git
cd kratix-in-action
./scripts/01-install-prerequisites.sh
./scripts/02-start-cluster.sh
./scripts/03-deploy-app.sh
./scripts/04-demo-scenarios.sh
```

**20 minutes. 10 scenarios. Zero cloud costs.**

The repo includes detailed documentation, troubleshooting guides, and CI/CD workflows. Star it if you find it useful: **[github.com/23seriy/kratix-in-action](https://github.com/23seriy/kratix-in-action)**

---

## What's Next?

I'm planning to extend this project with:

- **GitOps integration** — replacing MinIO with Flux/ArgoCD as the state store
- **Multi-cluster scheduling** — separate platform and worker clusters
- **Monitoring Promise** — auto-inject Prometheus ServiceMonitor and Grafana dashboards
- **RBAC and multi-tenancy** — different teams, different Promises, different permissions

If you're building an internal developer platform (or thinking about it), Kratix is worth your time. It's the closest thing I've seen to a framework that actually makes platform-as-a-product practical.

---

*Sergei Olshanetski is a DevOps engineer who believes the best platform is the one developers actually use. Find him on [GitHub](https://github.com/23seriy).*

---

## Medium Publishing Notes

**Title**: I Replaced Our Entire Ticketing System With 4 Lines of YAML

**Subtitle**: How Kratix Promises turned "file a Jira ticket and wait 3 days" into kubectl apply — and why your platform team should care

**Tags** (pick 5):
1. Platform Engineering
2. Kubernetes
3. DevOps
4. Internal Developer Platform
5. Infrastructure as Code

**Publications to submit to** (ordered by reach):
1. **Better Programming** — largest dev publication on Medium
2. **ITNEXT** — strong Kubernetes/DevOps audience
3. **DevOps.dev** — niche but targeted
4. **Towards Dev** — growing publication
5. **Level Up Coding** — wide developer audience

**SEO keywords to include naturally**:
- platform engineering
- internal developer platform
- Kratix
- self-service Kubernetes
- developer experience
- platform as a product
- Kubernetes CRD
- GitOps

**Recommended reading time**: ~11 minutes (optimal for Medium engagement)

**Featured image suggestion**: Architecture diagram from the repo, or a split-screen showing "Jira ticket queue" vs. "kubectl apply" terminal
