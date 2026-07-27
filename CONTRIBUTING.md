# Contributing to kratix-in-action

Thank you for your interest in contributing! This project aims to be a clear,
educational demonstration of Kratix's platform engineering capabilities.
Whether you're fixing a bug, improving documentation, or adding new scenarios,
we appreciate your help.

## Getting Started

1. **Fork and clone** the repository
2. **Create a feature branch** from `main`: `git checkout -b feature/your-feature`
3. **Make your changes** and test them thoroughly
4. **Submit a pull request** with a clear description

## Code of Conduct

This project adheres to a Code of Conduct. Please review [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) before participating.

## Development Workflow

### Before You Start

- Ensure you have the prerequisites installed: Docker Desktop, Minikube, and macOS (scripts use Homebrew)
- Familiarity with Kubernetes and Kratix concepts is helpful but not required

### Testing Your Changes

For **script changes**:

```bash
chmod +x scripts/*.sh
./scripts/02-start-cluster.sh
./scripts/03-deploy-app.sh
./scripts/04-demo-scenarios.sh
./scripts/05-teardown.sh
```

For **Promise changes**:

```bash
kubectl apply -f kratix/promises/<promise>.yaml --dry-run=client -o yaml
```

For **Go code changes** (pipeline):

```bash
cd apps/pipeline
go vet ./...
go build -o /dev/null .
```

For **manifest changes**:

- Update the corresponding YAML in `k8s/` or `kratix/`
- Run the full demo to ensure nothing breaks

### Shell Script Standards

All shell scripts should:

- Start with `#!/usr/bin/env bash` and `set -euo pipefail`
- Use the project's `info()`, `warn()`, and `header()` helper functions for output
- Include descriptive comments for complex logic
- Pass `shellcheck` without warnings (run `shellcheck scripts/*.sh`)

### Kratix Resource Standards

All resources in `kratix/` should:

- Have clear metadata names that describe the resource's purpose
- Use consistent labels (e.g., `demo: kratix-in-action`)
- Include `app.kubernetes.io/managed-by: kratix` on generated resources
- Reference the correct Destination for the target environment
- Broken resources should follow the naming pattern: `broken-<failure-mode>.yaml`

### Documentation Standards

- Keep the README.md up-to-date with the latest Kubernetes and Kratix versions
- Document new scenarios in the "Demo Scenarios" section
- Update CLAUDE.md if adding architectural concepts
- Use clear, jargon-free language where possible

## Reporting Issues

### Security Vulnerabilities

**Do not** open a public issue for security vulnerabilities. Please review [SECURITY.md](SECURITY.md) for responsible disclosure.

### Bugs and Feature Requests

Use GitHub Issues with:

- **Clear title**: "Script fails on Minikube M1" is better than "Something broken"
- **Steps to reproduce**: Exact commands and cluster state
- **Expected vs. actual behavior**
- **Environment**: macOS version, Minikube version, Kubernetes version, Kratix version

## Pull Request Process

1. **Update tests** if you change functionality
2. **Run the full demo** and confirm all scenarios pass
3. **Check with `shellcheck`**: `shellcheck scripts/*.sh`
4. **Check Go code**: `cd apps/pipeline && go vet ./...`
5. **Update docs** if behavior changes
6. **Write a clear PR description** explaining *why* the change is needed

### PR Title Convention

Use the format: `[type] short description`

Types:

- `[docs]` — Documentation-only changes
- `[fix]` — Bug fixes
- `[feature]` — New scenarios or Promises
- `[refactor]` — Code cleanup without behavior change
- `[ci]` — CI/CD workflow changes

Example: `[feature] add Redis caching Promise`

## Project Goals & Philosophy

This project demonstrates Kratix through **hands-on examples**, not exhaustive
feature coverage. When contributing:

- **Prefer clarity over cleverness** — a simple Promise is more educational than a complex one
- **Each scenario should teach one thing** — avoid mixing multiple concepts in a single scenario
- **Test scripts must be reproducible** — they should work the same way on any macOS machine with prerequisites installed
- **Include both happy-path and troubleshooting** — real-world platform engineering includes debugging

## Recognition

Contributors will be recognized in:

- The project README's acknowledgments section (if you'd like)
- Individual commit history via GitHub

## Questions?

Open a discussion or an issue if you're unsure about anything. We're here to help!

---

Thank you for helping make kratix-in-action a better learning resource. 🏗️
