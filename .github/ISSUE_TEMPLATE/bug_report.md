---
name: Bug Report
about: Report something that isn't working as expected
title: "[BUG] "
labels: bug
assignees: ''

---

## Description

<!-- A clear and concise description of what the bug is -->

## Steps to Reproduce

<!-- Exact steps to reproduce the behavior -->

1. Run `...`
2. Apply `...`
3. Observe `...`

## Expected Behavior

<!-- What should happen? -->

## Actual Behavior

<!-- What actually happens? -->

## Environment

- **OS**: <!-- e.g., macOS 14.0 -->
- **Minikube Version**: <!-- output of `minikube version` -->
- **Kubernetes Version**: <!-- output of `kubectl version --short` -->
- **Docker Desktop Version**: <!-- if using Docker Desktop -->

## Error Messages or Logs

<!-- Paste any error messages or relevant log output -->

```
Paste logs here
```

## Diagnostics

<!-- Run these commands and share the output if applicable -->

```bash
kubectl get promises
kubectl get destinations
kubectl get pods -n kratix-platform-system
kubectl logs -n kratix-platform-system deploy/kratix-platform-controller-manager --tail=50
minikube logs -p kratix-demo --tail=50
```
