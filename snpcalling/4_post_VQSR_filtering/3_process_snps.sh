#!/bin/bash


module load plink2/20230417
module load bcftools/intel/1.14
module load plink/1.90b6.21
module load r/gcc/4.1.0

prefix=${1::-4}
maxhet=$2
dir=$3

# Remove all genotype calls that are supported by just two or less reference and/or alternative read
# This is an allelic depth filter

bcftools filter -S . -e '(GT="het" & (FORMAT/AD[*:0]<=2 | FORMAT/AD[*:1]<=2)) | ( (GT="0/0" | GT="0|0") & FORMAT/AD[*:0]<=2) |((GT="1/1" | GT="1|1") & FORMAT/AD[*:1]<=2)' -o ${prefix}_AD.vcf.gz  ${dir}/$1


plink2 --vcf ${prefix}_AD.vcf.gz --set-missing-var-ids @:# --allow-extra-chr --double-id --make-bed --out ${prefix}

plink2 --bfile ${prefix} --allow-extra-chr --hardy --out ${prefix}

# Find SNPs by max heterozygosity

Rscript filter_hwe.R ${prefix}.hardy $maxhet ${prefix}_het${maxhet}_filtered_SNPs.txt

# Extract heterozygosity-filtered SNPs

plink2 --bfile ${prefix} --allow-extra-chr --extract ${prefix}_het${maxhet}_filtered_SNPs.txt --make-bed --out \
${prefix}_het

# Filter by SNPs that are biallelic (still)

plink2 --bfile ${prefix}_het --mac 1 --allow-extra-chr --make-bed --out ${prefix}_het_mac


# Filter by genotyping rate
plink2 --bfile ${prefix}_het_mac --geno 0.2 --allow-extra-chr --make-bed --out \
${prefix}_het_mac_geno

# First step of linkage pruning
plink2 --bfile ${prefix}_het_mac_geno --allow-extra-chr --indep-pairwise 10kb 1 0.8 --out ${prefix}_ld_1
plink2 --bfile ${prefix}_het_mac_geno --extract ${prefix}_ld_1.prune.in --allow-extra-chr --make-bed --out \
${prefix}_het_mac_geno_10kb

# Second step of linkage pruning
plink2 --bfile ${prefix}_het_mac_geno_10kb --allow-extra-chr --indep-pairwise 50 1 0.8 --out ${prefix}_ld_2
plink2 --bfile ${prefix}_het_mac_geno_10kb --extract ${prefix}_ld_2.prune.in --allow-extra-chr --make-bed --out \
${prefix}_het_mac_geno_10kb_50

# Generate distance matrix
plink --bfile ${prefix}_het_mac_geno_10kb_50 --allow-extra-chr --distance square '1-ibs' --out \
${prefix}_het_mac_geno_10kb_50

# Run discretize using run_pamsil.sh script


