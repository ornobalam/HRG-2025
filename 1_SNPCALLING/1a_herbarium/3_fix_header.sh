#!/bin/bash
#
#SBATCH --verbose
#SBATCH --job-name=HAP
#SBATCH --time=04:00:00
#SBATCH --nodes=1
#SBATCH --mem=10G
#SBATCH --cpus-per-task=1
#SBATCH --array=49

module load jdk/1.8.0_271
module load samtools/intel/1.14

bam=`head -n ${SLURM_ARRAY_TASK_ID} merged_bams.txt | tail -n 1`

# sort the newly merged file
java -Djava.io.tmpdir=/scratch/oa832/tmp -jar /home/oa832/tools/picard.jar SortSam \
INPUT=merged_bams/${bam} OUTPUT=merged_bams/${bam::-4}_picard.bam SORT_ORDER=coordinate

# fix the sample IDs in the header of the bam files
samtools view -H merged_bams/${bam::-4}_picard.bam | sed -e 's/SM:f.*HR/SM:HR/g' | samtools reheader - \
merged_bams/${bam::-4}_picard.bam > merged_bams/${bam::-4}_picard_rh.bam

# index the re-headered bam files
java -Djava.io.tmpdir=/scratch/oa832/tmp -jar /home/oa832/tools/picard.jar BuildBamIndex \
INPUT=merged_bams/${bam::-4}_picard_rh.bam OUTPUT=merged_bams/${bam::-4}_picard_rh.bai 
