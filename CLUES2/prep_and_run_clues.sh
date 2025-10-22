#!/bin/bash
#
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=30:00:00
#SBATCH --mem=250GB
#SBATCH --job-name=local
#SBATCH --array=1-88

module load r/gcc/4.3.1


source activate base
conda activate feems-env


ID=${SLURM_ARRAY_TASK_ID}
# this is a list of known functional SNPs, extracting chromosome and positions
chr=`head -n ${ID} QTNS/All_seg_qtns_genes.txt | tail -n 1 | awk '{print $1}'`
pos=`head -n ${ID} QTNS/All_seg_qtns_genes.txt | tail -n 1 | awk '{print $2}'`


# sampling 500 times from the ARG at the position of the SNP
../RELATE_SOFTWARE/scripts/SampleBranchLengths/SampleBranchLengths.sh \
-i ALL/ALL_HAPLOID/ALL_popsize_GAUT_UNIFORM_iter10_thresh0_pops_haploidized_chr${chr} \
-o ALL/ALL_HAPLOID_CLUES/Sampled_${chr}:${pos} \
-m 5.35e-9 \
--coal ALL/ALL_HAPLOID/ALL_popsize_GAUT_UNIFORM_iter10_thresh0_pops_haploidized.coal \
--dist ALL/ALL_HAPLOID/ALL_popsize_GAUT_UNIFORM_iter10_thresh0_pops_haploidized_chr${chr}.dist \
--format n \
--num_samples 500 \
--first_bp ${pos} \
--last_bp ${pos} \
--seed 1


# create derived.txt file for CLUES2
awk -v var=${pos} '$3==var' ALL/ALL_HAPLOID_HAPS/chr${chr}_ALL_haploidized.haps | tr ' ' '\n' | sed '1,5d' > ALL/ALL_HAPLOID_CLUES/Sampled_${chr}:${pos}_derived.txt

# calculate derived allele frequency for CLUES2 input
frq=`awk '{ total += $1 } END { print total/NR }' ALL/ALL_HAPLOID_CLUES/Sampled_${chr}:${pos}_derived.txt`

# convert RELATE newick outputs to CLUES2 format
python3 /scratch/oa832/GENOTYPER_files_STAY/CLUES2/RelateToCLUES.py \
--RelateSamples ALL/ALL_HAPLOID_CLUES/Sampled_${chr}:${pos}.newick \
--DerivedFile ALL/ALL_HAPLOID_CLUES/Sampled_${chr}:${pos}_derived.txt \
--out ALL/ALL_HAPLOID_CLUES/Sampled_${chr}:${pos}


# run CLUES2
python3 /scratch/oa832/GENOTYPER_files_STAY/CLUES2/inference.py \
--times ALL/ALL_HAPLOID_CLUES/Sampled_${chr}:${pos}_times.txt \
--popFreq ${frq} \
--coal ALL/ALL_HAPLOID/ALL_popsize_GAUT_UNIFORM_iter10_thresh0_pops_haploidized.coal \
--tCutoff 20000 \
--out  ALL/ALL_HAPLOID_CLUES/CLUES_${chr}:${pos}


# plot allele frequency trajectories
python3 /scratch/oa832/GENOTYPER_files_STAY/CLUES2/plot_traj.py \
--freqs ALL/ALL_HAPLOID_CLUES/CLUES_${chr}:${pos}_freqs.txt \
--post ALL/ALL_HAPLOID_CLUES/CLUES_${chr}:${pos}_post.txt \
--figure ALL/ALL_HAPLOID_CLUES/CLUES_${chr}:${pos}  \
--generation_time 1.0


