# Multi-Cloud CI/CD Pipeline with Automated Infrastructure Provisioning & Observability (AWS + GCP)

A production-style DevOps platform that provisions infrastructure across **AWS and Google Cloud Platform** from a single Terraform codebase, deploys containerized workloads through an automated CI/CD pipeline, and gives on-call engineers a unified, real-time view of system health across both clouds.

---

## Why this project exists

Most teams end up managing AWS and GCP with two separate toolchains, two sets of pipelines, and two monitoring stacks — which slows down releases and makes incident response harder. This project solves that by treating multi-cloud as a first-class design goal: one CI/CD pipeline, one IaC codebase, one dashboard, regardless of which cloud a service runs on.

## Architecture

```
                        ┌──────────────────────┐
                        │   GitHub Actions      │
                        │  (lint → test → scan  │
                        │  → build → deploy)    │
                        └──────────┬───────────┘
                                   │
                 ┌─────────────────┴─────────────────┐
                 │                                     │
        ┌────────▼─────────┐                 ┌─────────▼────────┐
        │   AWS (EKS)       │                 │   GCP (GKE)       │
        │  Terraform module │                 │  Terraform module │
        │  VPC / IAM / EC2  │                 │  VPC / IAM / GCE  │
        └────────┬─────────┘                 └─────────┬────────┘
                 │                                     │
                 └─────────────────┬───────────────────┘
                                   │
                        ┌──────────▼───────────┐
                        │  Prometheus + Grafana  │
                        │  Unified Observability │
                        └───────────────────────┘
```

## Key Features

- **Single Terraform codebase, two clouds** — modular Terraform provisions equivalent networking, IAM/RBAC, and Kubernetes cluster infrastructure on both AWS (EKS) and GCP (GKE), keeping environment drift close to zero.
- **One CI/CD pipeline, dual targets** — a single GitHub Actions workflow lints, tests, security-scans (Trivy), builds Docker images, and deploys to either or both clouds based on branch/tag triggers, with blue-green and canary rollout support.
- **Cross-cloud health automation** — Python and Bash scripts run scheduled health checks, capture system/pod metrics, and trigger automated remediation (pod restarts, scale-out) when thresholds are breached on either cloud.
- **Unified observability** — Prometheus scrapes both clusters and Grafana renders a single dashboard for latency, error rate, CPU/memory, and deployment frequency, so on-call engineers never have to context-switch between cloud consoles.
- **Reliability & security by design** — least-privilege IAM policies, encrypted state storage, and RBAC-scoped service accounts on both clouds.

## Tech Stack

| Layer | Tools |
|---|---|
| CI/CD | GitHub Actions, Trivy |
| IaC | Terraform (modular, remote state, multi-environment) |
| Compute / Orchestration | Docker, Kubernetes (EKS + GKE), Helm |
| Cloud Platforms | AWS (VPC, IAM, EC2, EKS), GCP (VPC, IAM, Compute Engine, GKE) |
| Monitoring | Prometheus, Grafana |
| Automation / Scripting | Python, Bash |

## Repository Structure

```
.
├── terraform/
│   ├── modules/
│   │   ├── aws/            # VPC, IAM, EKS node groups
│   │   └── gcp/             # VPC, IAM, GKE node pools
│   └── environments/
│       ├── staging/
│       └── production/
├── .github/workflows/
│   └── ci-cd.yml            # lint -> test -> scan -> build -> deploy
├── k8s/
│   ├── aws/
│   └── gcp/
├── monitoring/
│   ├── prometheus/
│   └── grafana/dashboards/
├── scripts/
│   ├── health_check.py
│   ├── metrics_snapshot.sh
│   └── auto_remediate.py
└── README.md
```

## Getting Started

```bash
# 1. Clone the repo
git clone https://github.com/cloudnash/multi-cloud-cicd-observability-platform.git
cd multi-cloud-cicd-observability-platform

# 2. Provision infrastructure (choose a cloud, or both)
cd terraform/environments/staging
terraform init
terraform plan -var-file="aws.tfvars"
terraform apply -var-file="aws.tfvars"

# 3. Deploy the monitoring stack
kubectl apply -f monitoring/prometheus/
kubectl apply -f monitoring/grafana/dashboards/

# 4. Push to a feature branch — GitHub Actions handles the rest
git push origin feature/my-change
```

## Impact

- Reduced manual provisioning steps for new environments by standardizing AWS and GCP infrastructure through shared Terraform modules.
- Cut mean time to detect (MTTD) cross-cloud issues by consolidating monitoring into a single Grafana view instead of two separate cloud consoles.
- Enabled safe, repeatable releases with blue-green/canary deployment support built directly into the pipeline.

## Roadmap

- [ ] Add OpenTelemetry-based distributed tracing across both clusters
- [ ] Extend auto-remediation scripts with Slack/webhook alerting
- [ ] Add cost-comparison reporting between AWS and GCP workloads

---

**Author:** Nashit Ahmad — [github.com/cloudnash](https://github.com/cloudnash) | [linkedin.com/in/nashitahmad](https://linkedin.com/in/nashitahmad)
