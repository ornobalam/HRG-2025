#!/bin/bash

# given a file with all the known ages of the herbarium specimens
# produce a text file with all sample ages (assign 0 for all non-herbarium specimens)
# in the format required by RELATE

sed '1d' ALL/ALL_HAPS/chr1_ALL.poplabels \
| join - herbarium_japonica_ages.txt -1 1 -2 1 -a 1 \
| awk '{$5=$5!=""?$5:"0"}1' | awk '{print $5}'  > ALL/ALL_haploidized_sample_ages.txt


