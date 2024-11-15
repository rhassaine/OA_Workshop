#!/bin/bash

### Start up script to setup everything needed for the Oncoanalyser Workshop
### Bucharest, Romania - November 25/26 2024

# Define log files
LOGFILE="oncoanalyser_setup.log"      # Combined log for both stdout and stderr
STDOUT_LOG="oncoanalyser_setup.out"    # Log for stdout only
STDERR_LOG="oncoanalyser_setup.err"    # Log for stderr only

# Print initial instructions
echo "Starting Oncoanalyser setup script..."
echo "Logs will be saved to $LOGFILE, $STDOUT_LOG, and $STDERR_LOG."

# Check and install tmux if not installed
if ! command -v tmux >/dev/null; then
  echo "tmux not found. Installing tmux..."
  sudo apt-get update && sudo apt-get install -y tmux
fi

# Start in tmux if not already in a tmux session
if [ -z "$TMUX" ]; then
  tmux new-session -d -s oncoanalyser_setup "bash $0"  # Start a detached tmux session to re-run this script within tmux
  echo "Script is now running in tmux session 'oncoanalyser_setup'."
  exit
fi

# Redirect output: `stdout` to STDOUT_LOG and `stderr` to STDERR_LOG,
# while also capturing both in LOGFILE
exec > >(tee -i "$LOGFILE" "$STDOUT_LOG") 2> >(tee -i "$LOGFILE" "$STDERR_LOG" >&2)

set -e  # Exit on any error

# Trap errors and log them with line numbers
trap 'echo "Error occurred on line $LINENO. Check $LOGFILE, $STDOUT_LOG, and $STDERR_LOG for details." && exit 1' ERR

# Installing unzip (necessary for the installation of SDKMAN among other things)
sudo apt-get update && sudo apt-get install -y unzip zip
echo "Checking if unzip & unzip are installed..."

echo "Checking if Java is installed..."

# Check Java installation
if java_version=$(java --version); then
  echo "Java is installed: $java_version"
else
  echo "Java is not installed. Installing Java with SDKMAN!"
  curl -s https://get.sdkman.io | bash
  source "$HOME/.sdkman/bin/sdkman-init.sh"  # Initialize SDKMAN in current shell
  sdk install java 17.0.10-tem
fi

# Confirm the Java installation
java -version

# Check and install Docker if not installed
echo "Checking if Docker is installed..."
if ! command -v docker >/dev/null; then
  echo "Docker not found. Installing Docker..."
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

  echo "Docker installed successfully."
else
  echo "Docker is already installed: $(docker --version)"
fi


# Install Nextflow
echo "Installing Nextflow..."
curl -s https://get.nextflow.io | bash

# Give the permissions to the executable
chmod +x nextflow

# Recommended directory for the executable
mkdir -p ~/.local/bin
mv nextflow ~/.local/bin

# Add Nextflow directory to PATH
export PATH="$HOME/.local/bin:$PATH"


# Persist PATH change for future sessions
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi

echo "Reloading .bashrc in tmux session for above changes to take effect..."
source ~/.bashrc
echo "Current PATH: $PATH"

# Confirm the Nextflow installation
nextflow info

# Update Nextflow to the latest version
echo "Updating Nextflow..."
nextflow self-update

# Clone the Oncoanalyser repository
echo "Cloning nf-core/oncoanalyser repository using Nextflow commands..."
nextflow pull nf-core/oncoanalyser

# Verify that the pipeline was pulled successfully
if [ -d "$HOME/.nextflow/assets/nf-core/oncoanalyser" ]; then
  echo "nf-core/oncoanalyser pipeline is successfully pulled and available."
else
  echo "Error: nf-core/oncoanalyser pipeline directory not found. Please check the pull command."
  exit 1
fi

# Prepare reference data
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

# This will download the reference data for a run using the GRCh37_hmf reference genome
# The samplesheet.csv file is a file that contains the information about the samples 
# that will be used in the analysis - only the references needed for that type of analysis will be downloaded
# The samplesheet file is a CSV file with the following columns: 
# group_id,subject_id,sample_id,sample_type,sequence_type,filetype,filepath
# In this workshop, it will only be done for the COLOMini sample, from bam
# The sampelsheet should be stored in the same directory as that this script

# Extra: Running the test profile

# Using the staged references will required the creation of a nextflow.config file
# to point each individual references (otherwise the pipeline 
# will download the references again)

# The following Nextflow commands can be used for running the test profile

# echo "Running test profile for nf-core/oncoanalyser..."
nextflow run nf-core/oncoanalyser -profile test,docker --outdir test_profile_results -c nextflow.config

echo "Setup completed successfully."

# Final message
echo "Oncoanalyser setup script completed successfully."
echo "Please check the log files ($LOGFILE, $STDOUT_LOG, $STDERR_LOG) for details."