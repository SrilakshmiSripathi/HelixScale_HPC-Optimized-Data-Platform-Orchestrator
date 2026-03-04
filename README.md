# 🚀 HelixScale: HPC-Optimized Data Platform

Core Objective: A proof-of-concept platform that bridges the gap between High-Performance Computing (HPC) and Cloud-Native MLOps, automating the deployment of NVIDIA BioNeMo microservices.

### The Problem It Solves

Traditional AI research often suffers from "Infrastructure Friction." Data Scientists struggle to move workloads between on-prem SLURM clusters and cloud-based Kubernetes environments. HelixScale provides a unified control plane using Infrastructure as Code (Terraform) to deploy containerized LLMs with built-in observability.

### Current Hardware
Developed on Apple Silicon M1 pro 64GB RAM. GPU workloads validated on A100 via Lambda Labs. All Slurm and Apptainer testing done in OrbStack Linux VM

### Tech Stack

- Infrastructure: Terraform (Modular AWS/GCP or Local K3s).

- Orchestration: Kubernetes (CKA/CKAD level patterns: Taints, Tolerations, Node Affinity for GPUs).

- AI Layer: NVIDIA BioNeMo / Triton Inference Server.

- Observability: Prometheus (metrics) & Grafana (dashboards for GPU utilization).

- Quality: PyTest (Unit/Integration) and Synthetic Data Generators.

# 🛠️ Phased Implementation Plan (The "Sprint to Live")

Check out the [project]("https://github.com/users/SrilakshmiSripathi/projects/3/views/1") for more details on phase plan.