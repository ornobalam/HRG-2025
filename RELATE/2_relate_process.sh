#!/bin/bash


module load bcftools/intel/1.14
module load htslib/intel/1.14

# create haps files via vcf files

for i in {1..12}
do 
bcftools view -t $i Shuhui_456_SNP_biallel_HT_VQSR90_het_mac_geno_imputed_polarized.vcf > VCFS/chr${i}.vcf
bgzip VCFS/chr${i}.vcf

RelateFileFormats \
                 --mode ConvertFromVcf \
                 --haps HAPS/chr${i}.haps \
                 --sample HAPS/chr${i}.sample \
                 -i VCFS/chr${i}

done

# will remove the two duplicate herbarium specimens
cat duplicates.txt | sort | uniq > ALL/ALL_remove.txt


# create a poplabels file
# mainly cosmetic, treating everything as japonica
# split times are generated posthoc from the eventual RELATE-inferred tree sequences

sed '1,2d' HAPS/chr1.sample > ALL/ALL.poplabels

echo 'sample population group sex' > ALL/tmpALL

awk '{print $1" japonica japonica NA"}' ALL/ALL.poplabels >> ALL/tmpALL

mv ALL/tmpALL ALL/ALL.poplabels



# remove duplicate accessions, apply genomic mask (generated with Heng Li's snpable approach), and
# generate SNP annotations
for i in {1..12}
do
RelateFileFormats \
                 --mode RemoveSamples \
                 --haps HAPS/chr${i}.haps \
                 --sample HAPS/chr${i}.sample\
                 --poplabels ALL/ALL.poplabels \
                 -i ALL/ALL_remove.txt \
                 -o ALL/ALL_HAPS/chr${i}_ALL

RelateFileFormats \
                 --mode FilterHapsUsingMask\
                 --haps ALL/ALL_HAPS/chr${i}_ALL.haps \
                 --sample ALL/ALL_HAPS/chr${i}_ALL.sample \
                 --mask MASKS/chr${i}_mask.fa \
                 -o ALL/ALL_HAPS/chr${i}_ALL_masked

RelateFileFormats \
                 --mode GenerateSNPAnnotations \
                 --haps ALL/ALL_HAPS/chr${i}_ALL_masked.haps \
                 --sample ALL/ALL_HAPS/chr${i}_ALL.sample \
                 --poplabels ALL/ALL_HAPS/chr${i}_ALL.poplabels \
                 -o ALL/ALL_HAPS/chr${i}_ALL_masked
done

