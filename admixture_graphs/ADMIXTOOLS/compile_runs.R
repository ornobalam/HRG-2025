
library(admixtools)
library(tidyverse)

models = read.table("models.txt",col.names=c("K","m"))

winners_list = list()

for (i in 1:nrow(models)){	
	df = data.frame()
	for (j in 1:200){
		tdf = readRDS(paste0("K",models$K[i],"/K",models$K[i],"_m",
					models$m[i],"_iter",j,"_models.rds"))
		df = rbind(df,tdf)	
	}
	df$class = isomorphism_classes2(df$graph)
  
    df = df %>%
    dplyr::group_by(class) %>% sample_n(1) %>%
    dplyr::arrange(score) %>% dplyr::ungroup() %>%
    dplyr::slice_min(order_by = score, n = 100)
	
    winners_list[[paste0(models$K[i],".",models$m[i])]] = df
}

saveRDS(winners_list,"find_graphs_winners.rds")
