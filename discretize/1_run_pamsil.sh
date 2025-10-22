#!/bin/bash

module load r/gcc/4.3.1

Rscript PAMSil.r 12 \
../japonica_456_countries_meta.txt \
../Shuhui_456_SNP_biallel_HT_VQSR90_het_mac_geno_10kb_50.mdist

