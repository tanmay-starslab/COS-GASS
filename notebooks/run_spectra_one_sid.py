#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse, glob, os, sys
from pathlib import Path

# --- make sure we can import the module from your repo notebooks ---
# adjust if your repo path differs
REPO_NOTEBOOKS = "/home/tsingh65/COS-GASS/notebooks"
if REPO_NOTEBOOKS not in sys.path:
    sys.path.insert(0, REPO_NOTEBOOKS)

from spectra_batch_module import (
    JobPaths, JobParams, SpectraConfig, run_all_runs_for_sid
)

def pick_cutout(subdir: str, sid: int) -> str:
    pats = [
        f"{subdir}/cutout_ALLFIELDS_sphere_2p1Rvir_sub{sid}.hdf5",
        f"{subdir}/cutout*sub{sid}*.hdf5",
        f"{subdir}/*.hdf5",
    ]
    hits = []
    for pat in pats:
        hits.extend(glob.glob(pat))
    if not hits:
        raise FileNotFoundError(f"No cutout HDF5 under {subdir} for SID={sid}")
    # prefer ALLFIELDS + sphere_2p1Rvir if present
    hits.sort(key=lambda p: (0 if "ALLFIELDS" in p and "sphere_2p1Rvir" in p else
                             1 if "ALLFIELDS" in p else 2, len(p)))
    return hits[0]

def available_runs(subdir: str, sid: int, snap: int):
    out = []
    for rl in ("L3Rvir", "L4Rvir"):
        rays_csv = os.path.join(
            subdir, f"rays_and_recipes_sid{sid}_snap{snap}_{rl}", f"rays_sid{sid}.csv"
        )
        if os.path.isfile(rays_csv):
            out.append(rl)
    return out

def main():
    ap = argparse.ArgumentParser(description="Run spectra for one SID on SOL.")
    ap.add_argument("--sid", type=int, required=True)
    ap.add_argument("--snap", type=int, default=99)
    ap.add_argument("--root", default="/scratch/tsingh65/TNG50-1_snap99",
                    help="Scratch root that contains sub_<SID>/")
    ap.add_argument("--filter_mode", choices=["noflip","flip"], default=None)
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()

    sid  = int(args.sid)
    snap = int(args.snap)
    subdir = os.path.join(args.root, f"sub_{sid}")
    if not os.path.isdir(subdir):
        raise FileNotFoundError(f"Missing directory: {subdir}")

    cutout = pick_cutout(subdir, sid)
    run_labels = available_runs(subdir, sid, snap)
    if not run_labels:
        raise FileNotFoundError(
            f"No rays CSVs found for SID={sid} (looked for L3Rvir/L4Rvir under {subdir})"
        )

    paths  = JobPaths(cutout_h5=cutout, rays_base=subdir, output_base=subdir)
    params = JobParams(sid=sid, snap=snap, run_labels=run_labels,
                       filter_mode=args.filter_mode, verbose=args.verbose)
    cfg    = SpectraConfig()  # defaults: COS-G130M, Lyα/SiIII/CII zooms

    run_all_runs_for_sid(paths, params, cfg)

if __name__ == "__main__":
    main()