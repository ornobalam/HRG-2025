#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=168:00:00
#SBATCH --mem=40GB
#SBATCH --job-name=combine
#SBATCH --array=1-12

module load bcftools/intel/1.14

input=../../IMPUTE/Shuhui_456_SNP_biallel_HT_VQSR90_het_mac_geno_imputed.vcf.gz
pop=`head -n ${SLURM_ARRAY_TASK_ID} K12_pops.txt | tail -n 1`


# creating list for each population and for all individuals excluding the population
# XP-nSL is going to be run for each population vs. all other individuals

# duplicates.txt removes two individuals with identical herbarium IDs to two other samples
grep ${pop} list2annoK12_noNA.txt | grep -v -f duplicates.txt | awk '{print $2}' > ${pop}.txt
grep -v ${pop} list2annoK12_noNA.txt | grep -v -f duplicates.txt | awk '{print $2}' > No_${pop}.txt

# produce chromosome level vcf files for each population and its inverse (that is, the rest of the individuals)
# the unmappable regions bed file was produced through Heng Li's mappability procedure
# https://lh3lh3.users.sourceforge.net/snpable.shtml
# using 100 bp reads from the reference genome

bcftools index -s \
${input} | cut -f 1 | while read C; do bcftools view \
-r ${C} -T ^unmappable_Shuhui_noorg_contigs.bed \
-S ${pop}.txt -o VCFS/${pop}_${C}_imputed.vcf ${input} ; done

bcftools index -s \
${input} | cut -f 1 | while read C; do bcftools view \
-r ${C} -T ^unmappable_Shuhui_noorg_contigs.bed \
-S No_${pop}.txt -o VCFS/No_${pop}_${C}_imputed.vcf ${input} ; done
