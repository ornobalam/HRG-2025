#!/bin/bash

module load htslib/intel/1.14
module load r/gcc/4.1.0
module load bcftools/intel/1.14

VCF=$1
TYPE=$2

# get vcf with HDRA SNPs present in current dataset

# this is run with two TYPE = HDRA or Truth

# HDRA refers to 700k SNPs from the SNP Chip Project https://iric.irri.org/projects/snp-chip-project-hdra
# Lifted over to Shuhui

# Truth is a shorter list of experimentally validated mutations or peak SNPs reported from GWAS

bcftools view ../${VCF} -T known_sets/Shuhui_${TYPE}.txt -o ${VCF::-7}_${TYPE}_prec.vcf

# Validate SNPs

sed -e '/^#/d' ${VCF::-7}_${TYPE}_prec.vcf | awk '{print $1"\t"$2"\t"$4"\t"$5}' > vcf_${TYPE}.txt

Rscript validate_SNPS.R ${TYPE}

bcftools view -T ^non_val_${TYPE}.txt ${VCF::-7}_${TYPE}_prec.vcf  > ${VCF::-7}_${TYPE}.vcf

# Compress and index

bgzip -c ${VCF::-7}_${TYPE}.vcf > ${VCF::-7}_${TYPE}.vcf.gz


tabix -p vcf ${VCF::-7}_${TYPE}.vcf.gz
