#!/bin/bash

### Undo script for the Oncoanalyser Workshop setup
### Bucharest, Romania - November 25/26 2024

# Define the tmux session name to reuse across the script
TMUX_SESSION_NAME="oncoanalyser_setup"

# Define log files for capturing output
LOGFILE="oncoanalyser_undo.log"      # Combined log for both stdout and stderr
STDOUT_LOG="oncoanalyser_undo.out"   # Log for stdout only
STDERR_LOG="oncoanalyser_undo.err"   # Log for stderr only

# Print initial instructions to the user
echo "Starting Oncoanalyser undo script..."
echo "Logs will be saved to $LOGFILE, $STDOUT_LOG, and $STDERR_LOG."

# Redirect stdout and stderr to log files while also printing to the console
exec > >(tee -i "$LOGFILE" "$STDOUT_LOG") 2> >(tee -i "$LOGFILE" "$STDERR_LOG" >&2)

# Enable immediate exit on error and trap errors for better debugging
set -e  # Exit on any error
trap 'echo "Error occurred on line $LINENO. Check $LOGFILE, $STDOUT_LOG, and $STDERR_LOG for details." && exit 1' ERR

### Step 1: Kill any tmux sessions created by the setup script
echo "Checking for active tmux session named '$TMUX_SESSION_NAME'..."
if tmux has-session -t "$TMUX_SESSION_NAME" 2>/dev/null; then
  echo "Killing tmux session '$TMUX_SESSION_NAME'..."
  tmux kill-session -t "$TMUX_SESSION_NAME"
else
  echo "No active tmux session named '$TMUX_SESSION_NAME' found."
fi

### Step 2: Remove Docker
echo "Uninstalling Docker and related components..."
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo apt-get autoremove -y --purge
sudo rm -rf /var/lib/docker /var/lib/containerd /etc/docker
sudo rm -rf /etc/apt/keyrings/docker.gpg /etc/apt/sources.list.d/docker.list
echo "Docker and related components have been removed."

### Step 3: Remove Java installed via SDKMAN!
if [ -d "$HOME/.sdkman" ]; then
  echo "Removing SDKMAN! and Java..."
  rm -rf "$HOME/.sdkman"
  sed -i '/sdkman-init.sh/d' "$HOME/.bashrc"
else
  echo "SDKMAN! not found. Skipping Java removal."
fi

### Step 4: Remove Nextflow
echo "Removing Nextflow..."
if [ -f "$HOME/.local/bin/nextflow" ]; then
  rm -f "$HOME/.local/bin/nextflow"
  sed -i '/export PATH="$HOME\/.local\/bin:$PATH"/d' "$HOME/.bashrc"
  echo "Nextflow has been removed."
else
  echo "Nextflow not found. Skipping."
fi

### Step 5: Remove nf-core/oncoanalyser pipeline
echo "Removing nf-core/oncoanalyser pipeline..."
if [ -d "$HOME/.nextflow/assets/nf-core/oncoanalyser" ]; then
  rm -rf "$HOME/.nextflow/assets/nf-core/oncoanalyser"
  echo "nf-core/oncoanalyser pipeline has been removed."
else
  echo "nf-core/oncoanalyser pipeline not found. Skipping."
fi

### Step 6: Remove other installed packages
echo "Removing unzip, zip, and tmux..."
sudo apt-get purge -y unzip zip tmux
sudo apt-get autoremove -y --purge
echo "Unzip, zip, and tmux have been removed."

### Step 7: Clean up any remaining log files
echo "Cleaning up log files..."
rm -f oncoanalyser_setup.log oncoanalyser_setup.out oncoanalyser_setup.err
echo "Setup log files have been removed."

### Final Message
echo "Oncoanalyser undo script completed successfully."
echo "Please check the log files ($LOGFILE, $STDOUT_LOG, $STDERR_LOG) for details."