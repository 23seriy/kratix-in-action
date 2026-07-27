# Testing Guide

This document describes how to test kratix-in-action and validate changes
before submitting a pull request.

## Automated Testing

### Local Validation

Before pushing, run the validation suite locally:

```bash
# Check shell scripts
shellcheck -x scripts/*.sh

# Validate YAML
for file in k8s/*.yaml kratix/*.yaml kratix/promises/*.yaml kratix/requests/*.yaml kratix/broken/*.yaml; do
  kubectl apply -f "$file" --dry-run=client -o yaml > /dev/null 2>&1 && echo "✓ $file" || echo "✗ $file"
done

# Check Go code
cd apps/pipeline && go vet ./... && go build -o /dev/null . && cd ../..

# Lint Dockerfiles (if hadolint installed)
hadolint apps/scoreboard-api/Dockerfile
hadolint apps/stats-service/Dockerfile
hadolint apps/schedule-service/Dockerfile
hadolint apps/pipeline/Dockerfile
```

### GitHub Actions

The repository includes automated validation via GitHub Actions
(`.github/workflows/validate.yml`). Checks run on every push and pull request:

- **Shell linting** — `shellcheck` validates all scripts
- **YAML validation** — `yamllint` checks Kubernetes manifests and Kratix resources
- **Go build and vet** — Ensures pipeline container compiles and passes `go vet`
- **Dockerfile linting** — `hadolint` checks Dockerfiles
- **Documentation completeness** — Ensures all required files exist
- **Markdown linting** — Checks documentation formatting

## Manual Testing

### Full Demo Run

The most comprehensive test is running the full demo:

```bash
./scripts/01-install-prerequisites.sh
./scripts/02-start-cluster.sh
./scripts/03-deploy-app.sh
./scripts/04-demo-scenarios.sh
./scripts/05-teardown.sh
```

**Expected output:** All 10 scenarios complete with ✅ checks passing.

**Time:** ~20 minutes (depends on network speed for image downloads)

### Single Promise Test

Test a Promise in isolation:

```bash
# Validate YAML syntax
kubectl apply -f kratix/promises/nba-service-promise.yaml --dry-run=client -o yaml

# Apply and check
kubectl apply -f kratix/promises/nba-service-promise.yaml
kubectl get promises
```

### Component-Level Testing

#### Test the NBA APIs

```bash
kubectl port-forward svc/scoreboard-api 9080:8080 -n kratix-demo &

curl -s http://localhost:9080/health | python3 -m json.tool
curl -s http://localhost:9080/scores | python3 -m json.tool
curl -s http://localhost:9080/schedule | python3 -m json.tool
```

#### Test Pipeline Container

```bash
# Build and run locally with test input
cd apps/pipeline
go build -o pipeline .
mkdir -p /tmp/kratix-test/input /tmp/kratix-test/output
cat > /tmp/kratix-test/input/object.yaml <<EOF
apiVersion: demo.kratix.io/v1alpha1
kind: NBAService
metadata:
  name: test-service
  namespace: kratix-demo
spec:
  name: test-service
  port: 8080
  team: test-team
  environment: dev
EOF
# Note: pipeline expects /kratix paths — this is a structure check only
```

#### Test Kratix Controller

```bash
kubectl get pods -n kratix-platform-system
kubectl logs -n kratix-platform-system deploy/kratix-platform-controller-manager --tail=30
```

## Test Cases

### Core Functionality

| Test | Command | Expected Result |
|------|---------|-----------------|
| Install tools | `./scripts/01-install-prerequisites.sh` | All tools installed, versions printed |
| Start cluster | `./scripts/02-start-cluster.sh` | Minikube running, Kratix deployed, MinIO ready |
| Deploy app | `./scripts/03-deploy-app.sh` | All NBA services running |
| Run demo | `./scripts/04-demo-scenarios.sh` | All 10 scenarios pass |
| Cleanup | `./scripts/05-teardown.sh` | Cluster deleted |

### Kratix Resources

| Resource | Manifest | Expected |
|----------|----------|----------|
| Promise | `nba-service-promise.yaml` | Promise installed, CRD created |
| Request | `scoreboard-api-request.yaml` | Pipeline runs, resources generated |
| PostgreSQL | `postgresql-promise.yaml` | Promise installed, StatefulSet on request |
| Compound | `nba-platform-promise.yaml` | Both service and DB provisioned |

### Troubleshooting Scenarios

| Scenario | Manifest | Expected Failure | Lesson |
|----------|----------|------------------|--------|
| Bad Pipeline | `broken-pipeline-promise.yaml` | Pod stuck in ImagePullBackOff | Verify pipeline images |
| Missing Destination | `broken-no-destination-promise.yaml` | Resources not scheduled | Match destination labels |
| Invalid Request | `broken-invalid-request.yaml` | API validation rejects | Fix schema violations |

## Testing Checklist for Pull Requests

Before submitting a PR, ensure:

- [ ] `shellcheck -x scripts/*.sh` passes without warnings
- [ ] All YAML files validate with `--dry-run=client`
- [ ] Go code compiles: `cd apps/pipeline && go vet ./... && go build -o /dev/null .`
- [ ] Dockerfiles lint: `hadolint` passes (if available)
- [ ] Full demo runs: `./scripts/04-demo-scenarios.sh` completes all scenarios
- [ ] No regressions: all scenarios show expected results
- [ ] Documentation updated if behavior changed
- [ ] Commit messages follow convention: `[type] description`

---

Questions about testing? See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) or open an issue! 🏗️
