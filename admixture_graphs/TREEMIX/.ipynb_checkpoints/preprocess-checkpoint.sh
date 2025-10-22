#!/bin/bash

module load plink/1.90b6.21

# CREATE THE CLUSTER FILE, make sure each anno file has outgroup annotations added

# Convert to freq file

for i in {3..12}
do
awk '{print $2"\t"$2"\t"$1}' ../ADMIXTOOLS/anno_K${i}_outgroup.txt | grep -v -f duplicates.txt  > pop_clust_K${i}.txt

plink --bfile ../BARTHII/Shuhui_JAP_BARTHII_LDpruned_filtered --mac 1  \
--geno 0.05 --allow-extra-chr  --keep pop_clust_K${i}.txt \
--make-bed --out K${i}_JAP_BARTHII_LDpruned

plink --bfile K${i}_JAP_BARTHII_LDpruned --freq  \
--allow-extra-chr  --within pop_clust_K${i}.txt \
--out K${i}_JAP_BARTHII_LDpruned

gzip K${i}_JAP_BARTHII_LDpruned.frq.strat

./plink2treemix.py K${i}_JAP_BARTHII_LDpruned.frq.strat.gz K${i}_JAP_BARTHII_LDpruned.frq.trm.gz

zcat K${i}_JAP_BARTHII_LDpruned.frq.trm.gz | sed "s/['b]//g" | gzip -c >  temp_K${i}.gz

mv temp_K${i}.gz K${i}_JAP_BARTHII_LDpruned.frq.trm.gz
done
