#!/bin/bash
#SBATCH --job-name=spec_one
#SBATCH --output=spec_one_%j.out
#SBATCH --error=spec_one_%j.err
#SBATCH --partition=htc
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=10G
#SBATCH --time=04:00:00

set -euo pipefail

SID="${1:?Usage: sbatch run_spectra_single.sh <SID>}"

# --- Env (SOL) ---
module purge
module load mamba
eval "$(conda shell.bash hook)"
conda activate trident

export LD_LIBRARY_PATH="$CONDA_PREFIX/lib:${LD_LIBRARY_PATH:-}"
export PATH="$CONDA_PREFIX/bin:$PATH"
unset PYTHONPATH || true
export PYTHONNOUSERSITE=1
export MPLBACKEND=Agg
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}
export MKL_NUM_THREADS=${SLURM_CPUS_PER_TASK}
export OPENBLAS_NUM_THREADS=${SLURM_CPUS_PER_TASK}
export NUMEXPR_NUM_THREADS=${SLURM_CPUS_PER_TASK}

# let Python see your module in the repo
export PYTHONPATH="/home/tsingh65/COS-GASS/notebooks:${PYTHONPATH:-}"

ROOT="/scratch/tsingh65/TNG50-1_snap99"
cd "$ROOT"

echo "[INFO] Host: $(hostname)"
echo "[INFO] CONDA_PREFIX: $CONDA_PREFIX"
echo "[INFO] Running SID=$SID"

python -u /home/tsingh65/COS-GASS/notebooks/run_spectra_one_sid.py \
  --sid "$SID" \
  --snap 99 \
  --root "$ROOT" \
  --verbose