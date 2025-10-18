#!/bin/bash
#SBATCH --chdir=/scratch/tsingh65/TNG50-1_snap99
#SBATCH --output=/scratch/tsingh65/TNG50-1_snap99/logs/spec_arr_%A_%a.out
#SBATCH --error=/scratch/tsingh65/TNG50-1_snap99/logs/spec_arr_%A_%a.err
#SBATCH --partition=public
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=10G
#SBATCH --time=2-12:00:00
#SBATCH --array=1-1  # <-- set at submission time

set -euo pipefail

# --- Env (SOL) ---
module purge
module load mamba
eval "$(conda shell.bash hook)"
conda activate trident

export LD_LIBRARY_PATH="$CONDA_PREFIX/lib:${LD_LIBRARY_PATH:-}"
export PATH="$CONDA_PREFIX/bin:$PATH"
# HDF5 on shared FS: avoid flaky locks/version checks
export HDF5_USE_FILE_LOCKING=FALSE
export HDF5_DISABLE_VERSION_CHECK=2

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

# ---- TWEAK STARTS HERE ----
# Per-task workdir = that subhalo's directory
WORKDIR="${ROOT}/sub_${SID}"
if [[ ! -d "$WORKDIR" ]]; then
  echo "[ERROR] Missing subhalo directory: $WORKDIR"
  exit 2
fi
cd "$WORKDIR"
echo "[INFO] CWD set to $PWD"

# Scratch for Trident ray files (your Python now checks SLURM_TMPDIR first)
export TRIDENT_RAY_TMP="${SLURM_TMPDIR:-$WORKDIR/_tmp_trident}"
mkdir -p "$TRIDENT_RAY_TMP"
echo "[INFO] TRIDENT_RAY_TMP=$TRIDENT_RAY_TMP"
# ---- TWEAK ENDS HERE ----

echo "[INFO] Task $SLURM_ARRAY_TASK_ID → SID=$SID"

python -u /home/tsingh65/COS-GASS/notebooks/run_spectra_one_sid.py \
  --sid "$SID" \
  --snap 99 \
  --root "$ROOT" \
  --verbose
