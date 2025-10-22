#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=6:00:00
#SBATCH --mem=5GB
#SBATCH --job-name=find
#SBATCH --array=1-9200

module load r/gcc/4.3.1

LINE=$SLURM_ARRAY_TASK_ID

# the find_graphs() function from admixtools (R package) 
# is being run 200 times for each model configuration (number of populations, number of admixture events)

file=admix_array.txt

K=`head -n ${LINE} ${file} | tail -n 1 | awk '{print $1}'`
m=`head -n ${LINE} ${file} | tail -n 1 | awk '{print $2}'`
iter=`head -n ${LINE} ${file} | tail -n 1 | awk '{print $3}'`
seed=`head -n ${LINE} ${file} | tail -n 1 | awk '{print $4}'`

Rscript run_find_graphs.R $K $m $iter $seed
