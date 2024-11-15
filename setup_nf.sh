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

# Trap errors, log, and send email notification on error
trap 'echo "Error occurred on line $LINENO. Check $LOGFILE, $STDOUT_LOG, and $STDERR_LOG for details." && send_email && exit 1' ERR

# Installing unzip (necessary for the installation of SDKMAN among other things)
sudo apt-get update && sudo apt-get install -y unzip
echo "Checking if unzip is installed..."

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

echo "Checking if Docker is installed..."

# Check Docker installation
if docker_version=$(docker --version); then
  echo "Docker is installed: $docker_version"
else
  echo "Docker is not installed. Please install Docker manually and re-run the script."
  exit 1  # Exit if Docker is not installed, as it is required
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

# Confirm the Nextflow installation
nextflow info

# Update Nextflow to the latest version
echo "Updating Nextflow..."
nextflow self-update

# Clone the Oncoanalyser repository
echo "Cloning nf-core/oncoanalyser repository using Nextflow commands..."
nextflow pull nf-core/oncoanalyser

# List installed pipelines to confirm success
# Check if nf-core/oncoanalyser is in the list

if echo "$nextflow_list_output" | grep -q "nf-core/oncoanalyser"; then
  echo "nf-core/oncoanalyser is present in the list of Nextflow pipelines."
else
  echo "Error: nf-core/oncoanalyser is not present in the list of Nextflow pipelines."
  exit 1
fi

# Prepare reference data
# There is a dedicated command in oncoanalyser to download the reference data

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
# nextflow run nf-core/oncoanalyser -profile test,docker --outdir test_profile_results

echo "Setup completed successfully."

# Final message
echo "Oncoanalyser setup script completed successfully."
echo "Please check the log files ($LOGFILE, $STDOUT_LOG, $STDERR_LOG) for details."