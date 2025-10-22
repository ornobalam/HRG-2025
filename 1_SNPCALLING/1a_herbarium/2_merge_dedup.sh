#!/bin/bash
#
#SBATCH --verbose
#SBATCH --job-name=merge
#SBATCH --time=30:00:00
#SBATCH --nodes=1
#SBATCH --mem=10G
#SBATCH --cpus-per-task=1
#SBATCH --array=4

module load samtools/intel/1.14
module load jdk/11.0.9

# two column file with each line containing two bam files per sample
# each library was sequenced as part of two novaseq runs
file=libraries.txt

SLURM_ARRAY_TASK_ID=1

b1=`head -n ${SLURM_ARRAY_TASK_ID} $file  | tail -n 1 | awk '{print $1}'`
b2=`head -n ${SLURM_ARRAY_TASK_ID} $file  | tail -n 1 | awk '{print $2}'`

name=`echo ${b1} | cut -d'/' -f2`
echo ${name:2}


samtools merge -o merged_bams/${name:2} $b1 $b2

java -Djava.io.tmpdir=/scratch/oa832/tmp -jar /scratch/oa832/DeDup/build/libs/DeDup-0.12.8.jar -i merged_bams/${name:2} \
-m -o ./

# For samples that went through two separate library preps before sequencing, merging was carried out after
# removing PCR duplicates
