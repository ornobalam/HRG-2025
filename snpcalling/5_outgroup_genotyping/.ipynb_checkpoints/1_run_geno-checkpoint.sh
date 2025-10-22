#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=48:00:00
#SBATCH --mem=20GB
#SBATCH --job-name=geno


module load gatk/4.2.0.0

chrom=`head -n ${SLURM_ARRAY_TASK_ID} chrom.intervals | tail -n 1`

# call SNPs on sites already identified in japonica dataset while keeping invariant sites

gatk GenotypeGVCFs \
        -V ../Shuhui_BAR_19.g.vcf.gz \
        -R /scratch/oa832/taiwan_project/vcf/11pop/indica_ref/REFERENCE/GCA_002151415.1_R498.Genome.version1_genomic.fa \
        -O Shuhui_BAR_19.vcf.gz \
	-L snp_list.bed.bed \
	-all-sites
