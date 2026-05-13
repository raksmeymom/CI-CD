# SaaS App — CI/CD Pipeline

A production-grade CI/CD pipeline for a SaaS application using GitHub Actions, Helm, and AWS EKS.

## Project structure

```
cicd-saas/
├── .github/workflows/       # GitHub Actions pipelines
│   ├── ci-cd.yml            # Main pipeline (build → test → security → deploy)
│   ├── pr-validation.yml    # PR checks + preview environments
│   └── scheduled.yml        # Nightly backups, dep audits, load tests
├── helm/                    # Kubernetes Helm chart
│   ├── saas-app/            # Chart definition + templates
│   └── values/              # Per-environment values
├── k8s/                     # Raw Kubernetes manifests
│   ├── namespace.yaml
│   └── secrets.yaml
├── scripts/                 # Helper shell scripts
│   ├── smoke-test.sh        # Post-deploy smoke tests
│   ├── monitor-canary.sh    # Canary health monitoring
│   ├── wait-for-healthy.sh  # Readiness polling
│   └── prune-old-snapshots.sh
├── tests/
│   ├── unit/                # Jest unit tests
│   ├── integration/         # API integration tests
│   └── e2e/                 # Playwright end-to-end tests
├── Dockerfile               # Multi-stage production Docker build
├── docker-compose.test.yml  # Local test environment
├── renovate.json            # Automated dependency updates
└── SECRETS.md               # Required GitHub secrets reference
```

## Pipeline stages

| Stage             | Trigger             | What runs                       |
| ----------------- | ------------------- | ------------------------------- |
| Build             | Every push/PR       | Docker build, lint, type-check  |
| Unit tests        | Every push/PR       | Jest with coverage              |
| Integration tests | Every push/PR       | API tests with real DB + Redis  |
| E2E tests         | PR + staging branch | Playwright browser tests        |
| Security scan     | After tests pass    | Snyk, Trivy, TruffleHog, CodeQL |
| Deploy staging    | Push to `staging`   | Helm deploy + smoke tests       |
| Deploy production | Push to `main`      | Canary (10%) → full rollout     |

## Getting started

### 1. Add GitHub secrets

See `SECRETS.md` for the full list.

### 2. Create Kubernetes namespaces

```bash
kubectl apply -f k8s/namespace.yaml
```

### 3. Create secrets in each namespace

```bash
# Edit k8s/secrets.yaml with real values first
kubectl apply -f k8s/secrets.yaml -n production
kubectl apply -f k8s/secrets.yaml -n staging
```

### 4. Push to staging branch to trigger your first deploy

```bash
git checkout -b staging
git push origin staging
```

## Local development

Run the full test environment locally:

```bash
docker compose -f docker-compose.test.yml up
```

Run tests:

```bash
npm run test:unit
npm run test:integration
npm run test:e2e
```
