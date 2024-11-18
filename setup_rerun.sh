#!/bin/bash

### Start up script to setup everything needed for the Oncoanalyser Workshop
### Bucharest, Romania - November 25/26 2024

# Define log files
LOGFILE="oncoanalyser_setup.log"      # Combined log for both stdout and stderr
STDOUT_LOG="oncoanalyser_setup.out"   # Log for stdout only
STDERR_LOG="oncoanalyser_setup.err"   # Log for stderr only

# Log rotation to prevent overwriting logs
mv "$LOGFILE" "$LOGFILE.$(date +%s)" 2>/dev/null || true
mv "$STDOUT_LOG" "$STDOUT_LOG.$(date +%s)" 2>/dev/null || true
mv "$STDERR_LOG" "$STDERR_LOG.$(date +%s)" 2>/dev/null || true

# Print initial instructions
echo "Starting Oncoanalyser setup script..."
echo "Logs will be saved to $LOGFILE, $STDOUT_LOG, and $STDERR_LOG."

# Redirect output: `stdout` to STDOUT_LOG and `stderr` to STDERR_LOG,
# while also capturing both in LOGFILE
exec > >(tee -i "$LOGFILE" "$STDOUT_LOG") 2> >(tee -i "$LOGFILE" "$STDERR_LOG" >&2)

set -e  # Exit on any error

# Trap errors and log them with line numbers
trap 'echo "Error occurred on line $LINENO. Check $LOGFILE, $STDOUT_LOG, and $STDERR_LOG for details." && exit 1' ERR

### 1. Install tmux if not installed
if ! dpkg -l | grep -qw tmux; then
  echo "Installing tmux..."
  sudo apt-get update && sudo apt-get install -y tmux
else
  echo "tmux is already installed."
fi

### 2. Start in tmux if not already in a tmux session
if [ -z "$TMUX" ]; then
  if tmux has-session -t oncoanalyser_setup 2>/dev/null; then
    echo "Attaching to existing tmux session 'oncoanalyser_setup'."
    tmux attach-session -t oncoanalyser_setup
  else
    echo "Creating a new tmux session 'oncoanalyser_setup'."
    tmux new-session -d -s oncoanalyser_setup "bash $0"
  fi
  exit
fi

### 3. Install unzip if not installed
if ! dpkg -l | grep -qw unzip; then
  echo "Installing unzip and zip..."
  sudo apt-get update && sudo apt-get install -y unzip zip
else
  echo "unzip and zip are already installed."
fi

### 4. Install Java if not installed
if ! command -v java >/dev/null; then
  echo "Java not found. Installing via SDKMAN..."
  curl -s https://get.sdkman.io | bash
  source "$HOME/.sdkman/bin/sdkman-init.sh"
  sdk install java 17.0.10-tem
else
  echo "Java is already installed: $(java --version)"
fi

### 5. Install Docker if not installed
if ! command -v docker >/dev/null; then
  echo "Installing Docker..."
  sudo apt-get update
  sudo apt-get install -y \
      ca-certificates \
      curl \
      gnupg \
      lsb-release

  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo systemctl start docker
  sudo systemctl enable docker
else
  echo "Docker is already installed: $(docker --version)"
fi

# For the user to be able to interact w/ the Docker daemon w/o sudo
# it needs to be granted permission to the docker group

USER=$(whoami)

echo "Adding user '$USER' to the docker group..."
sudo usermod -aG docker "$USER"

# Apply group membership changes immediately within the tmux session
echo "Applying group membership changes for user '$USER'..."
exec sg docker newgrp "$(id -gn)" <<EONG
echo "Group membership applied. Verifying groups in this shell:"
groups
EONG

### 6. Install Nextflow
if [ ! -f "$HOME/.local/bin/nextflow" ]; then
  echo "Nextflow not found. Installing..."
  curl -s https://get.nextflow.io | bash
  chmod +x nextflow
  mkdir -p ~/.local/bin
  mv nextflow ~/.local/bin
else
  echo "Nextflow is already installed."
fi

# Add Nextflow directory to PATH if not already present
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
  echo "Added Nextflow to PATH in .bashrc."
else
  echo "Nextflow PATH is already set in .bashrc."
fi

source ~/.bashrc
export PATH="$HOME/.local/bin:$PATH"
echo "Current PATH: $PATH"

# Verify Nextflow installation
if ! command -v nextflow >/dev/null; then
  echo "Error: Nextflow installation failed or PATH is not set correctly."
  exit 1
else
  echo "Nextflow installation successful."
fi

### 7. Update Nextflow
echo "Updating Nextflow..."
nextflow self-update

### 8. Clone the Oncoanalyser repository
if [ ! -d "$HOME/.nextflow/assets/nf-core/oncoanalyser" ]; then
  echo "Cloning nf-core/oncoanalyser repository..."
  nextflow pull nf-core/oncoanalyser
else
  echo "nf-core/oncoanalyser repository already exists."
fi

# Potential resource staging check upon rerun of script 

### 9. Prepare reference data
# if [ ! -f "prepare_reference/done.marker" ]; then
#   echo "Preparing reference data..."
#   # Example commands to prepare references:
#   # nextflow run nf-core/oncoanalyser --prepare_reference_only -c nextflow.config
#   touch prepare_reference/done.marker
#   echo "Reference data preparation completed."
# else
#   echo "Reference data already prepared. Skipping."
# fi

# The following Nextflow commands can be used for running the test profile

echo "Running test profile for nf-core/oncoanalyser..."
nextflow run nf-core/oncoanalyser -profile test,docker --outdir test_profile_results -c nextflow.config

### 10. Final message
echo "Oncoanalyser setup script completed successfully."
echo "Please check the log files ($LOGFILE, $STDOUT_LOG, $STDERR_LOG) for details."