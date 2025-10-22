#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=56:00:00
#SBATCH --mem=20GB
#SBATCH --job-name=haplo
#SBATCH --array=1-8

module load gatk/4.2.0.0


# list of the final merged bam files with PCR duplicates removed
bam=`head -n ${SLURM_ARRAY_TASK_ID} merged_bams_reheadered.txt | tail -n 1`
name=`echo $bam | cut -d'.' -f1`

gatk HaplotypeCaller \
	-I merged_bams/${bam} \
        -R /scratch/oa832/taiwan_files/vcf/11pop/indica_ref/REFERENCE/GCA_002151415.1_R498.Genome.version1_genomic.fa \
	-O ../Shuhui_herbaria_gvcfs/${name}.g.vcf.gz \
	-ERC GVCF
