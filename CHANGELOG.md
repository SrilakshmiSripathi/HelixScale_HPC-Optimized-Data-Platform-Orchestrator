# HelixScale Changelog

All notable changes to the HelixScale Platform will be documented in this file.

> Not auto-generated

# Version 2.0: HelixScale: BioNeMo-AI HPC Fabric Orchestration Platform

Mainly, the idea evolved to differ streamlit interface to version 3.0. 

┌──────────────────────────────────────────────────────────────┐
│                     Orchestration Engine                     │
│         Pipeline DAG  ←→  Scheduler Abstraction              │
│        (dependency      (Slurm |  Local)                 │
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



# [Version - 1.0] - Mar-04-2026 HelixScale: HPC-optimized BioNemo Orchestration  (MVP Phase 1)

### 🎯 Features: 

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