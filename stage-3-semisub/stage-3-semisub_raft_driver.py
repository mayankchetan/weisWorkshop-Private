#!/usr/bin/env python3
import os
from wisdem import run_wisdem
from openmdao.utils.mpi import MPI


## File management
run_dir = os.path.dirname( os.path.realpath(__file__) )
fname_wt_input = os.path.join(run_dir, "..", "stage-2-controller","outputs", "stage-2-controller.yaml")
fname_modeling_options = os.path.join(run_dir, "stage-3-semisub_raft_modeling.yaml")
fname_analysis_options = os.path.join(run_dir, "stage-3-semisub_raft_analysis.yaml")

wt_opt, modeling_options, analysis_options = run_wisdem(
        fname_wt_input, fname_modeling_options, fname_analysis_options
    )

