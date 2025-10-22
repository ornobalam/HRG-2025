#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=48:00:00
#SBATCH --mem=20GB
#SBATCH --job-name=geno


module load gatk/4.2.0.0
module load plink/1.90b6.21
module load bcftools/intel/1.14
module load plink2/20230417

chrom=`head -n ${SLURM_ARRAY_TASK_ID} chrom.intervals | tail -n 1`


# Genotype barthii for sites present in japonica

# japonica_456_snps.bed contains the positions of all genotyped SNPs in japonica

awk '{print $1"\t"$4-1"\t"$4}' ../JAPONICA/Shuhui_456_SNP_biallel_HT_VQSR90_het_mac_geno.bim > japonica_456_snps.bed

gatk GenotypeGVCFs \
        -V ../Shuhui_BAR_19.g.vcf.gz \
        -R /scratch/oa832/taiwan_project/vcf/11pop/indica_ref/REFERENCE/GCA_002151415.1_R498.Genome.version1_genomic.fa \
        -O japonica_BAR_19.vcf.gz \
	-L japonica_456_snps.bed \
	-all-sites


# for the actual polarization of the japonica SNPs -
# that is, setting the barthii fixed allele as the reference allele
# I use the default tendency of plink to load the major allele as the A2 allele
# when exporting as vcf, plink treats the A2 allele as the reference allele

OUTG=japonica_BAR_19.vcf.gz
TARG=Shuhui_456_SNP_biallel_HT_VQSR90_het_mac_geno_imputed.vcf.gz
TARG_DIR=../IMPUTE


# select sites that are represented in at least half of the barthii individuals
# and that have a minor allele frequency of 0, hence fixed alleles
# for the final version of the analysis, I modified the condition to also include the HAN1 site
# and treat its major allele (at 0.92 frequency) as the ancestral allele even though it is not fixed
# in barthii
bcftools view -i 'MAF==0 && F_MISSING < 0.5' -o ${OUTG::-7}_filtered.vcf.gz -Oz \
${OUTG}

# convert to plink bed format, which sets the major allele as the A2 allele
plink --vcf ${OUTG::-7}_filtered.vcf.gz --allow-extra-chr --make-bed --out ${OUTG::-7}_fixed

# retrieve the positions of the fixed sites
awk '{print $1"\t"$4}' ${OUTG::-7}_fixed.bim > ${OUTG::-7}_fixed.regions

# using the positions from the last step, retrieve barthii-fixed SNPs from japonica imputed SNPs
bcftools view -R ${OUTG::-7}_fixed.regions -Oz -o ${TARG::-7}_outgroup.vcf.gz ${TARG_DIR}/${TARG}

# get the base identity of the ancestral (or major/fixed allele in barthii) alleles
awk '{print $1":"$4"\t"$6}' ${OUTG::-7}_fixed.bim > ${OUTG::-7}_fixed_ancestral.txt

# force the ancestral allele to be A2, that is, the reference allele
plink2 --vcf ${TARG::-7}_outgroup.vcf.gz --ref-allele 'force' ${OUTG::-7}_fixed_ancestral.txt 2 1 \
--allow-extra-chr --export vcf --out ${TARG::-7}_prepolarized

# the above will fail when the ancestral base is different from the two present at each position in japonica
# make a list of these sites
grep "ref-allele mismatch" ${TARG::-7}_prepolarized.log | awk '{print $7}' | sed "s/[']//g" | cut -d'.' -f1,2 > 
${TARG::-7}_triallelic.snps

# exclude the mismatched sites
plink2 --vcf ${TARG::-7}_prepolarized.vcf --allow-extra-chr --exclude ${TARG::-7}_triallelic.snps \
--export vcf --out ${TARG::-7}_polarized
