#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=10:00:00
#SBATCH --mem=16GB
#SBATCH --job-name=convert
#SBATCH --array=1-12

i=${SLURM_ARRAY_TASK_ID}


# these newick files are required for conversion into tskit format

../RELATE_SOFTWARE/scripts/SampleBranchLengths/SampleBranchLengths.sh \
-i ALL/ALL_HAPLOID/ALL_popsize_GAUT_UNIFORM_iter10_thresh0_pops_haploidized_chr${i} \
-o ALL/ALL_NEWICK/ALL_popsize_GAUT_UNIFORM_iter10_thresh0_pops_haploidized_chr${i} \
-m 5.35e-9 \
--coal ALL/ALL_HAPLOID/ALL_popsize_GAUT_UNIFORM_iter10_thresh0_pops_haploidized.coal \
--dist ALL/ALL_HAPLOID/ALL_popsize_GAUT_UNIFORM_iter10_thresh0_pops_haploidized_chr${i}.dist \
--format n \
--num_samples 1 \
--seed 12 \
--num_proposals 0
