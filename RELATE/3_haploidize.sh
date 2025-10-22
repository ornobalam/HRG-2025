#!/bin/bash

module load r/gcc/4.3.1


# create haploidized hap/sample files
# by randomly sampling one phased haplotype per chromosome for each individual

for chr in {1..12}
do
Rscript haploidize.R ALL/ALL_HAPS/chr${chr}_ALL
mv ALL/ALL_HAPS/chr${chr}_ALL_haploidized* ALL/ALL_HAPLOID_HAPS
cp ALL/ALL_HAPS/chr${chr}_ALL_masked.dist ALL/ALL_HAPLOID_HAPS/chr${chr}_ALL_haploidized.dist
cp ALL/ALL_HAPS/chr${chr}_ALL.poplabels ALL/ALL_HAPLOID_HAPS/chr${chr}_ALL_haploidized.poplabels
done
