#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=20
#SBATCH --time=43:00:00
#SBATCH --mem=50GB
#SBATCH --job-name=relate



popsize=`grep ALL Ne_ALL.txt | awk '{print $2}'`
mutrate=5.35e-9
mutsource=GAUT
recomb=UNIFORM

echo $popsize

for i in {1..12}
do
Relate \
        --mode All \
        --haps ALL/ALL_HAPLOID_HAPS/chr${i}_ALL_haploidized.haps \
        --sample ALL/ALL_HAPLOID_HAPS/chr${i}_ALL_haploidized.sample   \
        --map UNIFORM/chr${i}.map \
        --dist ALL/ALL_HAPLOID_HAPS/chr${i}_ALL_haploidized.dist \
        -m ${mutrate} \
        -N ${popsize} \
        --sample_ages ALL/ALL_haploidized_sample_ages.txt \
        -o ALL_${mutsource}_${recomb}_haploidized_chr${i} \
        --memory 20
done

mv ALL_${mutsource}_${recomb}_haploidized_* ALL/ALL_HAPLOID
