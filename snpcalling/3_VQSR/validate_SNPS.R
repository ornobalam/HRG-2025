library(dplyr)
library(stringr)


args = commandArgs(trailingOnly=TRUE)

vcf <- read.table(paste0("vcf_",args[1],".txt"))
nip_shu <- read.table(paste0("known_sets/Shuhui_",args[1],".bed"))

colnames(vcf) <- c("C","P","R","A")
colnames(nip_shu) <- c("C","S","P","R","A","X","ID")

nip_shu$R <- as.character(nip_shu$R)
nip_shu$A <- as.character(nip_shu$A)

vcf$R <- as.character(vcf$R)
vcf$A <- as.character(vcf$A)

nip_shu %>% rowwise() %>% mutate(M = str_c(str_sort(c(R,A)),collapse = "") ) -> nip_shu

vcf %>% rowwise() %>% mutate(M = str_c(str_sort(c(R,A)),collapse = "") ) -> vcf

final <- left_join(vcf, nip_shu, by= c("C","P","M"))

final %>% dplyr::filter(is.na(ID)) %>% dplyr::select(C,P) -> snp_list

write.table(snp_list, file = paste0("non_val_",args[1],".txt"), quote = F, col.names = F, row.names =F ,sep = "\t")
