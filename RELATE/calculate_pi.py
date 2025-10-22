import numpy as np
import pandas as pd
import sys

def get_pi(pi_file,unmapped_file):
    pi_windows = pd.read_csv(pi_file,sep = "\t",header=None)

    unmapped = pd.read_csv(unmapped_file,sep = "\t",header=None)
    unmapped[3] = unmapped[2] - unmapped[1]

    pi_windows['unmapped'] = unmapped.groupby(0)[3].sum().to_numpy()[0:12]
    pi_windows['effective_length'] = pi_windows[2] - pi_windows['unmapped']
    pi_windows['weighted_sum'] = pi_windows[4] * pi_windows[2]
    pi = sum(pi_windows['weighted_sum']) / sum(pi_windows['effective_length'])
    return pi

pi=get_pi(sys.argv[1],"unmappable_Shuhui.bed")

# scaling the mutation rate by the number kept after filtering to keep 
# sites with fixed alleles in barthii
mut_scale = 3040580/3695494

Ne = 2 * pi/(mut_scale * 6.5e-9 * 4) 

print(Ne)
