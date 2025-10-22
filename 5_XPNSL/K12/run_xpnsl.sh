#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=10
#SBATCH --time=48:00:00
#SBATCH --mem=40GB
#SBATCH --job-name=geno
#SBATCH --array=1-12

chr=`head -n ${SLURM_ARRAY_TASK_ID} chrom.txt | tail -n 1`
pop=$1

selscan --xpnsl --vcf VCFS/${pop}_${chr}_imputed.vcf \
--vcf-ref VCFS/No_${pop}_${chr}_imputed.vcf \
--max-extend-nsl -1 --out XPNSL/${pop}_${chr} --threads 10
