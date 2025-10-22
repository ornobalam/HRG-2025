#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=20
#SBATCH --time=23:00:00
#SBATCH --mem=50GB
#SBATCH --job-name=estpop



mutrate=5.35e-9
mutsource=GAUT
recomb=UNIFORM
iterations=10
threshold=0
poplabel=ALL/ALL_HAPLOID_HAPS/chr1_ALL_haploidized.poplabels
if [ $1 == "hap" ]; then poplabel="hap"; fi

module load r/gcc/4.3.1

../RELATE_SOFTWARE/scripts/EstimatePopulationSize/EstimatePopulationSize.sh \
    -i ALL/ALL_HAPLOID/ALL_${mutsource}_${recomb}_haploidized \
    -m ${mutrate} \
    --poplabels ${poplabel} \
    --years_per_gen 1 \
    --first_chr 1 \
    --last_chr 12 \
    --threads 20 \
    --num_iter ${iterations} \
    --threshold ${threshold} \
    --bins 2,7,0.1 \
    -o ALL_popsize_${mutsource}_${recomb}_iter${iterations}_thresh${threshold}_${1}_haploidized

mv ALL_popsize_${mutsource}_${recomb}_iter${iterations}_thresh${threshold}_${1}_haploidized* ALL/ALL_HAPLOID
