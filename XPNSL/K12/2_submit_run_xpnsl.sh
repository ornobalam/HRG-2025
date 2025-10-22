#!/bin/bash

while IFS= read -r line
do
sbatch run_xpnsl.sh ${line}
done < K12_pops.txt
