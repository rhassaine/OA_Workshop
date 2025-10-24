#!/bin/bash
#SBATCH --job-name=COLO829v003Mini-test
#SBATCH -p compute
#SBATCH --time=72:00:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --output=/home/rhassaine/colo_mini_test/logs/%x_%j.out
#SBATCH --error=/home/rhassaine/colo_mini_test/logs/%x_%j.err
#SBATCH -D /home/rhassaine/colo_mini_test


ROOT="/home/rhassaine/colo_test"
OUTDIR="$ROOT/results"
WORKDIR="$ROOT/work"
NXFHOME="$ROOT/.nextflow_home"
CONFIG="/home/rhassaine/rayan_verylong.config"
INPUT="/home/rhassaine/colo_mini_test/samplesheet_colo_mini_fastq.csv"

mkdir -p "$ROOT/logs"

module load nextflow

echo "Launcher node: $(hostname)"
echo "Nextflow: $(nextflow -version | head -n1)"
echo "Apptainer: $(apptainer --version)"

export NXF_HOME="$NXFHOME"
export NXF_WORK="$WORKDIR"
export NXF_OPTS='-Xms1g -Xmx8g'

nextflow run nf-core/oncoanalyser \
  -profile singularity \
  -c "$CONFIG" \
  -r 2.2.0 \
  --mode wgts \
  --genome GRCh38_hmf \
  --outdir "$OUTDIR" \
  --input "$INPUT"

EXIT_CODE=$?
echo "Done at $(date) with code $EXIT_CODE"
exit $EXIT_CODE
