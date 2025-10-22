#!/bin/bash

module load r/gcc/4.3.1

# compile the results of the find_graphs and keep the best admixture graphs for
# all model configurations

Rscript compile_runs.R
