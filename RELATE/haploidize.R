# creating pseudodiploid files from existing haps and poplabels files
library(tidyverse)

args = commandArgs(trailingOnly = TRUE)

prefix = args[1]


haps_file = paste0(prefix,"_masked.haps")

sample_file = paste0(prefix,".sample")


thap = read.table(haps_file)

tsample = read.table(sample_file,skip=2)
tsample$colnum = 1:nrow(tsample)

pair_df = data.frame()

inds = tsample$V1

  
df = data.frame(inds)
  
  
df$c1 = NA

set.seed(123)
which_chrom = sample(c(4,5),nrow(df),replace=TRUE)

for (i in 1:nrow(df)){
  i1 = df$ind[i]
  df$c1[i] = (2*tsample$colnum[which(tsample$V1 == i1)])+ which_chrom[i]
  
}


nhap = thap[,c(1:5,df$c1)]

df = df %>% dplyr::mutate(ID = paste0(inds))

nsample = data.frame(ID_1 = 0, ID_2 = 0, missing = 0)

nsample_sub = data.frame(ID_1 = df$ID, ID_2 = NA,
                         missing = 0)

nsample = rbind(nsample,nsample_sub)



write.table(nhap,paste0(prefix,"_haploidized.haps"),quote=FALSE,
            row.names = FALSE,col.names=FALSE,
            sep=" ")

write.table(nsample,paste0(prefix,"_haploidized.sample"),quote=FALSE,
            row.names = FALSE,col.names=TRUE,
            sep="\t")




