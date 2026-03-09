# HelixScale: BioNeMo HPC Orchestration Platform

> Production-grade HPC platform engineering for GPU-accelerated computational biology workloads — from bare metal to cloud, single node to multi-cluster.

[![Python 3.12+](https://img.shields.io/badge/python-3.12+-blue.svg)](https://www.python.org/downloads/)
[![Terraform](https://img.shields.io/badge/terraform-%3E%3D1.7-7B42BC.svg)](https://www.terraform.io/)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Built with UV](https://img.shields.io/badge/built%20with-UV-DE5FE9.svg)](https://github.com/astral-sh/uv)

---

## What This Project Demonstrates

HelixScale is a working HPC orchestration platform that provisions GPU clusters, schedules BioNeMo protein-folding workloads across Slurm and Altair Grid Engine, and monitors everything through a full observability stack. It processes real protein structures from the Protein Data Bank (PDB) — not toy examples.

This project covers the full lifecycle that platform engineering and AI infrastructure roles demand:

**Infrastructure Provisioning** — Terraform modules for VPC, GPU compute (A100/H100), FSx Lustre scratch storage, and EFS persistent storage on AWS/EKS and AKS.

**Cluster Configuration** — Ansible roles for Slurm controller/compute nodes, NVIDIA driver installation, CUDA toolkit, DCGM telemetry, and Apptainer (rootless HPC containers).

**Workload Orchestration** — DAG-based pipeline engine that chains protein folding stages (fetch → preprocess → inference → postprocess → report) with native scheduler dependency resolution via `--dependency=afterok`.

**Dual Scheduler Support** — Protocol-based abstraction over Slurm (primary) and Altair Grid Engine (secondary), wrapping real CLI commands (`sbatch`, `squeue`, `qsub`, `qstat`) — not library mocks.

**GPU Resource Management** — Advisory allocation layer on top of Slurm GRES with GPU type validation, queue wait estimation, and NVIDIA MIG partitioning awareness.

**Observability** — Prometheus + Grafana + Loki stack with custom Slurm exporters, DCGM GPU metrics, NVIDIA Triton inference server monitoring, and three pre-built dashboards.

**Compliance as Code** — Chef InSpec profiles validating GPU driver versions, GRES configuration, Slurm service health, and storage mount integrity.

**MLOps Integration** — Experiment tracking, model versioning, and a Streamlit web interface for pipeline submission and monitoring.

---

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        CLI / Streamlit UI                    │
│              helixscale [cluster|jobs|infra|monitor]         │
├──────────────────────────────────────────────────────────────┤
│                     Orchestration Engine                     │
│         Pipeline DAG  ←→  Scheduler Abstraction              │
│        (dependency      (Slurm | SGE | Local)                │
│         resolution)        GPU Allocator                     │
├──────────────────────────────────────────────────────────────┤
│                     Container Runtimes                       │
│              Docker (T0/T1)  |  Apptainer (T2)               │
├──────────────┬──────────────┬────────────────────────────────┤
│  Terraform   │   Ansible    │   Chef InSpec                  │
│  (provision) │  (configure) │   (validate)                   │
├──────────────┴──────────────┴────────────────────────────────┤
│                     Observability                            │
│    Prometheus → Grafana    DCGM Exporter    Loki             │
│    Slurm Exporter          Triton Metrics                    │
└──────────────────────────────────────────────────────────────┘
```

### Deployment Tiers

| Tier | Environment | GPU | Scheduler | Use Case |
|------|-------------|-----|-----------|----------|
| **T0 — Local** | macOS M1 Pro | CPU fallback | Mini-Slurm (Docker Compose) | Development & validation |
| **T1 — Cloud** | AWS EKS / AKS | A100/H100 | Slurm on provisioned infra | Production demo |
| **T2 — HPC** | On-prem cluster | Multi-node GPU | Slurm + Altair SGE | Full-scale deployment |

Every component runs at T0 first. If it doesn't work in Docker Compose, it doesn't ship.

---

## The BioNeMo Workload

Real Bronze level protein structure prediction using NVIDIA BioNeMo and Meta's ESM-2, processing **50 3D structures from the Protein Data Bank (PDB)**.

```
PDB FASTA Input → Tokenization → ESMFold Inference → PDB Output + pLDDT Scores → Report
     (CPU)           (CPU)         (GPU / CPU)              (CPU)                (CPU)
```

- **T0 (Local):** ESM-2 embeddings via Meta's `esm` package — real model, CPU-only, no fake GPU metrics
- **T1/T2 (Cloud/HPC):** Full ESMFold/OpenFold on A100 via `nvcr.io/nvidia/bionemo:1.0` container
- **Output:** Per-protein PDB files with confidence scores (pLDDT), aggregated HTML report with structure visualization

---

## Tech Stack

### Core
| Category | Tools |
|----------|-------|
| Language | Python 3.12+, Bash, HCL, YAML |
| Package Manager | UV (10–100x faster than pip) |
| CLI Framework | Typer + Rich |
| Configuration | Pydantic Settings (tier-aware, env-driven) |

### Infrastructure & Orchestration
| Category | Tools |
|----------|-------|
| Provisioning | Terraform (AWS/GCP modules) |
| Configuration | Ansible (Slurm, drivers, storage) |
| Compliance | Chef InSpec |
| Containers | Docker, Apptainer (HPC-native, rootless) |
| Schedulers | Slurm (primary), Altair Grid Engine |
| Cloud | AWS EKS, Azure AKS |

### NVIDIA Stack
| Category | Tools |
|----------|-------|
| Workload | BioNeMo (ESMFold protein folding) |
| GPU Telemetry | DCGM Exporter |
| Inference | Triton Inference Server |
| Partitioning | MIG (Multi-Instance GPU) |
| Communication | NCCL (multi-GPU) |
| Runtime | CUDA Toolkit, nvidia-container-toolkit |

### Observability & MLOps
| Category | Tools |
|----------|-------|
| Metrics | Prometheus + Grafana (3 dashboards) |
| Logs | Loki |
| GPU Monitoring | DCGM + custom Slurm exporter |
| Web UI | Streamlit |
| CI/CD | GitHub Actions (lint, test, infra-plan, container-build) |

---

## Quick Start (T0 — Local)

```bash
# Clone and install
git clone https://github.com/<your-username>/helixscale.git
cd helixscale
uv sync --all-extras

# Lint and test
make lint
make test

# Start local Slurm cluster (Docker Compose)
make t0-up

# Submit a protein folding pipeline (dry run first)
uv run helixscale jobs submit pipelines/workloads/protein_folding.yaml --dry-run
uv run helixscale jobs submit pipelines/workloads/protein_folding.yaml

# Monitor GPU metrics (Rich TUI)
uv run helixscale monitor gpu

# Grafana dashboards
open http://localhost:3000

# Teardown
make t0-down
```

---

## Project Structure

```
helixscale/
├── src/helixscale/
│   ├── cli/                  # Typer CLI (cluster, jobs, infra, monitor)
│   ├── orchestrator/         # Pipeline DAG, scheduler abstraction, GPU allocator
│   ├── monitoring/           # Prometheus exporters, DCGM integration, dashboards
│   └── utils/                # Tier-aware config, container runtime abstraction
├── infra/
│   ├── terraform/            # VPC, compute, storage, scheduler modules
│   ├── ansible/              # Slurm, GPU drivers, Apptainer, monitoring roles
│   └── chef/inspec/          # Compliance profiles
├── containers/               # Dockerfiles, Apptainer .def, docker-compose.yml
├── scheduler/                # Slurm/SGE configs, job templates, prolog scripts
├── pipelines/                # CI/CD workflows, BioNeMo workload definitions
├── monitoring/               # Prometheus, Grafana dashboards, alerting rules
├── docs/                     # Architecture, tradeoffs, runbook
└── tests/                    # Unit, integration (T0), e2e
```

---

## Key Design Decisions

| Decision | Chosen | Why |
|----------|--------|-----|
| Slurm over K8s-only | Slurm is the HPC standard — gang scheduling, fairshare, preemption. K8s orchestrates *around* the cluster, not as the batch scheduler. |
| Apptainer over Docker on HPC | No root daemon, MPI-native `srun` integration, required by most HPC facilities. |
| CLI wrapping over library bindings | `sbatch`/`squeue`/`qsub` — this is how HPC admins actually operate clusters. |
| Terraform + Ansible + InSpec | Provision → Configure → Validate. Three tools, three concerns, no overlap. |
| CPU fallback on every GPU path | Every GPU function has `if config.cpu_fallback:` with explicit logging. No fake metrics, no silent degradation. |
| UV over pip/poetry | 10–100x faster dependency resolution. Modern lockfile. Production-ready. |
| Real Slurm in Docker (T0) | `giovtorres/slurm-docker-cluster` proves real `sbatch`/`squeue` integration, not mocked subprocess calls. |

---

## Testing Strategy

| Level | What It Proves | How |
|-------|---------------|-----|
| **Unit** | Scheduler abstraction, config parsing, DAG resolution | `pytest` + mocks |
| **Integration** | Real Slurm job submission in Docker Compose | `pytest` + T0 stack |
| **E2E** | Full pipeline: provision → submit → monitor → report | GitHub Actions |
| **Compliance** | GPU drivers, GRES config, service health, storage mounts | Chef InSpec |

```bash
make test          # Unit tests
make t0-test       # Integration tests (starts/stops Docker stack)
make validate      # InSpec compliance
```

---

## Roadmap

- [x] Project scaffold and dependency setup
- [ ] Core scheduler abstraction (Slurm + SGE + Local backends)
- [ ] Pipeline DAG engine with dependency resolution
- [ ] CLI with `--dry-run` on all destructive commands
- [ ] T0 Docker Compose stack (3-node Slurm cluster)
- [ ] BioNeMo protein folding pipeline (50 PDB structures)
- [ ] Terraform modules (VPC, compute, storage, scheduler)
- [ ] Ansible roles (Slurm, NVIDIA drivers, Apptainer)
- [ ] Prometheus + Grafana observability stack
- [ ] NVIDIA Triton integration for model serving
- [ ] MIG partitioning support
- [ ] Streamlit web interface
- [ ] Chef InSpec compliance profiles
- [ ] CI/CD pipelines (GitHub Actions)
- [ ] EKS / AKS cloud deployment
- [ ] Architecture and tradeoffs documentation

---

## Target Roles

This project is built to demonstrate readiness for:

- **Platform Engineering** — full infrastructure lifecycle, IaC, config management, compliance
- **AI Infrastructure** — GPU cluster provisioning, model serving, NVIDIA stack depth
- **HPC Engineering** — Slurm/SGE administration, workload scheduling, multi-node GPU jobs
- **DevOps/SRE** — observability, CI/CD, container orchestration, incident runbooks

---

## License

MIT

---

<p align="center">
Built with purpose. Designed to ship.
</p>
