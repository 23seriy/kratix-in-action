# I Replaced Our Entire Ticketing System With 4 Lines of YAML

## How Kratix Promises turned "file a Jira ticket and wait 3 days" into `kubectl apply` — and why your platform team should care

---

**A developer needed a new microservice.**

She opened a Jira ticket. It sat in a queue. Two days later, an ops engineer picked it up.
He provisioned a Deployment, a Service, a ConfigMap, a Secret. Set up resource limits.
Added security contexts. Wired DNS. Tagged everything with the right labels.

**Total time: 3 days. Total human effort: 4 hours across two people.**

The service was identical to the last seven we'd deployed.

I looked at the ticket. I looked at the seven before it. Same template. Same labels. Same security contexts. Copy-pasted from Confluence, adjusted by hand, applied with fingers crossed.

That's when it hit me: *we didn't have a platform. We had a ticketing system with Kubernetes underneath.*

Sound familiar?

---

## The Dirty Secret of "Platform Engineering"

Platform engineering is everywhere right now. Every KubeCon talk. Every blog post. Every job listing. Everyone wants an "internal developer platform."

But here's what nobody says out loud at the conference afterparty:

> **Most "platforms" are just a pile of Terraform modules, Helm charts, and tribal knowledge held together by Slack threads and good intentions.**

Be honest. How does a developer get a new service at your company right now?

- Open a ticket? **That's not a platform. That's a queue.**
- Clone a template repo and modify 15 files? **That's not self-service. That's busywork.**
- Message someone on Slack who "knows how things work"? **That's not a platform. That's a single point of failure.**

Developers don't want to learn your custom tooling. They don't want to read a 40-page Confluence wiki. They don't want to open a ticket and wait.

They want to say *"I need a service"* and get one.

**What if you could make that happen with a single `kubectl apply`?**

---

## Enter Kratix: Platform-as-a-Product, Not Platform-as-a-Jira-Board

[Kratix](https://kratix.io/) is an open-source framework by [Syntasso](https://www.syntasso.io/) for building internal developer platforms on Kubernetes.

But calling it "a framework" undersells it. Here's the pitch in one sentence:

> **Kratix lets platform teams define self-service APIs called Promises. Developers consume them with `kubectl apply`. The platform handles everything else.**

Still abstract? Let me make it concrete:

**Without Kratix:**

Dev opens ticket → Ops reads ticket → Ops writes YAML → Ops applies YAML → Dev waits 3 days → Dev gets access → Dev finds a typo in the config → cycle repeats

**With Kratix:**

Dev runs `kubectl apply -f my-service.yaml` → Pipeline validates, hardens, and deploys → Done in 30 seconds

No tickets. No queues. No "hey, can you check on my deployment?" Slack messages.

*That's the difference between a platform and a ticketing system.*

---

## "Show Me the Code" — I Built a Full Demo

I don't trust blog posts that stop at architecture diagrams. So I built a working project that proves every claim in this article.

**[kratix-in-action](https://github.com/23seriy/kratix-in-action)** demonstrates every major Kratix concept
using NBA microservices as the workload. Why NBA? Because if I'm going to stare at terminal output
for hours debugging pipelines, I want it to show basketball scores, not "hello world."

Here's what's in the repo:

- **3 NBA microservices** (Python/Flask) — scoreboard API, stats service, schedule service
- **4 Kratix Promises** — single service, PostgreSQL database, compound (service + DB), security-hardened variant
- **A Go pipeline container** — transforms resource requests into production-ready K8s manifests
- **3 intentionally broken scenarios** — because real platform engineering is 50% building and 50% debugging
- **5 numbered scripts** — clone, run, learn. Nothing to configure.

**Everything runs on your laptop with Minikube.** No cloud account. No credit card. No "contact sales."

---

## How It Works: The Architecture in 60 Seconds

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

The key insight — and the thing that makes Kratix different from yet-another-Helm-wrapper:

**Kratix separates *what* from *how*.**

Dev teams declare *what* they need: "a service," "a database," "a service with a database."

The platform defines *how* it's delivered: with security contexts, resource limits, standard labels, monitoring sidecars — all baked into pipelines that run automatically.

*Developers never see the complexity. They just get working infrastructure.*

---

## From Zero to Self-Service in 20 Minutes

Let me walk you through it. This is the actual workflow, not a simplified version.

### Step 1: Set up the cluster (2 minutes)

```bash
git clone https://github.com/23seriy/kratix-in-action.git
cd kratix-in-action
./scripts/01-install-prerequisites.sh
./scripts/02-start-cluster.sh
```

One command creates a Minikube cluster, installs cert-manager, installs Kratix, deploys MinIO as the state store, and registers the cluster as a Destination.

**Two minutes. From nothing to a functioning platform.**

### Step 2: Create your first Promise (5 seconds)

This is the heart of Kratix. A Promise defines three things:

1. **An API** — what fields developers can set (service name, port, team, environment)
2. **A pipeline** — containers that transform the request into Kubernetes resources
3. **Scheduling** — where the resources get deployed

```bash
kubectl apply -f kratix/promises/nba-service-promise.yaml
kubectl get promises
```

```
NAME          STATUS      AGE
nba-service   Available   5s
```

**That's it.** Your platform now offers "NBA Service" as a self-service capability. Developers can see it. They can request it. They don't need to know what happens behind the curtain.

### Step 3: A developer requests a service (30 seconds to running)

Here's the moment that changes everything. A developer writes this:

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

1. **Validates** the request against the Promise's schema
2. **Runs the pipeline** — a Go container generates a Deployment, Service, and ConfigMap with security contexts, resource limits, and standard labels
3. **Schedules** the resources to the worker Destination
4. **Deploys** everything automatically

The developer didn't write a single line of Kubernetes YAML beyond the request. No security contexts. No resource limits. No label conventions. **The platform handled all of it.**

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

Let that sink in. The same thing that took 3 days and 4 hours of human effort now takes 30 seconds and zero human intervention.

---

## The Pipeline: This Is Where the Real Magic Lives

The Promise gets all the attention. But the pipeline is where platform engineering *actually* happens.

Think of it this way: the Promise is the menu. The pipeline is the kitchen.

In my demo, the pipeline container is written in Go. When a resource request arrives, it:

1. Reads the request from `/kratix/input/object.yaml`
2. Generates a **Deployment** with:
   - `runAsNonRoot: true`
   - `readOnlyRootFilesystem: true`
   - CPU/memory requests and limits
   - Standard `app.kubernetes.io/*` labels
3. Generates a **Service** matching the requested port
4. Generates a **ConfigMap** with environment-specific configuration
5. Writes everything to `/kratix/output/`

Every service that passes through this pipeline automatically gets security hardening, resource governance, and consistent labeling.

**No developer effort. No ops tickets. No exceptions. No "oh, we forgot the security context on that one."**

And here's the part that made me stop and think: *when you update the pipeline, every service gets the new standards
on re-request.* Changed your labeling convention? Updated your security policy? Added a monitoring sidecar?
Just update the pipeline. Zero migration scripts. Zero "can you update all 47 services" tickets.

---

## Compound Promises: The Feature That Sold Me

Individual Promises are useful.

Compound Promises are *transformative.*

Here's the scenario: a developer needs a service *and* a database. At most companies, that's:

- Ticket #1: "I need a service"
- Ticket #2: "I need a database"
- Ticket #3: "Can someone wire them together?"
- Follow-up Slack thread: "The connection string is wrong"
- Another ticket: "Actually, can we change the DB size?"

With a Compound Promise, it's one request:

```bash
kubectl apply -f kratix/promises/nba-platform-promise.yaml
kubectl apply -f kratix/requests/full-stack-request.yaml
```

The platform provisions the service, provisions PostgreSQL, and wires them together. One request. One command. Done.

**This is what "golden path" actually means** — not a wiki page titled
"How to Deploy a Service (Updated 6 Months Ago, May Be Wrong)."
It's an automated, tested, self-service workflow that does the right thing every time.

---

## Break Things on Purpose (This Is the Part Most Tutorials Skip)

Here's what separates this project from every other "Getting Started with Kratix" tutorial you've read:

**I intentionally built three broken scenarios.**

Why? Because I've spent enough years in ops to know that *real platform engineering is mostly debugging.* The happy path is the demo. The sad path is the job.

### 🔥 Scenario 1: Broken Pipeline

```bash
kubectl apply -f kratix/broken/broken-pipeline-promise.yaml
kubectl apply -f kratix/broken/broken-pipeline-request.yaml
```

The pipeline container image doesn't exist. The pod gets stuck in `ImagePullBackOff`. This is the most common Kratix failure mode, and most engineers see it for the first time in production.

You learn to diagnose it:

```bash
kubectl get pods -n kratix-demo -l kratix.io/promise-name=broken-pipeline
kubectl describe pod <pod-name> -n kratix-demo
```

### 🔥 Scenario 2: Missing Destination

The Promise targets a "production" Destination that doesn't exist. Resources are generated but never delivered. Everything *looks* fine — no errors, no crashes — but nothing actually deploys.

This is the sneakiest failure in Kratix. You learn to check destination registration and label matching.

### 🔥 Scenario 3: Invalid Request

The request violates the schema — missing required fields, port out of range. The Kubernetes API rejects it immediately with a validation error.

This one's easy to fix, but new users panic when they see it. You learn to read validation errors calmly.

**These aren't edge cases. These are Tuesday.** If you're building a platform and haven't practiced debugging these failures, you're not ready for production.

---

## "But What About Crossplane / Backstage / Our Custom Scripts?"

This question comes up every time I present this. Here's the honest answer:

| Tool | What It Does | When to Choose It |
| ------ | ------------- | ---------------- |
| **Crossplane** | Provisions cloud resources via Kubernetes CRDs | You need to manage AWS/GCP/Azure resources declaratively |
| **Backstage** | Developer portal with service catalog and templates | You need a UI for discoverability and documentation |
| **Kratix** | Self-service platform APIs with pipeline-based fulfillment | You need to encode org standards into automated workflows |
| **Custom scripts** | Whatever you duct-tape together | You enjoy 2 AM pages. Please don't. |

Here's the thing people miss: **these tools aren't competitors. They're layers.**

Kratix handles the *fulfillment layer* — what happens after someone requests a resource. That pipeline can trigger
Crossplane compositions, Helm releases, Terraform runs, or plain Kubernetes manifests.
Backstage can sit in front as the developer portal.

But if you're starting from scratch and can only pick one tool to begin building a platform?

**Start with Kratix.** It solves the hardest problem first: turning tribal knowledge and organizational standards into automated, self-service workflows.

Everything else is UI and orchestration on top.

---

## 7 Things I Wish Someone Told Me Before I Started

After building this project, here's what I'd tell past-me:

**1. Your Promise API is your platform's contract.**
It defines what developers can request and how the platform fulfills it. Spend time on the API design.
If the API is intuitive, adoption follows naturally. If it's confusing, no amount of documentation will save you.

**2. Pipelines are the real product.**
Every org has standards — security contexts, resource limits, label conventions, monitoring. Pipelines encode them once and enforce them everywhere. Your pipeline *is* your platform.

**3. Self-service eliminates an entire category of work.**
Once a Promise exists, developers don't need ops. They `kubectl apply` and move on. No tickets, no Slack threads, no "when will my service be ready?" The platform just works.

**4. Compound Promises are the golden path.**
"I need a service with a database" becomes one request. The platform handles the wiring. This is where developer experience goes from "nice" to "I'm never going back."

**5. Platform evolution doesn't break consumers.**
Update a pipeline to add new security policies. Existing services get them on re-request. No migration scripts. No coordinated rollouts. No "please update your Helm chart."

**6. Practice debugging *before* production.**
Pipeline failures, missing destinations, schema violations — these are the daily reality of platform engineering.
Build a muscle for diagnosing them. The broken scenarios in this repo are a training ground.

**7. Start small. Ship fast. Iterate.**
Don't try to build the entire platform in one sprint. Ship one Promise. Get feedback. Add another. The best platforms are built incrementally, not designed in committee.

---

## Try It Right Now (Seriously, It Takes 20 Minutes)

Everything in this article is backed by working code you can run on your laptop:

```bash
git clone https://github.com/23seriy/kratix-in-action.git
cd kratix-in-action
./scripts/01-install-prerequisites.sh
./scripts/02-start-cluster.sh
./scripts/03-deploy-app.sh
./scripts/04-demo-scenarios.sh
```

**20 minutes. 10 interactive scenarios. Zero cloud costs.**

The repo includes documentation, troubleshooting guides, and CI/CD workflows. It's designed to be forked, modified, and used as a starting point for your own platform.

If it helps you, [star the repo](https://github.com/23seriy/kratix-in-action). It helps others find it.

---

## What's Coming Next

I'm extending this project with:

- **GitOps integration** — Flux/ArgoCD replacing MinIO as the state store
- **Multi-cluster scheduling** — separate platform and worker clusters
- **Monitoring Promise** — auto-inject Prometheus ServiceMonitor and Grafana dashboards
- **RBAC and multi-tenancy** — different teams, different Promises, different permissions

**Follow me here on Medium or [on GitHub](https://github.com/23seriy) to get updates.**

If you're building an internal developer platform — or even just thinking about it — Kratix is worth
an afternoon of your time. It's the closest thing I've found to a framework that makes
platform-as-a-product practical, not theoretical.

**The best platform is the one developers actually use.** Make it self-service, or watch them route around you.

---

*Sergei Olshanetski is a Staff DevOps Engineer who has spent too many years watching tickets sit in queues.
He builds platforms that make developers faster and ops engineers less stressed.
Find him on [GitHub](https://github.com/23seriy).*

---

## Medium Publishing Notes

**Title Options** (A/B test with friends before publishing):

1. I Replaced Our Entire Ticketing System With 4 Lines of YAML *(curiosity gap — "how?")*
2. Stop Building Platforms With Jira Tickets. There's a Better Way. *(direct challenge)*
3. The Open-Source Tool That Turns Kubernetes Into a Self-Service Platform *(benefit-driven)*

**Subtitle**: How Kratix Promises turned "file a Jira ticket and wait 3 days" into kubectl apply — and why your platform team should care

**Tags** (pick 5 — optimized for discoverability):

1. Platform Engineering
2. Kubernetes
3. DevOps
4. Software Engineering
5. Developer Experience

**Publications to submit to** (ordered by acceptance likelihood and audience fit):

1. **ITNEXT** — strong Kubernetes/DevOps readership, high acceptance rate for quality tutorials
2. **Better Programming** — largest dev publication, harder to get into but massive reach
3. **DevOps.dev** — niche but exactly the right audience
4. **Towards Dev** — growing publication, good for first-time submitters
5. **Level Up Coding** — wide developer audience, accepts hands-on tutorials

**Medium Best Practices Applied**:

- **Hook in first 3 lines** — story-driven opening that creates empathy
- **Reading time: ~13 minutes** — within Medium's 7-15 minute sweet spot for engagement
- **Subheadings every 200-300 words** — scannable structure for mobile readers
- **Bold key sentences** — readers who skim still get the core message
- **Emotional resonance** — "sound familiar?" and "be honest" create connection
- **Comparison table** — high-save, high-highlight content (boosts distribution)
- **Numbered list of lessons** — most-highlighted section type on Medium
- **Clear CTA at the end** — star the repo, follow on Medium/GitHub
- **Short paragraphs** — 1-3 sentences max, optimized for mobile reading
- **Code blocks interspersed** — breaks up text, adds credibility, attracts technical readers
- **Strategic use of horizontal rules** — creates visual breathing room between sections
- **"Try It Right Now" section** — converts readers into users

**SEO keywords included naturally**:

- platform engineering (5x)
- internal developer platform (3x)
- Kratix (15x)
- self-service (6x)
- developer experience (2x)
- platform as a product (2x)
- Kubernetes CRD (implicit through code)
- golden path (2x)
- kubectl apply (5x)

**Social media snippets for promotion**:

- Twitter/X: "We replaced our ticketing system with 4 lines of YAML. Here's how Kratix turns Kubernetes into a self-service platform. [link] 🧵"
- LinkedIn: "3 days and 4 hours of human effort to deploy a microservice. Or 30 seconds with zero human intervention. I built an open-source demo to show the difference. [link]"
- Reddit (r/kubernetes, r/devops): "I built an open-source project demonstrating Kratix for self-service
platform engineering — includes intentionally broken scenarios for learning to debug. Feedback welcome. [link]"
- Hacker News: "Show HN: kratix-in-action – hands-on self-service platform engineering with Kratix, Minikube, and NBA microservices [link]"

**Featured image**: Split-screen showing a Jira ticket queue on the left vs. a terminal with `kubectl apply` on the right, with a stopwatch showing "3 days → 30 seconds"
