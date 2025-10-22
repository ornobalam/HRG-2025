#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=40:00:00
#SBATCH --mem=20GB
#SBATCH --job-name=vqsr

module load gatk/4.2.0.0
module load r/gcc/4.1.0

gatk VariantRecalibrator \
	-R /scratch/oa832/taiwan_files/vcf/11pop/indica_ref/REFERENCE/GCA_002151415.1_R498.Genome.version1_genomic.fa \
	-V ../Shuhui_JAP_456_SNP_biallel.vcf.gz  \
	--resource:HDRA,known=true,training=true,truth=false Shuhui_JAP_456_SNP_biallel_HDRA_filt.vcf.gz  \
	--resource:Truth,known=false,training=true,truth=true Shuhui_JAP_456_SNP_biallel_Truth.vcf.gz \
	-an QD -an FS -an MQ -an MQRankSum -an ReadPosRankSum -mode SNP -tranche 100.0 -tranche 99.9 -tranche 99.0 \
	-tranche 90.0 -O Shuhui_456_SNP_HT.recal \
	--tranches-file Shuhui_456_SNP_HT.tranches --rscript-file Shuhui_456_SNP_HT.R 



gatk ApplyVQSR \
	-R /scratch/oa832/taiwan_files/vcf/11pop/indica_ref/REFERENCE/GCA_002151415.1_R498.Genome.version1_genomic.fa \
	-V ../Shuhui_JAP_456_SNP_biallel.vcf.gz -mode SNP --recal-file Shuhui_456_SNP_HT.recal \
	--tranches-file Shuhui_456_SNP_HT.tranches --truth-sensitivity-filter-level 90 \
	-O Shuhui_456_SNP_biallel_HT_VQSR90_unfiltered.vcf.gz

gatk ApplyVQSR \
        -R /scratch/oa832/taiwan_files/vcf/11pop/indica_ref/REFERENCE/GCA_002151415.1_R498.Genome.version1_genomic.fa \
        -V ../Shuhui_JAP_456_SNP_biallel.vcf.gz -mode SNP --recal-file Shuhui_456_SNP_HT.recal \
        --tranches-file Shuhui_456_SNP_HT.tranches --truth-sensitivity-filter-level 90 \
	--exclude-filtered \
        -O Shuhui_456_SNP_biallel_HT_VQSR90.vcf

./vcf_HWE_filter.pl -i Shuhui_456_SNP_biallel_HT_VQSR90.vcf -o Shuhui.txt -f -n 2 -d 4 -s 0.5
