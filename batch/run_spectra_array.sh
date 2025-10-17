#!/bin/bash
#SBATCH --job-name=spec_arr
#SBATCH --output=spec_arr_%A_%a.out
#SBATCH --error=spec_arr_%A_%a.err
#SBATCH --partition=general
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=10G
#SBATCH --time=06:00:00
#SBATCH --array=1-1  # <-- set at submission time

set -euo pipefail

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
export PYTHONPATH="/home/tsingh65/COS-GASS/notebooks:${PYTHONPATH:-}"

ROOT="/scratch/tsingh65/TNG50-1_snap99"
SID_LIST="/home/tsingh65/COS-GASS/data/sids_with_inc.txt"

# map array index -> line (skip blank/comment lines)
SID="$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SID_LIST" | tr -d '[:space:]')"
if [[ -z "${SID}" || ! "${SID}" =~ ^[0-9]+$ ]]; then
  echo "[WARN] Empty/invalid SID on line ${SLURM_ARRAY_TASK_ID}; skipping."
  exit 0
fi

cd "$ROOT"
echo "[INFO] Task $SLURM_ARRAY_TASK_ID → SID=$SID"

python -u /home/tsingh65/COS-GASS/notebooks/run_spectra_one_sid.py \
  --sid "$SID" \
  --snap 99 \
  --root "$ROOT" \
  --verbose