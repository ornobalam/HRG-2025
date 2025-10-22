#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=20
#SBATCH --time=28:00:00
#SBATCH --mem=60GB
#SBATCH --job-name=impute

module load jdk/11.0.9
module load plink2/20230417


# export MAC=1, and geno=0.2 filtered file as vcf to be used as input for phasing/imputation
plink2 --bfile ../JAPONICA/Shuhui_456_SNP_biallel_HT_VQSR90_het_mac_geno --allow-extra-chr  \
 --recode vcf id-paste=iid --out Shuhui_456_SNP_biallel_HT_VQSR90_het_mac_geno



# run imputation using beagle
# version details: beagle.22Jul22.46e.jar (version 5.4)
java -Xmx40g -jar ./beagle.jar gt=Shuhui_456_SNP_biallel_HT_VQSR90_het_mac_geno.vcf \
out=Shuhui_456_SNP_biallel_HT_VQSR90_het_mac_geno_imputed nthreads=20

