#!/bin/bash
#
#SBATCH --verbose
#SBATCH --job-name=HAP
#SBATCH --time=168:00:00
#SBATCH --nodes=1
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1

module purge
module load nextflow/20.10.0


# the csv file contains four columns
# sample ID, sequence ID, fastq file 1, fastq file 2
# several samples have multiple sequence IDs, which are merged in the pipeline after alignment
# the japonica_mbe.csv and wei_sra.csv files in this directory provide the lists that were run with this pipeline

nextflow run process_3k_v0.2.nf -c process_3k_v0.2.conf \
	--ref /scratch/oa832/SNPCALLING/REFERENCE/R498_Chr.fasta  \
	--list landraces.csv \
	--exe slurm

# this pipeline produces individual g.vcf.gz files for each sample
