#!/bin/bash

module load plink/1.90b6.21

# convert to plink bed format
plink --vcf Shuhui_BAR_19.vcf.gz --set-missing-var-ids @:# --allow-extra-chr --biallelic-only strict \
--keep-allele-order --double-id --make-bed --out Shuhui_BAR_19

# run a genotyping rate filter
plink --bfile Shuhui_BAR_19 --geno 0.5 --allow-extra-chr --make-bed \
--keep-allele-order --out Shuhui_BAR_19_geno0.5

# for treemix and admixture graphs, we used an LD pruned dataset
# getting the list of SNPs after LD pruning
awk '{print $2}' ../JAPONICA/Shuhui_456_SNP_biallel_HT_VQSR90_het_mac_geno_10kb_50.bim > JAP_LDpruned_snps.txt

# keeping LD-pruned SNPs
plink --bfile Shuhui_BAR_19_geno0.5 --allow-extra-chr --extract JAP_LDpruned_snps.txt \
--keep-allele-order --make-bed --out Shuhui_BAR_19_geno0.5_LDpruned

# merging barthii individuals into japonica dataset
plink --bfile ../JAPONICA/Shuhui_456_SNP_biallel_HT_VQSR90_het_mac_geno_10kb_50 \
--bmerge Shuhui_BAR_19_geno0.5_LDpruned.bed Shuhui_BAR_19_geno0.5_LDpruned.bim Shuhui_BAR_19_geno0.5_LDpruned.fam \
--allow-extra-chr --keep-allele-order --make-bed --out Shuhui_JAP_BARTHII_LDpruned

# the merging initially fails, so creating new japonica set excluding mismatched/triallelic SNPs
awk '{print $2}' Shuhui_BAR_19_geno0.5_LDpruned.bim > JAP_BAR_LDpruned_snps.txt

plink --bfile ../JAPONICA/Shuhui_456_SNP_biallel_HT_VQSR90_het_mac_geno_10kb_50 --extract JAP_BAR_LDpruned_snps.txt \
--exclude Shuhui_JAP_BARTHII_LDpruned-merge.missnp --allow-extra-chr --keep-allele-order \
--make-bed --out JAP_merge

plink --bfile Shuhui_BAR_19_geno0.5_LDpruned \
--exclude Shuhui_JAP_BARTHII_LDpruned-merge.missnp --allow-extra-chr --keep-allele-order \
--make-bed --out BARTHII_merge

# re-attempt merging, works this time

plink --bfile JAP_merge --bmerge BARTHII_merge.bed \
BARTHII_merge.bim BARTHII_merge.fam --allow-extra-chr --keep-allele-order \
--make-bed --out Shuhui_JAP_BARTHII_LDpruned_filtered
