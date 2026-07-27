# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in kratix-in-action, please **do not** open a public GitHub issue. Instead, please report it responsibly by emailing [23seriy@gmail.com](mailto:23seriy@gmail.com) with:

- A description of the vulnerability
- Steps to reproduce it
- Potential impact
- Any suggested fixes (if you have them)

**Please do not disclose the vulnerability publicly until we've had time to address it.**

We will:
1. Acknowledge receipt of your report within 48 hours
2. Provide a timeline for a fix
3. Work with you on the patch if needed
4. Coordinate a disclosure date with you
5. Credit you in the security advisory (unless you prefer anonymity)

## Scope

This security policy covers the kratix-in-action repository itself. It does **not** cover:

- **Kratix itself** — please report Kratix vulnerabilities to the [Kratix project](https://github.com/syntasso/kratix/security)
- **Kubernetes** — please report Kubernetes vulnerabilities through their [security disclosure process](https://kubernetes.io/security/)
- **MinIO** — please report MinIO vulnerabilities to [MinIO](https://github.com/minio/minio/security)

## What We Fix

We consider the following as potential security issues:

- **Credential leakage** (e.g., real cloud keys in git history or manifests)
- **Code injection** in scripts (shell) or pipeline containers (Go)
- **Insecure defaults** that could lead to unintended resource exposure
- **Container security** (running as root, missing security contexts)
- **Supply chain risks** in the Go application or Docker build

We do **not** consider the following as security issues (please file them as bugs instead):

- Demo scenarios that intentionally break things (the point of this project)
- Kratix controller vulnerabilities (report to Syntasso)
- Kubernetes API vulnerabilities (report to Kubernetes)

## Security Best Practices When Using This Project

### For Demo/Learning Environments

- **Use Minikube, not production clusters** — this project is a demo, not a production-hardened system
- **Run in isolated networks** — don't expose the Minikube cluster to the internet
- **Use MinIO demo credentials** — the `minioadmin`/`minioadmin` credentials are for the demo only
- **Clean up after demos** — run `./scripts/05-teardown.sh` to delete the test cluster

### For Extending to Production

If you're using this project as a blueprint for production platform engineering:

- **Use proper secrets management** — not plaintext credentials in Secrets
- **Implement RBAC** — restrict who can create Promises vs. who can make requests
- **Use GitStateStore** — point to a real Git repo instead of MinIO for production
- **Enable audit logging** — track who creates which resource requests
- **Review all pipelines** — ensure pipeline containers are signed and from trusted registries
- **Multi-cluster setup** — separate platform cluster from worker clusters

## Known Security Considerations

### MinIO Credentials in This Project

The MinIO state store uses:
- Username: `minioadmin` / Password: `minioadmin`
- These are **MinIO default credentials** for the local demo
- They are stored in a Kubernetes Secret

For production, use proper secrets management (Vault, AWS Secrets Manager, etc.)

### Container Security in This Project

All containers in this project:
- Run as a non-root user (UID 10001)
- Use minimal base images (Alpine)
- Have multi-stage Docker builds (pipeline container)
- Include security contexts (runAsNonRoot, readOnlyRootFilesystem)

## Security Advisories

We will publish security advisories for any reported vulnerabilities that we confirm. Check the [GitHub Security Advisories](https://github.com/23seriy/kratix-in-action/security/advisories) page.

---

Thank you for helping keep kratix-in-action secure. 🏗️
