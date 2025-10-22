#!/bin/bash
#
#SBATCH --verbose
#SBATCH --job-name=dep
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --mem=3G
#SBATCH --cpus-per-task=1
#SBATCH --array=1-8


file=`head -n ${SLURM_ARRAY_TASK_ID} bam_files.txt | tail -n 1`
id=`echo $file | cut -d'.' -f1`

module load samtools/intel/1.14

samtools depth -a 4_mapping/${file}  |  awk '{sum+=$3} END { print "Average = ",sum/NR}' > merged_coverages/${id}_coverage.txt
