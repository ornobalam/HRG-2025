#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=24:00:00
#SBATCH --mem=12GB
#SBATCH --job-name=filter
#SBATCH --array=1-12

module load gatk/4.2.0.0

file=vcf_list.txt
vcf=`head -n ${SLURM_ARRAY_TASK_ID} $file  | tail -n 1`


# Get SNPs only

gatk SelectVariants \
       -R /scratch/oa832/taiwan_files/vcf/11pop/indica_ref/REFERENCE/GCA_002151415.1_R498.Genome.version1_genomic.fa \
        -V ${vcf} \
        --select-type-to-include SNP \
       -O ${vcf::-7}_SNP.vcf.gz

# Get biallelic SNPs

gatk SelectVariants \
       -R /scratch/oa832/taiwan_files/vcf/11pop/indica_ref/REFERENCE/GCA_002151415.1_R498.Genome.version1_genomic.fa \
       -V ${vcf::-7}_SNP.vcf.gz \
       --restrict-alleles-to BIALLELIC \
       -O ${vcf::-7}_SNP_biallel.vcf.gz
