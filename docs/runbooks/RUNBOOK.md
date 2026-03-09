# HelixScale: Developer Onboarding & Runbook

## 1. Environment Initialization (macOS / T0)
This platform requires a specific toolchain (UV, Docker, OrbStack) to simulate the HPC environment locally.

Commands from the start

### Initialize the environment

#### OrbStack Linux environment local run below commands in the HelixScale folder
`orb create ubuntu helixscale-dev`
`orb -m helixscale-dev`

 When ready to close: `orb stop helixscale-dev`

This step creates most compatible Linux machine- modern way to add Linux VM to MACs. 

> Ceveat is SLURM still sees CPU not GPU( as mac doesnt have CUDA GPU).

#### Installing make to OrbStack environment

`sudo apt-get update && sudo apt-get install make`
`sudo apt-get update && sudo apt-get install build-essential`


#### Create Virtual Environment within Linux Environment
`uv init --name helixscale --python 3.12`
`uv sync --all-extras`

