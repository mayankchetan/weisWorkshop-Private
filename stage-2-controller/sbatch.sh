#!/bin/bash
#SBATCH --time=5-00:00:00          # walltime limit (max 10 days)
#SBATCH --account=weis            # allocation account
#SBATCH --nodes=2                  # number of nodes
#SBATCH --tasks-per-node=80       # number of tasks per node
########SBATCH --qos=high
#SBATCH --job-name=ww-2-control
#SBATCH --output=logs/job_log.%j.out  # %j will be replaced with the job ID

 
# Save current directory
cdr=$(pwd)
 
cd $cdr
 
scontrol show hostnames > nodelist
source ~/.bash_profile
export OMP_NUM_THREADS=1
conda activate /projects/weis/mchetan/weis-workshop/env/weis-workshop-script-main
echo "Number of Tasks: $SLURM_NTASKS"
echo "Number of Tasks per node: $SLURM_NTASKS_PER_NODE"
# mpirun -n $SLURM_NTASKS -ppn $SLURM_NTASKS_PER_NODE python aeroStruct.py
mpirun -n $SLURM_NTASKS -ppn $SLURM_NTASKS_PER_NODE python stage-2-controller_driver.py