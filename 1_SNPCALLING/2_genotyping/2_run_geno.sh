#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=168:00:00
#SBATCH --mem=50GB
#SBATCH --job-name=geno
#SBATCH --array=1-12


module load gatk/4.2.0.0

chrom=`head -n ${SLURM_ARRAY_TASK_ID} chrom.intervals | tail -n 1`

gatk GenotypeGVCFs \
        -V total_gvcf/Shuhui_${chrom}_JAP_456.g.vcf.gz \
        -R /scratch/oa832/taiwan_files/vcf/11pop/indica_ref/REFERENCE/GCA_002151415.1_R498.Genome.version1_genomic.fa \
        -O total_vcf/Shuhui_${chrom}_JAP_456.vcf.gz
