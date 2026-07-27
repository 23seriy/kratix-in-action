# Project Governance

## Overview

kratix-in-action is a community-driven educational project demonstrating
Kratix's platform engineering capabilities. This document outlines how we
make decisions, manage contributions, and maintain the project.

## Project Goals

1. **Educate** — Provide clear, hands-on examples of Kratix Promises, pipelines, and Destinations
2. **Demonstrate** — Show real platform engineering workflows and troubleshooting that users can adapt
3. **Empower** — Enable users to build their own internal developer platforms with Kratix
4. **Maintain Quality** — Keep code, docs, and scripts clean and consistent

## Maintainers

The project is maintained by:

- **Sergei Olshanetski** (@23seriy) — Creator and primary maintainer

Maintainers handle:

- Reviewing pull requests
- Merging approved changes
- Managing releases
- Setting project direction
- Enforcing code standards

## Contributing

We welcome contributions! See [CONTRIBUTING.md](../CONTRIBUTING.md) for:

- How to get started
- Development workflow
- Testing requirements
- PR conventions

## Decision Making

### Minor Changes (Docs, Bug Fixes, Tests)

- Open a PR with a clear description
- At least one maintainer approval needed
- CI checks must pass

### Major Changes (New Features, Architecture)

- Open an issue or discussion first
- Get feedback from maintainers
- Then open a PR
- Allow 3-5 days for community feedback

### Breaking Changes

- Only in major version bumps
- Clearly documented in CHANGELOG
- Community discussion encouraged

## Release Process

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR** — Breaking changes
- **MINOR** — New features (new Promises, scenarios)
- **PATCH** — Bug fixes

## Code Standards

All contributions must:

- Pass `shellcheck` (shell scripts)
- Pass `yamllint` (YAML files)
- Build successfully with `go vet` and `go build` (Go code)
- Include clear commit messages: `[type] description`

## Code of Conduct

All participants must follow the [CODE_OF_CONDUCT.md](../CODE_OF_CONDUCT.md).

## Licensing

All contributions are licensed under [MIT](../LICENSE). By submitting a PR, you agree to this license.

---

Questions about governance? Open an issue or discussion! 🏗️
