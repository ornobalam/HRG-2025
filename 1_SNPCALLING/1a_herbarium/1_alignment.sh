#!/bin/bash
#
#SBATCH --verbose
#SBATCH --job-name=HAP
#SBATCH --time=120:00:00
#SBATCH --nodes=1
#SBATCH --mem=40G
#SBATCH --cpus-per-task=10
#SBATCH --array=1-96

module load samtools/intel/1.14
module load fastqc/0.11.9
module load r/gcc/4.1.2
module load jdk/11.0.9
module load bwa/intel/0.7.17

TABLE=nova_batch_1.txt

NO=${SLURM_ARRAY_TASK_ID}

ID=`head -n ${NO} ${TABLE} | tail -n 1 | awk '{print $2}' `
F1=`head -n ${NO} ${TABLE} | tail -n 1 | awk '{print $3}' `
F2=`head -n ${NO} ${TABLE} | tail -n 1 | awk '{print $4}' `


REF='/scratch/oa832/taiwan_files/vcf/11pop/indica_ref/REFERENCE/GCA_002151415.1_R498.Genome.version1_genomic.fa'

# Remove adapter sequences
AdapterRemoval --file1 ${F1} --file2 ${F2} \
--basename 2_trimmed_merged/${ID} --collapse --gzip --minlength 35 --threads 10

# Perform quality control check
fastqc -t 10 -o 3_quality_control/ 2_trimmed_merged/${ID}.collapsed.gz \
2_trimmed_merged/${ID}.pair1.truncated.gz 2_trimmed_merged/${ID}.pair2.truncated.gz

# Perform alignment
bwa aln -t 10 -l 1024 -f 4_mapping/${ID}.collapsed.sai ${REF} 2_trimmed_merged/${ID}.collapsed.gz

bwa samse -r @RG\\tID:${ID}\\tSM:${ID}\\tPL:ILLUMINA -f 4_mapping/${ID}.sam ${REF} 4_mapping/${ID}.collapsed.sai 2_trimmed_merged/${ID}.collapsed.gz

# Compute statistics including percentage of mapped reads to reference
samtools flagstat -@ 10 4_mapping/${ID}.sam > 4_mapping/${ID}_flagstats.log

# Convert to BAM and sort
samtools view -@ 10 -F 4 -Sbh -o 4_mapping/${ID}.mapped.bam 4_mapping/${ID}.sam
samtools sort -@ 10 -o 4_mapping/${ID}.mapped.sorted.bam 4_mapping/${ID}.mapped.bam

# Remove PCR dupl
#java -Djava.io.tmpdir=/scratch/oa832/tmp -jar /scratch/oa832/DeDup/build/libs/DeDup-0.12.8.jar -i 4_mapping/${ID}.mapped.sorted.bam -m -o 4_mapping
