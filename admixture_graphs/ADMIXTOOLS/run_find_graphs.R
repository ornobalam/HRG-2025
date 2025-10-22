args = commandArgs(trailingOnly=TRUE)

library(admixtools)
library(tidyverse)

K=args[1]
m=args[2]
iter=args[3]
seed=args[4]

anno = read.table(paste0("anno_K",K,"_outgroup.txt"),col.names = c("POP","ID"))

anno = anno %>% dplyr::filter(!ID %in% c("HRB0316","HRB0334"))

inds = anno$ID
pops = anno$POP

# the input file contains 19 Oryza barthii individuals to provide outgroup allele frequency information
f2 = f2_from_geno("../BARTHII/Shuhui_JAP_BARTHII_LDpruned_filtered", inds = inds, pops = pops,auto_only = FALSE, outpop = "Barthii",outpop_scale = TRUE)

set.seed(as.numeric(seed))
opt_results = find_graphs(f2, numadmix = as.numeric(m), outpop = 'Barthii',stop_gen=200,stop_gen2=25,
                          opt_worst_residual = FALSE)


winners = opt_results %>% slice_min(order_by = score, n = 5)

saveRDS(winners,paste0("K",K,"/K",K,"_m",m,"_iter",iter,"_models.rds"))
