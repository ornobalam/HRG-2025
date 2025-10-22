#!/bin/bash

module load plink2/20230417
module load vcftools/intel/0.1.16

for i in {1..12}
do
plink2 --haps ALL/ALL_HAPS/chr${i}_ALL_masked.haps ref-first \
--sample ALL/ALL_HAPS/chr${i}_ALL.sample \
--export vcf-4.2 id-paste=iid --out ALL/ALL_VCFS/chr${i}_ALL_masked

end=`awk '{print $2}' Shuhui.genome | head -n ${i} | tail -n 1`
vcftools --vcf ALL/ALL_VCFS/chr${i}_ALL_masked.vcf --window-pi ${end} \
--out ALL/ALL_STATS/chr${i}_ALL_masked
done



for i in {1..12}; do sed '1d' ALL/ALL_STATS/chr${i}_ALL_masked.windowed.pi; done > ALL/ALL_pi.txt




python3 calculate_pi.py ALL/ALL_pi.txt | paste <(echo ALL) - >> Ne_ALL.txt 
