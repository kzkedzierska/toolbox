import pandas
import numpy as np

df = pandas.read_csv(dist_matrix, index_col=0) 
# nested dict
df_dict = df.to_dict()

dna_dist = dict()
# ugly way to get from nested dictionary to tuple dictionary so 
# pairwise2.align will accept it

for key in df_dict:            
	for subkey in df_dict[key]:
		if not dna_dist.get(tuple(sorted((key, subkey)))):
			dna_dist[tuple(sorted(((key, subkey))))] = df_dict.get(key).get(subkey)

np.save('nuc.npy', dna_dist) 