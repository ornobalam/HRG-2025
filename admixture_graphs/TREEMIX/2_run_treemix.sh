#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=24:00:00
#SBATCH --mem=4GB
#SBATCH --job-name=treemix
#SBATCH --array=3-12


K=${SLURM_ARRAY_TASK_ID}
module load treemix/intel/1.13


max_m=`echo $(( ($K / 2) + 1 ))`

if [ $K == 10 ]; then max_m=3; fi

echo $max_m


for m in `seq 1 ${max_m}`
   do
   for i in 1 10 100
      do
      treemix -i K${K}_JAP_BARTHII_LDpruned.frq.trm.gz -k ${i} -m $m -o K${K}/K${K}.${i}.${m} -root Barthii
      done
   done
