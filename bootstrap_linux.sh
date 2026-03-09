# 1. Install uv for Linux
curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.cargo/env

# 2. Install all Python dependencies using uv
uv sync --all-extras

# 3. Install core OS dependencies (Ubuntu equivalents of the macOS brew prerequisites)
sudo apt update && sudo apt install -y ansible nodejs
snap install terraform --classic