# Troubleshooting Guide

## Installation & Prerequisites

### "command not found: minikube" or "command not found: kubectl"

```bash
chmod +x scripts/01-install-prerequisites.sh
./scripts/01-install-prerequisites.sh
```

Or manually: `brew install minikube kubectl helm`

### "Docker Desktop is not running"

Start Docker Desktop: `open /Applications/Docker.app`

### "Minikube failed to start"

Minikube needs ~8GB RAM. Check memory: `sysctl hw.memsize | awk '{print $2/1024/1024/1024 " GB"}'`

Fix: Close unused apps, reduce Docker Desktop memory, or run `./scripts/05-teardown.sh` first.

---

## Cluster Setup Issues

### "Kratix installation failed"

```bash
# Check if the Kratix manifest is accessible
curl -sL https://github.com/syntasso/kratix/releases/latest/download/kratix.yaml | head -5

# Check cluster resources
kubectl get pods -n kratix-platform-system
kubectl get events -n kratix-platform-system --sort-by=.metadata.creationTimestamp | tail -20
```

**Fix:** Delete and reinstall:

```bash
kubectl delete --filename https://github.com/syntasso/kratix/releases/latest/download/kratix.yaml
./scripts/02-start-cluster.sh
```

### "MinIO not starting"

```bash
kubectl get pods -n kratix-demo -l app=minio
kubectl describe pod -n kratix-demo -l app=minio
kubectl logs -n kratix-demo -l app=minio --tail=20
```

Common cause: Insufficient memory. MinIO needs ~128MB.

---

## Promise Issues

### "Promise not creating CRD"

```bash
kubectl get promises
kubectl describe promise <name>
kubectl get crd | grep kratix
```

Check Kratix controller logs:

```bash
kubectl logs -n kratix-platform-system deploy/kratix-platform-controller-manager --tail=30
```

### "Promise stuck in pending state"

```bash
kubectl get promises -o wide
kubectl describe promise <name>
```

Common causes:

- Kratix controller not running
- Invalid Promise YAML (check `spec.api` section)

---

## Pipeline Issues

### "Pipeline pod stuck in ImagePullBackOff"

```bash
kubectl get pods -n kratix-demo -l kratix.io/promise-name=<promise-name>
kubectl describe pod -n kratix-demo -l kratix.io/promise-name=<promise-name>
```

The pipeline container image doesn't exist or can't be pulled.

**Fix:** Build the image and load it into Minikube:

```bash
eval "$(minikube -p kratix-demo docker-env)"
docker build -t kratix-demo/nba-pipeline:latest apps/pipeline
```

### "Pipeline pod completed but no resources generated"

```bash
# Check pipeline logs
kubectl logs -n kratix-demo -l kratix.io/pipeline-name=configure --tail=30

# Check if output was written
kubectl get deploy,svc -n kratix-demo -l app.kubernetes.io/managed-by=kratix
```

Common causes:

- Pipeline wrote to wrong output directory (must be `/kratix/output`)
- Pipeline crashed silently (check exit code)
- Input parsing failed (check `/kratix/input/object.yaml` format)

### "Pipeline runs but resources don't appear on worker"

```bash
# Check Destination
kubectl get destinations
kubectl describe destination worker

# Check State Store
kubectl get bucketstatestores
kubectl describe bucketstatestore default

# Check MinIO has the resources
kubectl port-forward svc/minio 9000:9000 -n kratix-demo
# Open http://localhost:9000 (minioadmin/minioadmin)
```

Common causes:

- No Destination registered
- Destination labels don't match Promise's destinationSelectors
- MinIO credentials wrong in BucketStateStore Secret

---

## Resource Request Issues

### "Request rejected by API validation"

```bash
kubectl apply -f kratix/requests/<request>.yaml 2>&1
```

Read the error message — it tells you which fields are invalid.
Common issues:

- Missing required fields (e.g., `team`)
- Value out of range (e.g., port < 1024)
- Value not in enum (e.g., invalid environment)

**Fix:** Update the request YAML to match the Promise schema.

### "Request accepted but nothing happens"

```bash
# Check resource request status
kubectl get nbaservices -n kratix-demo
kubectl describe nbaservice <name> -n kratix-demo

# Check pipeline pods
kubectl get pods -n kratix-demo -l kratix.io/promise-name=nba-service

# Check Kratix controller
kubectl logs -n kratix-platform-system deploy/kratix-platform-controller-manager --tail=30
```

---

## App Deployment Issues

### "Error building Docker image"

```bash
# Ensure you're using Minikube's Docker daemon
eval "$(minikube -p kratix-demo docker-env)"

# Build manually
docker build -t kratix-demo/scoreboard-api:latest apps/scoreboard-api
```

### "ImagePullBackOff" or "ErrImageNeverPull"

Images use `imagePullPolicy: Never` (built locally):

```bash
eval "$(minikube -p kratix-demo docker-env)"
docker build -t kratix-demo/scoreboard-api:latest apps/scoreboard-api
kubectl rollout restart deployment/scoreboard-api -n kratix-demo
```

---

## Cleanup & Removal

### "Teardown script failed"

```bash
# Manual cleanup
kubectl delete nbaservices --all -n kratix-demo --ignore-not-found=true
kubectl delete postgresqls --all -n kratix-demo --ignore-not-found=true
kubectl delete promises --all --ignore-not-found=true
kubectl delete destinations --all --ignore-not-found=true
kubectl delete --filename https://github.com/syntasso/kratix/releases/latest/download/kratix.yaml --ignore-not-found=true
minikube delete -p kratix-demo
```

### "Cluster is stuck in a weird state"

Nuclear option:

```bash
minikube delete -p kratix-demo --purge
```

Then start fresh: `./scripts/02-start-cluster.sh`

---

## Quick Reference

| Issue | Command |
|-------|---------|
| Kratix logs | `kubectl logs -n kratix-platform-system deploy/kratix-platform-controller-manager --tail=50` |
| All Promises | `kubectl get promises` |
| All Destinations | `kubectl get destinations` |
| Pipeline pods | `kubectl get pods -n kratix-demo -l kratix.io/promise-name=<name>` |
| Pipeline logs | `kubectl logs -n kratix-demo -l kratix.io/pipeline-name=configure --tail=30` |
| Resource requests | `kubectl get nbaservices,postgresqls -n kratix-demo` |
| MinIO console | `kubectl port-forward svc/minio 9000:9000 -n kratix-demo` |
| Delete cluster | `minikube delete -p kratix-demo` |

---

Still stuck? Check the [Kratix docs](https://kratix.io/docs/) or open an issue! 🏗️
