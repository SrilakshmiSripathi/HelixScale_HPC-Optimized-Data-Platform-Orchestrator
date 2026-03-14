#!/bin/bash

# ------------------------------------------
# bootstrap.sh - Platform Manager
# Purpose: Safely sets up the development environment for HelixScale
# Risk Level: Low (No cloud resources created unless you approve)
# Requirements: Bash 3+, curl, wget
# ------------------------------------------

set -e          # Exit on error
set -o pipefail # Enable pipeline error checking
set -u          # Treat unset variables as errors

echo "=========================================="
echo " 🚀 HelixScale Platform Manager "
echo "=========================================="
echo ""

# --- Configuration Variables ---
PROJECT_NAME="HelixScale"
UV_VERSION="0.9.26"
PYTHON_VERSION="3.12"  # Python 3.12+ is recommended for Mac M-Series
TERRAFORM_VERSION="1.14"
ANSIBLE_VERSION="2.15"
AWS_REGION = "us-east-1"   # Default region (override in .tfvars)

# --- Function 1: Detect OS & Install Dependencies ---
setup_system_tools() {
    echo "🔍 Checking System Environment..."
    
    local is_mac = false
    local is_linux = true
    
    if [[ $(uname) == "Darwin" ]]; then
        is_mac = true
        echo "⚠️  Detected macOS (M-Series). Running on POSIX Shell."
    fi

    # Check for Terraform and AWS CLI
    if ! command -v terraform &>/dev/null; then
        echo "   🛠️  Installing Terraform (${TERRAFORM_VERSION})..."
        curl -LO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_darwin_amd64.zip
        # Note: For cross-platform compatibility in a script, we use direct download.
        # On Linux, the file path usually changes (linux-amd64). 
        # To be truly portable, we detect and adjust extension, or ask user to install manually if auto-fail occurs.
        # SAFETY NOTE: We check for existing version first to avoid overwriting system tools if managed by root/sudo elsewhere.
        
        # Since direct downloads vary by architecture (ARM64 vs AMD64), we simplify:
        echo "   ℹ️  User must ensure Terraform is installed via package manager or binary."
        return 1 
    fi
    
    echo "   ✅ Terraform detected ($(terraform --version))"

    if ! command -v aws &>/dev/null; then
        echo "   🛠️  Installing AWS CLI v2..."
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        rm awscliv2.zip
    else
        echo "   ✅ AWS CLI detected ($(aws --version))"
    fi
}


# --- Step 1: Install uv if not present ---
echo "🔍 Checking UV installer..."

if ! command -v uv &> /dev/null; then
    echo "⚠️  UV not found. Installing now (this takes 30 seconds)..."
    
    # Use curl to install uv silently
    curl -LsSf https://astral.sh/uv/install.sh | sh
    
    echo ""
    echo "✅ UV installed successfully."
    
    # Re-scan to confirm it's ready
    if ! command -v uv &> /dev/null; then
        echo "❌ Installation failed. Please check your internet connection."
        exit 1
    fi
else
    echo "✅ UV already installed (Version: $(uv --version))"
fi

# --- Step 2: Create Virtual Environment for Python Code ---
echo ""
echo "🔧 Creating isolated project environment..."

# Ensure uv is in path
if [[ ! "$PATH" =~ (^|:)/\.local/bin ]]; then
    echo "⚠️  Adding UV to PATH. Run source $HOME/.local/bin/env || export PATH=$HOME/.local/bin:$PATH"
fi

cd "$PROJECT_NAME"  # Ensure we're in the project folder

# Initialize uv project and create virtual environment
uv init --python "${PYTHON_VERSION}" > /dev/null 2>&1 || {
    echo "ℹ️  Initializing Python project without error handling..."
}

# Install common Python dependencies (if any)
echo ""
echo "📦 Installing Python dependencies..."

uv add --optional requests boto3 python-dotenv > /dev/null 2>&1 || true

echo "✅ Virtual environment ready."

# --- Step 3: Check System Tools (Terraform & Ansible) ---
echo ""
echo "☁️  Checking cloud infrastructure tools..."

if ! command -v terraform &> /dev/null; then
    echo "⚠️  Terraform not found on system."
    echo "   To install: brew install terraform"
    echo ""
else
    echo "✅ Terraform installed (Version: $(terraform --version))"
fi

if ! command -v ansible &> /dev/null; then
    echo "⚠️  Ansible not found on system."
    echo "   To install: brew install ansible"
    echo ""
else
    echo "✅ Ansible installed (Version: $(ansible --version))"
fi

if ! command -v aws &> /dev/null; then
    echo "⚠️  AWS CLI not found on system."
    echo "   To install: brew install aws-cli"
    echo ""
else
    echo "✅ AWS CLI installed (Version: $(aws --version))"
fi

# --- Step 4: Verify AWS Credentials (Safety Check) ---
echo ""
echo "🔐 Verifying cloud permissions..."

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo ""
    echo "⚠️  No AWS credentials found in environment."
    echo ""
    echo "   To set up credentials securely:"
    echo "   1. Go to https://console.aws.amazon.com/iam/"
    echo "   2. Create a new access key for your IAM user"
    echo "   3. Run: aws configure"
    echo "   OR export AWS_ACCESS_KEY_ID='...'"
    echo "   OR export AWS_SECRET_ACCESS_KEY='...'"
    echo ""
    
    read -p "Would you like to set up AWS credentials now? [y/N]: " SETUP_CREDENTIALS
    
    if [[ "$SETUP_CREDENTIALS" == "y" || "$SETUP_CREDENTIALS" == "Y" ]]; then
        echo ""
        aws configure --profile default
        # Check again after configuration
        if [ -z "$AWS_ACCESS_KEY_ID" ]; then
            echo "❌ Credential setup failed. Please set up credentials manually."
            exit 1
        fi
    else
        echo "ℹ️  Skipping AWS credential setup for now."
        echo "   You can run 'aws configure' later before creating cloud resources."
    fi
else
    echo "✅ AWS credentials detected (no action needed)."
fi

# --- Step 5: Create .gitignore if not exists (Safety Protection) ---
echo ""
echo "🛡️  Setting up security protections..."

if [[ ! -f .gitignore ]]; then
    cat > .gitignore << 'EOF'
# Python cache
__pycache__/
*.py[cod]
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg

# Terraform State (NEVER commit this!)
*.tfstate*
*.tfvars

# Virtual environments
.env
.venv/
venv/
ENV/
.venv/
uv.lock      # Optional: commit if you want locked versions

# AWS Credentials (Never commit)
.aws/
*.pem
EOF
    
    echo "✅ .gitignore created for security."
else
    echo "ℹ️  .gitignore already exists."
fi

# --- Step 6: Final Summary & Approval Gate ---
echo ""
echo "=========================================="
echo "✅ Environment Ready!"
echo "=========================================="
echo ""
echo "Next Steps:"
echo "1. Review your AWS Budget settings ($2/month recommended)"
echo "2. Edit 'main.tf' in infra/ folder with desired resources"
echo "3. Run: terraform plan (to preview changes)"
echo "4. Run: ./bootstrap.sh again to refresh environment anytime"
echo ""

# --- Step 7: Ask for Approval Before Creating Cloud Resources ---
if ! check_credentials; then
    echo ""
    echo "⚠️  Cannot create cloud resources without credentials."
    echo "   Please run 'aws configure' or set AWS_ACCESS_KEY_ID/SECRET_ACCESS_KEY"
    exit 0
fi

echo ""
echo "☁️  Ready for Cloud Provisioning..."
read -p "🔐 Do you want to approve Terraform execution now? [y/N]: " CONFIRM_CREATE

if [[ "$CONFIRM_CREATE" == "y" || "$CONFIRM_CREATE" == "Y" ]]; then
    echo ""
    echo "✅ Creation Approved. Running Terraform..."
    terraform init
    
    if [ -f main.tf ]; then
        terraform plan
        read -p "Execute plan? [y/N]: " EXECUTE
        
        if [[ "$EXECUTE" == "y" || "$EXECUTE" == "Y" ]]; then
            terraform apply -auto-approve
            echo ""
            echo "✅ Cloud resources created successfully."
            echo "   View your resources in AWS Console!"
        else
            echo "ℹ️  Skipping resource creation for now."
        fi
    else
        echo "ℹ️  No main.tf found. Skipping Terraform execution."
    fi
else
    echo "ℹ️  Cloud resource creation skipped."
fi

echo ""
echo "=========================================="
echo "Bootstrap Complete!"
echo "=========================================="






# 1. Install uv for Linux
curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.cargo/env

# 2. Install all Python dependencies using uv
uv sync --all-extras

# 3. Install core OS dependencies (Ubuntu equivalents of the macOS brew prerequisites)
sudo apt update && sudo apt install -y ansible nodejs
snap install terraform --classic




#!/bin/bash

# -----------------------------------------------------------------------------
# bootstrap.sh - Safety First Initialization Script
# Purpose: Prepares the environment safely before creating cloud resources
# Author: HPC Platform Engineer Portfolio (Phase 1)
# Risk Level: Low (Requires user confirmation to spend money)
# -----------------------------------------------------------------------------

set -e # Exit immediately if a command exits with non-zero status
set -o pipefail # Enable pipeline error checking

echo "🚀 Starting HPC Platform Bootstrap..."
echo "=================================================="

# --- 1. Check and Install 'uv' (Python Manager) ---
# Why? uv is faster than pip. We install it once, then reuse it locally.
check_uv() {
    if command -v uv &> /dev/null; then
        echo "✅ UV is already installed."
        echo "   Version: $(uv --version)"
        return 0
    else
        echo "⚠️  UV not found. Installing now (this takes a moment)..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        source $HOME/.local/bin/env # Ensure path is updated for this session
        if command -v uv &> /dev/null; then
            echo "✅ UV installation complete."
            return 0
        else
            echo "❌ Installation failed. Please try manually with curl..."
            exit 1
        fi
    fi
}

# --- 2. Check AWS Credentials (Safety Guard) ---
# Why? We never want to accidentally use your credentials without checking.
check_credentials() {
    if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
        echo "⚠️  WARNING: No AWS Credentials detected in environment."
        echo "   You can generate these at https://console.aws.amazon.com/iam/"
        echo "   Set them using: export AWS_ACCESS_KEY_ID='...'"
        echo "   (Or use 'aws configure' to set them securely)."
        echo ""
        echo "   ⛔ CLOUD RESOURCE CREATION SKIPPED due to missing keys."
        echo "   This prevents accidental bills!"
        return 1
    else
        echo "✅ AWS Credentials detected."
        echo "   (Note: Keys are never logged or displayed)."
        return 0
    fi
}

# --- 3. Logic to Create/Check Linux VM (Cloud Instance) ---
# Why? This is the critical step. We ask for permission first.
create_linux_vm() {
    if ! check_credentials; then
        echo "Cannot create VM without credentials."
        return 1
    fi

    # Safety Check: Did you really mean it?
    read -p "⚠️  This action will spin up a Cloud Linux Instance (EC2/GCP). Do you want to proceed? [y/N]: " CONFIRM
    
    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
        echo "✅ VM Creation Request Approved. Running Terraform..."
        
        # We use 'terraform apply' here but only for the specific resources defined in Phase 1
        # In a real project, you might pass --target to only create the instance (e.g., -var=instance_name="my-vm")
        terraform init
        terraform plan -out=tfplan && terraform apply -auto-approve tfplan
        
        echo "✅ VM Instance Ready."
    else
        echo "ℹ️  Skipping VM creation for now. Run this script again with confirmation."
    fi
}

# --- 4. Main Execution Flow ---
# Step-by-step process to prevent mistakes

# 1. Setup Local Tools (uv) - This is always safe and local
echo "📦 Checking Python Manager..."
check_uv

# 2. Check Cloud Permissions (Safety Gate)
echo "🔐 Checking Security Credentials..."
check_credentials

# 3. Ask to Create Cloud Resources (The Risky Part)
echo "☁️  Ready for Cloud Provisioning Logic..."
create_linux_vm

echo "=================================================="
echo "Bootstrap Complete."
echo "Next Step: Check your AWS Console for the new resources if any were created."
