# spec.md — HelixScale Technical Specification

## 1. System Overview

HelixScale is a portfolio-grade HPC orchestration platform demonstrating end-to-end GPU cluster provisioning, workload scheduling, and monitoring for BioNeMo-class computational biology workloads.

Proves competence across: bare-metal config → container packaging → job scheduling → GPU resource management → observability.

---

## 2. Deployment Tiers

### 2.1 T0 — Local (macOS M-series, 64GB)

**Stack:** Docker Compose simulating 3-node Slurm cluster (1 controller + 2 compute), UV-managed Python, mock GPU metrics, Prometheus + Grafana in containers, BioNeMo CPU-only inference (ESM-2 subset).

**Networking:** Single Docker bridge `helixscale-net`. Ports: Grafana (3000), Prometheus (9090), Slurm REST (6820).

**Tradeoffs accepted:**
- Slurm-in-Docker lacks cgroups v2 enforcement and real GRES — validates job submission flow, not resource isolation
- M-series cannot run CUDA — CPU fallback only, documented explicitly, no fake GPU metrics

### 2.2 T1 — Cloud GPU (AWS/GCP)

**Stack:** Terraform-provisioned VPC + GPU instances + shared storage + Slurm head node. Ansible configures drivers, CUDA, Slurm, Apptainer, monitoring. Real BioNeMo inference on A100/H100.

**Instance strategy:**
- Head: `c5.2xlarge` (on-demand, always-on)
- Compute: `p3.2xlarge` (1x V100, dev) → `p4d.24xlarge` (8x A100, showcase)
- Spot for compute with Slurm `ResumeTimeout` + checkpoint/restart

**Storage:**
- `/scratch` → FSx Lustre (high-throughput, ephemeral, 10-100x faster than EFS)
- `/home` → EFS (persistent, lower throughput)
- Model weights → S3 with lazy pull

### 2.3 T2 — HPC Cluster (Real Slurm + SGE)

**Stack:** Ansible playbooks for existing clusters, Altair SGE compatibility layer, Apptainer `.sif` containers, InSpec compliance, multi-node NCCL jobs.

**Tradeoffs:**
- Apptainer over Docker: no root daemon, MPI-native, Slurm `srun` integration
- Slurm + SGE dual target: Slurm dominates modern HPC, SGE persists in pharma/biotech

---

## 3. Core Components

### 3.1 Scheduler Abstraction (`orchestrator/scheduler.py`)

Protocol-based. Each backend wraps CLI commands (not library bindings) — how HPC admins actually work.

```python
class SchedulerBackend(Protocol):
    def submit(self, job: JobSpec) -> JobID: ...
    def status(self, job_id: JobID) -> JobStatus: ...
    def cancel(self, job_id: JobID) -> bool: ...
    def queue_info(self) -> list[QueueEntry]: ...

# Implementations: SlurmBackend, SGEBackend, LocalBackend (T0 fallback)
```

**JobSpec:** name, container, gpus, cpus, memory_gb, wall_time, partition, environment, script, dependencies (Pydantic model).

### 3.2 Pipeline Engine (`orchestrator/pipeline.py`)

DAG execution for BioNeMo workflows. Dependencies via Slurm `--dependency=afterok:JOBID` or SGE `-hold_jid`.

**BioNeMo Protein Folding Pipeline:**
1. `fetch_weights` — Pull model from NGC/S3 to `/scratch` (CPU)
2. `preprocess` — Tokenize FASTA sequences (CPU)
3. `inference` — ESMFold/OpenFold forward pass (GPU, N nodes)
4. `postprocess` — Aggregate PDB outputs, pLDDT scores (CPU)
5. `report` — HTML report with structure visualization (CPU)

### 3.3 GPU Resource Allocator (`orchestrator/gpu_allocator.py`)

Advisory layer wrapping Slurm GRES. Queries `sinfo --gres=gpu`, validates GPU type compatibility, estimates queue wait time. **Not a custom scheduler** — Slurm makes all scheduling decisions.

### 3.4 Container Management (`utils/containers.py`)

Protocol-based `ContainerRuntime` with `DockerRuntime` (T0/T1) and `ApptainerRuntime` (T2). Docker→Apptainer bridge: Apptainer `.def` uses `Bootstrap: docker` from same registry image.

### 3.5 CLI

```
helixscale cluster up|down|status
helixscale jobs submit|status|logs|cancel
helixscale infra plan|apply|configure|validate
helixscale monitor dashboard|gpu
```

All destructive commands have `--dry-run`. Tier auto-detected or `--tier t0|t1|t2`.

### 3.6 Monitoring

```
GPU Node → DCGM Exporter → Prometheus → Grafana
Slurm → Custom Python Exporter → Prometheus → Grafana
Job Logs → Loki → Grafana
```

**3 pre-built dashboards:** Cluster Overview, GPU Utilization, Job Analytics.

**Custom Slurm exporter metrics:** `slurm_jobs_pending`, `slurm_jobs_running`, `slurm_job_wait_seconds` (histogram), `slurm_gpu_utilization_ratio`.

---

## 4. Infrastructure as Code

### 4.1 Terraform Modules

| Module | Resources |
|--------|-----------|
| `vpc` | VPC, subnets, SGs, NAT (private compute, public head) |
| `compute` | GPU instances, launch templates, spot config, placement groups |
| `storage` | FSx Lustre, EFS, S3 |
| `scheduler` | Head node, SlurmDB, elastic compute fleet |

State: S3 + DynamoDB (AWS) or GCS (GCP). Workspaces: `dev`, `prod`.

### 4.2 Ansible Roles

| Role | Key Tasks |
|------|-----------|
| `slurm_controller` | slurmctld, slurmdbd, munge, partitions |
| `slurm_compute` | slurmd, join cluster, GRES config |
| `nvidia_gpu` | Drivers, CUDA, nvidia-container-toolkit, DCGM |
| `apptainer` | Install, fakeroot, cache dirs |
| `monitoring` | Prometheus, Grafana, Loki, DCGM exporter |

### 4.3 Chef InSpec

Compliance profiles: GPU driver version ≥530, GRES config present, Slurm services running, storage mounts valid.

---

## 5. BioNeMo Workload

**Model:** ESMFold (primary) or OpenFold (fallback). Input: FASTA from UniProt. Output: PDB + pLDDT scores. GPU: 1x A100 (40GB) min for inference.

**T0 CPU fallback:** Meta's `esm` package for lightweight embeddings. Skip full structure prediction. Synthetic DCGM snapshots clearly labeled as mock.

**Container:** Dockerfile pulls `nvcr.io/nvidia/bionemo:1.0` (pinned). Apptainer `.def` bootstraps from same Docker image.

---

## 6. CI/CD

| Workflow | Trigger | Steps |
|----------|---------|-------|
| `lint.yml` | Push/PR | ruff, mypy, shellcheck, terraform fmt |
| `test.yml` | Push/PR | pytest unit + T0 integration |
| `infra-plan.yml` | PR→main | terraform validate + plan |
| `container-build.yml` | Tag push | Docker build + push, Apptainer .sif build |

Pre-commit: ruff, check-yaml, terraform_fmt, shellcheck.

---

## 7. Configuration

Pydantic `BaseSettings` with `env_prefix="HELIX_"`. Fields: tier, scheduler, container_runtime, cloud_provider, region, gpu_instance_type, spot_enabled, slurm paths, BioNeMo model config, monitoring URLs.

Auto-detection: `HELIX_TIER` env → config file → probe (`nvidia-smi`, `sinfo`, cloud metadata).

---

## 8. Testing

| Level | Scope | Runner |
|-------|-------|--------|
| Unit | Scheduler abstraction, config, pipeline DAG | pytest + mocks |
| Integration | Docker Compose Slurm, job submission | pytest + T0 stack |
| E2E | Full pipeline: provision→submit→monitor→report | GitHub Actions (manual) |
| Compliance | InSpec on live cluster | inspec exec (T2) |

---

## 9. Security

- Munge auth for Slurm (auto-generated keys)
- SSH key-only access
- Terraform state encrypted at rest
- Container images scanned (Trivy)
- No secrets in code; env vars or secret managers
- Apptainer unprivileged (no setuid)
- Compute nodes: private subnet only
