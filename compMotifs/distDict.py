#!python3_path required
import pandas
import numpy as np
import argparse

parser.add_argument("dist_matrix", type=str, help="distance matrix in cvs format")
parser.add_argument("out_path", type=str, help="output directory")
args = parser.parse_args()

name = args.dist_matrix.strip(".csv")
df = pandas.read_csv(args.dist_matrix, index_col=0) 
# nested dict
df_dict = df.to_dict()

dna_dist = dict()

# ugly way to get from nested dictionary to tuple dictionary so 
# pairwise2.align will accept it
for key in df_dict:            
	for subkey in df_dict[key]:
		if not dna_dist.get(tuple(sorted((key, subkey)))):
			dna_dist[tuple(sorted(((key, subkey))))] = df_dict.get(key).get(subkey)

np.save("/".join([args.out_path, ".".join([name, 'npy'])]), dna_dist) 