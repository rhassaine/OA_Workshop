#!/bin/bash

### Start-up script to set up everything needed for the Oncoanalyser Workshop
### Bucharest, Romania - November 25/26 2024

# Define the tmux session name to reuse across the script
TMUX_SESSION_NAME="oncoanalyser_setup"

# Define log files for capturing output
LOGFILE="oncoanalyser_setup.log"      # Combined log for both stdout and stderr
STDOUT_LOG="oncoanalyser_setup.out"   # Log for stdout only
STDERR_LOG="oncoanalyser_setup.err"   # Log for stderr only

# Print initial instructions to the user
echo "Starting Oncoanalyser setup script..."
echo "Logs will be saved to $LOGFILE, $STDOUT_LOG, and $STDERR_LOG."

# Redirect stdout and stderr to log files while also printing to the console
exec > >(tee -i "$LOGFILE" "$STDOUT_LOG") 2> >(tee -i "$LOGFILE" "$STDERR_LOG" >&2)

# Enable immediate exit on error and trap errors for better debugging
set -e  # Exit on any error
trap 'echo "Error occurred on line $LINENO. Check $LOGFILE, $STDOUT_LOG, and $STDERR_LOG for details." && exit 1' ERR

# Step 0: Check and install tmux if not installed
if ! command -v tmux >/dev/null 2>&1; then
  echo "tmux not found. Installing tmux..."
  sudo apt-get update && sudo apt-get install -y tmux
fi

# Step 1: Check if the script is already running in a tmux session
if [ -z "$TMUX" ]; then
  echo "Not in a tmux session. Starting a new tmux session named '$TMUX_SESSION_NAME'..."

  # Check if a tmux session with the same name already exists and kill it if it does
  if tmux has-session -t "$TMUX_SESSION_NAME" 2>/dev/null; then
    echo "A tmux session named '$TMUX_SESSION_NAME' already exists. Killing it..."
    tmux kill-session -t "$TMUX_SESSION_NAME"
  fi

  # Start a new tmux session and rerun this script from the beginning
  tmux new-session -d -s "$TMUX_SESSION_NAME" "bash $0 --tmux-start"
  echo "A new tmux session has been started. Attach using: tmux attach-session -t $TMUX_SESSION_NAME"
  exit 0
fi

# Step 2: Handle the first tmux session logic (initial setup)
if [ "$1" == "--tmux-start" ]; then
  echo "Running initial setup inside tmux session '$TMUX_SESSION_NAME'..."

  # Installing unzip and zip packages (required for extracting SDKMAN installation files)
  echo "Installing unzip and zip..."
  sudo apt-get update && sudo apt-get install -y unzip zip

  ### Installing Docker using the official Docker instructions
  echo "Installing Docker from the official Docker repository..."

  # Update the package index and install prerequisites
  sudo apt-get install -y \
      ca-certificates \
      curl \
      gnupg \
      lsb-release

  # Add Docker’s official GPG key for verifying downloads
  sudo mkdir -m 0755 -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

  # Set up the stable Docker repository
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  # Update the package index again and install Docker packages
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Verify Docker installation
  if command -v docker >/dev/null; then
    echo "Docker installed successfully: $(docker --version)"
  else
    echo "Docker installation failed. Exiting."
    exit 1
  fi

  # Add the current user to the Docker group to allow running Docker without sudo
  USER=$(whoami)
  echo "Adding user '$USER' to the 'docker' group..."
  sudo usermod -aG docker "$USER"
  echo "Docker installation complete. Please log out and log back in to apply group changes, or use 'newgrp docker' to apply them temporarily."

  ### Start a new tmux session for post-Docker setup
  echo "Starting a new tmux session for post-Docker setup..."

  # Detach and kill the current tmux session
  tmux detach
  tmux kill-session -t "$TMUX_SESSION_NAME"

  # Start a new tmux session for the next stage
  tmux new-session -d -s "$TMUX_SESSION_NAME" "bash $0 --tmux-continue"
  echo "A new tmux session has been started for the next stage. Attach using: tmux attach-session -t $TMUX_SESSION_NAME"
  exit 0
fi

# Step 3: Handle the second tmux session logic (post-Docker setup)
if [ "$1" == "--tmux-continue" ]; then
  echo "Continuing setup inside tmux session '$TMUX_SESSION_NAME'..."

  ### Install Java using SDKMAN!
  echo "Checking if Java is installed..."
  if java_version=$(java --version); then
    echo "Java is already installed: $java_version"
  else
    echo "Java is not installed. Installing Java with SDKMAN!"
    curl -s https://get.sdkman.io | bash
    source "$HOME/.sdkman/bin/sdkman-init.sh"  # Initialize SDKMAN in the current shell
    sdk install java 17.0.10-tem

    # Verify Java installation
    if java_version=$(java --version); then
      echo "Java was successfully installed!: $java_version"
    else
      echo "Java installation failed."
      exit 1
    fi
  fi

  ### Install Nextflow
  echo "Installing Nextflow..."
  curl -s https://get.nextflow.io | bash
  chmod +x nextflow
  mkdir -p ~/.local/bin
  mv nextflow ~/.local/bin

  # Add Nextflow to PATH and persist the changes
  export PATH="$HOME/.local/bin:$PATH"
  if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
  fi
  source ~/.bashrc

  # Confirm the Nextflow installation
  nextflow info

  ### Pull the nf-core/oncoanalyser pipeline
  echo "Cloning nf-core/oncoanalyser repository using Nextflow..."
  nextflow pull nf-core/oncoanalyser

  # Verify the pipeline was pulled successfully
  if [ -d "$HOME/.nextflow/assets/nf-core/oncoanalyser" ]; then
    echo "nf-core/oncoanalyser pipeline successfully pulled."
  else
    echo "Error: nf-core/oncoanalyser pipeline directory not found. Exiting."
    exit 1
  fi

  ### Prepare reference data
  # There is a dedicated command in oncoanalyser to download the reference data

  # Uncomment the following lines to download the stage data
  # echo "Preparing reference data..."
  # nextflow run nf-core/oncoanalyser \
  #   -profile docker \
  #   --mode wgts \
  #   --genome GRCh37_hmf \
  #   --prepare_reference_only \
  #   --input samplesheet.csv \
  #   --outdir prepare_reference/

  # OR 

  # nextflow run nf-core/oncoanalyser \
  #   --prepare_reference_only \
  #   -c nextflow.config

  # Pointing towards the nextflow.config file will contain all the necessary predefined parameters needed for stating the references
  # for a DNA analysis

  # The config file will then need to be adjusted with the correct paths to the references

  # This will download the reference data for a run using the GRCh37_hmf reference genome
  # The samplesheet.csv file is a file that contains the information about the samples 
  # that will be used in the analysis - only the references needed for that type of analysis will be downloaded
  # The samplesheet file is a CSV file with the following columns: 
  # group_id,subject_id,sample_id,sample_type,sequence_type,filetype,filepath
  # In this workshop, it will only be done for the COLOMini sample, from bam
  # The samplesheet should be stored in the same directory as this script

  # Extra: Running the test profile

  # Using the staged references will require the creation of a nextflow.config file
  # to point each individual reference (otherwise the pipeline 
  # will download the references again)

  # The following Nextflow commands can be used for running the test profile
  # echo "Running test profile for nf-core/oncoanalyser..."
  # nextflow run nf-core/oncoanalyser -profile test,docker --outdir test_profile_results -c nextflow.config
  
  echo "Setup completed successfully."

  # Final message
  echo "Oncoanalyser setup script completed successfully."
  echo "Please check the log files ($LOGFILE, $STDOUT_LOG, $STDERR_LOG) for details."
fi