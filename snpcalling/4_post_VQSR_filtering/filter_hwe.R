args = commandArgs(trailingOnly=TRUE)

# args[1] is the name of the input .hardy file
# args[2] is the maximum heterozygosity = 5 * (1-F)
# args[3] is the output file name

library(dplyr)

hardy = read.table(args[1]) 

hardy %>% rowwise() %>% 
	dplyr::mutate(sum = sum(V5,V6,V7)) %>% 
	dplyr::mutate(maxOb = V9 * sum * as.numeric(args[2])) %>%
	dplyr::filter(V6 < maxOb) %>% dplyr::select(V2) -> snp_list

write.table(snp_list,args[3],quote=FALSE,col.names=FALSE,row.names=FALSE)
