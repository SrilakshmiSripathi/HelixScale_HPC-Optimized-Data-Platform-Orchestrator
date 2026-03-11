# Claude.md — HelixScale: BioNemo HPC Orchestration Showcase

## Project Identity

**Name:** HelixScale — BioNemo HPC Orchestration Showcase
**Type:** Production-grade portfolio project demonstrating full-stack HPC platform engineering
**Goal:** Prove ability to design, automate, and operate GPU-accelerated HPC infrastructure for computational biology workloads (BioNeMo-class)

## Architecture Philosophy

This is a **tiered deployment** project. Every component must work across three tiers:

| Tier | Environment | GPU | Scheduler | Infra |
|------|-------------|-----|-----------|-------|
| T0 — Local | macOS 64GB (M-series) | Simulated (CPU fallback) | Mini-Slurm (Docker) | Docker Compose + UV |
| T1 — Cloud | AWS/GCP GPU instances | Real (A100/H100) | Slurm or K8s | Terraform-provisioned |
| T2 — HPC Cluster | On-prem or cloud HPC | Real (multi-node) | Slurm + Altair SGE | Ansible-configured |

**Key Tradeoff Decision:** We use **Slurm as the primary scheduler** (industry standard for HPC/bio) with Altair Grid Engine as a secondary target. Kubernetes is the orchestration layer *around* the cluster, not a replacement for the batch scheduler.

## Tech Stack (Pinned)

### Core Languages
- **Python 3.12+** — all application code, job orchestration, monitoring
- **Bash** — bootstrap scripts, scheduler wrappers, health checks
- **HCL (Terraform)** — cloud infrastructure provisioning
- **YAML** — Ansible playbooks, K8s manifests, CI/CD

### Infrastructure & Orchestration
- **Terraform** — AWS/GCP infra (VPC, compute, storage, networking)
- **Ansible** — cluster config management (Slurm, drivers, mounts, users)
- **Docker** — containerized workloads, dev environments
- **Apptainer (Singularity)** — HPC-native containers (no root, MPI-aware)
- **Kubernetes (K3s for T0, EKS/GKE for T1)** — service orchestration layer
- **Slurm** — primary batch scheduler
- **Altair Grid Engine** — secondary scheduler (compatibility layer)

### GPU & Compute
- **NVIDIA BioNeMo** — reference workload (protein folding inference)
- **CUDA Toolkit** — GPU runtime
- **NCCL** — multi-GPU communication
- **nvidia-container-toolkit** — container GPU passthrough

### DevOps & CI/CD
- **GitHub Actions** — CI/CD pipelines
- **Chef (InSpec)** — compliance-as-code for cluster validation
- **Pre-commit** — linting, formatting, security scanning

### Monitoring & Observability
- **Prometheus + Grafana** — cluster & GPU metrics
- **DCGM Exporter** — NVIDIA GPU telemetry
- **Loki** — log aggregation
- **Custom Python exporters** — Slurm job metrics

### Python Toolchain
- **UV** — package management and virtual environments
- **Ruff** — linting + formatting
- **Pytest** — testing
- **Typer** — CLI framework
- **Rich** — terminal UI

## Directory Structure

```
helixscale/
├── Claude.md
├── spec.md
├── INSTRUCTIONS.md
├── pyproject.toml
├── Makefile
│
├── src/helixscale/
│   ├── __init__.py
│   ├── cli/                     # Typer CLI commands
│   │   ├── cluster.py           # Cluster lifecycle
│   │   ├── jobs.py              # Job submission/monitoring
│   │   └── infra.py             # Terraform/Ansible wrappers
│   ├── orchestrator/            # Job orchestration engine
│   │   ├── scheduler.py         # Slurm/SGE abstraction
│   │   ├── pipeline.py          # Multi-stage job pipelines
│   │   └── gpu_allocator.py     # GPU-aware resource allocation
│   ├── monitoring/              # Observability
│   │   ├── exporters.py         # Custom Prometheus exporters
│   │   ├── gpu_metrics.py       # DCGM integration
│   │   └── dashboard.py         # Grafana dashboard generator
│   └── utils/
│       ├── config.py            # Tier-aware configuration
│       └── containers.py        # Docker/Apptainer helpers
│
├── infra/
│   ├── terraform/
│   │   ├── modules/             # vpc/, compute/, storage/, scheduler/
│   │   ├── environments/        # dev/, prod/
│   │   └── backend.tf
│   ├── ansible/
│   │   ├── inventory/
│   │   ├── playbooks/           # slurm, gpu_drivers, storage, monitoring
│   │   └── roles/               # slurm_controller, slurm_compute, nvidia_gpu, apptainer
│   └── chef/inspec/             # Compliance profiles
│
├── containers/
│   ├── Dockerfile.bionemo       # BioNeMo inference
│   ├── Dockerfile.orchestrator  # Orchestrator service
│   ├── apptainer/bionemo.def    # HPC-native container
│   └── docker-compose.yml       # T0 local stack
│
├── scheduler/
│   ├── slurm/
│   │   ├── slurm.conf.j2        # Jinja2 template
│   │   ├── gres.conf.j2         # GPU GRES config
│   │   ├── job_templates/       # SBATCH scripts
│   │   └── prolog.d/            # Node health checks
│   └── sge/                     # Altair Grid Engine configs
│
├── pipelines/
│   ├── ci/.github/workflows/    # lint, test, infra-plan, container-build
│   └── workloads/               # protein_folding.yaml, benchmarks.yaml
│
├── monitoring/
│   ├── prometheus/
│   ├── grafana/dashboards/      # cluster, gpu, job queue
│   └── alerting/
│
├── docs/
│   ├── architecture.md
│   ├── tradeoffs.md
│   └── runbook.md
│
└── tests/
    ├── unit/
    ├── integration/
    └── e2e/
```

## Coding Conventions

- Type hints on all function signatures
- Google-style docstrings (brief)
- Never swallow exceptions; log + re-raise or handle
- Pydantic Settings for config; tier-aware defaults
- Typer CLI with `--dry-run` on every destructive command
- Secrets via env vars or cloud secret managers only
- All IaC must be idempotent and re-runnable
- Unit tests mock externals; integration tests use T0 Docker stack

## Key Tradeoff Decisions

| Decision | Chosen | Alternative | Rationale |
|----------|--------|-------------|-----------|
| Scheduler | Slurm (primary) | K8s-only | HPC standard; gang scheduling, fairshare, preemption |
| HPC Containers | Apptainer | Docker on HPC | No root daemon, MPI native, Slurm integration |
| IaC | Terraform | Pulumi/CDK | HCL is JD requirement; HPC industry standard |
| Config Mgmt | Ansible + Chef/InSpec | Ansible-only | Ansible provisions, InSpec validates compliance |
| Local Dev | Docker Compose + UV | Vagrant/VMs | Lighter weight; UV is fast; multi-node simulation |
| GPU Alloc | GRES (Slurm native) | Custom allocator | Proven at scale; no reinvention |
| Monitoring | Prometheus stack | Datadog/CloudWatch | Open source; portable; DCGM exporter exists |
| Python Pkgs | UV | pip/poetry | 10-100x faster resolves; modern lockfile |

## Agent Rules

1. Check which tier (T0/T1/T2) every change affects
2. Run `make lint` before committing
3. Test T0 first — local must work before cloud
4. Use `--dry-run` on Terraform plans and Ansible runs
5. Document tradeoffs in `docs/tradeoffs.md`
6. Pin all container image versions; never `:latest`
7. GPU code paths always have CPU fallback with clear logging
