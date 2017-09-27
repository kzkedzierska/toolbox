#!python3_path required
import numpy as np
import re
from Bio import pairwise2 
from Bio.Seq import Seq
from Bio.Alphabet.IUPAC import *
import itertools
import os

__author__ = "Katarzyna Kedzierska"
__email__ = "kzk5f@virginia.edu"

#set up by config script with python3 
script_path = "script_path required"

def main():
	import argparse

	parser = argparse.ArgumentParser(description='Compare motifs from homer results files and keeps non-redundant ones or, if run in compare mode, compares the motifs from two result files and outputs: pairs, and uniques motifs from each file.')
	parser.add_argument("file1", type=str, help="homer output file with motifs from condition A")
	parser.add_argument("-f", "--file2", action="store", help = "homer output file with motifs from condition B")
	parser.add_argument("-o", "--out_path", action="store", default = ".", help = "Output directory, default: .")
	parser.add_argument("-t", "--threshold", action="store", default = 0.7, help="similarity threshold, default: 0.7")
	parser.add_argument("-g", "--gap_penalty", action="store", default = -2, help="Gap penalty for the local alignment, gap_pen <= 0, default: -2")
	parser.add_argument("-e", "--ext_gap_penalty", action="store", default = -2, help="Penalty for the extension of the gap in the alignment, gap_pen <= ext_gap_pen <= 0, default: -2")
	parser.add_argument("-p", "--pval", action="store", default = '1e-50', help="discard all the motifs from final result html file above this p-value threshold, default: 1e-50")
	parser.add_argument("-c", "--cpu_num", action="store", default = 1, help="Number of threads passed to homer when scanning the motifs against the known motifs database")
	parser.add_argument("-m", "--dist_matrix", action="store", help = "Distance matrix in csv file format")
	parser.add_argument("-d", "--dist_dict", action="store", help = "Distance dictionary in npy file format")

	args = parser.parse_args()


	### Check options
	# TODO: add creating a dist dict from matrix
	if args.dist_matrix is not None:
		run distDic.py args.dist_matrix args.out_path
		dna_dist_file = "/".join([args.out_path, ".".join([name, 'npy'])])
		dna_dist = np.load(dna_dist_file).item()

	if args.dist_dict is None:
		dna_dist = np.load('/'.join([script_path, "nuc.npy"])).item()
	elif re.match(".*.npy", args.dist_dict) is not None:
		dna_dist = np.load(args.dist_dict).item()
	else:
		print("Is your distance dictionary in numpy .npy format?")

	parameters = {}
	parameters['dna_dist'] = dna_dist
	parameters['threshold'] = args.threshold
	parameters['gap_penalty'] = args.gap_penalty
	parameters['ext_gap_penalty'] = args.ext_gap_penalty
	
	#because parameters is a class variable with this statement I'm assigning parameters to all motifSet instances
	motifSet.out_path = args.out_path
	#again, out_path is a class variable since it's the same for all objects
	motifSet.parameters = parameters

		
	if args.file2 is not None:
		setAB = bothSets(args.file1, args.file2)
		setAB.compare()
		setAB.get_non_redundant_common()

		get_results(setAB.set1, args.cpu_num, args.pval)
		get_results(setAB.set2, args.cpu_num, args.pval)
		get_results(setAB, args.cpu_num, args.pval, mode = 'duo')
		
	else:
		setA = motifSet(args.file1)
		setA_unique = setA.reduce() 
		homer_filter(setA.file_path, setA_unique, setA.out_file)

class motifSet:
	"""
	everything that needs to be done for reduce mode of this script and preprocessing the sets for compare
	"""
	pattern = re.compile('.*[^/]/([a-zA-Z0-9]*)\.[a-zA-Z0-9]*')
	parameters = {}
	out_path = ''

	def __init__(self, file_path):
		self.file_path = file_path
		self.name = re.search(self.__class__.pattern, self.file_path).group(1)
		self.out_file = "/".join([self.__class__.out_path, "".join([self.name, ".motifs"])])
		#works only on homer type of files for now
		with open(self.file_path, "r") as fi:
			motifs_set = []
			motifs_info = {}
			
			for ln in fi:
				if ln.startswith(">"):
					sequence = ln.strip(">").split("\t")[0]
					pval = ln.split("\t")[5].split(",")[2].strip("P:")
					motifs_set.append(sequence)  
					motifs_info[sequence] = float(pval)
		self.motifs_set = set(motifs_set)
		self.motifs_info = motifs_info

	def get_duplicates(self):
		cartesian = list(itertools.combinations(self.motifs_set, 2))
		duplicates = set(filter(None, map(lambda x: is_similiar(x, self.parameters, mode = "reduce", pvals = self.motifs_info), cartesian)))
		return duplicates

	def reduce(self):
		duplicates = self.get_duplicates()
		unique = self.motifs_set - duplicates
		return unique

class bothSets(motifSet):
	"""
	class for two motif sets objects
	everything that needs to be done for compare mode of this script and preprocessing the sets for compare
	"""

	def __init__(self, file_path1, file_path2):
		#set1 = super().__init__(file_path1)
		#set2 = super().__init__(file_path2) 
		self.set1 = motifSet(file_path1)
		self.set2 = motifSet(file_path2)

		#not sure if so many attributes are necessary, afraid I overcomplicated it
		self.name = '_'.join([self.set1.name, self.set2.name])
		self.out_file = "/".join([self.__class__.out_path, "".join([self.name, ".motifs"])])

	def compare(self):
		"""
		"""
		self.pairs = self.get_pairs()
		x_not_unique = set([item[0] for item in self.pairs])
		self.set1.unique = self.set1.reduce() - x_not_unique
		y_not_unique = set([item[1] for item in self.pairs])
		self.set2.unique = self.set2.reduce() - y_not_unique

	def get_pairs(self):
		cartesian = list(itertools.product(self.set1.reduce(), self.set2.reduce()))
		pairs = list(filter(lambda x: is_similiar(x, parameters = self.parameters), cartesian))
		return pairs

	def get_duplicates_sets(self):
		cartesian = list(itertools.combinations(self.motifs_set, 2))
		duplicates = set(filter(None, map(lambda x: is_similiar(x, self.parameters, mode = "reduce", pvals = self.motifs_info), cartesian)))
		return duplicates

	def reduce_sets(self):
		duplicates = self.get_duplicates_sets()
		unique = self.motifs_set - duplicates
		return unique

	def get_non_redundant_common(self):
		self.motifs_info = {**self.set1.motifs_info, **self.set2.motifs_info}
		take_from_1 = set([item[0] for item in self.pairs])
		take_from_2 = set([item[1] for item in self.pairs])
		for f in set(self.set1.motifs_info.keys()) & set(self.set2.motifs_info.keys()):
			if self.set1.motifs_info[f] < self.set2.motifs_info[f]:
				self.motifs_info[f] = self.set1.motifs_info[f]
				take_from_2 = take_from_2 - set(f)
			else:
				self.motifs_info[f] = self.set2.motifs_info[f]
				take_from_1 = take_from_1 - set(f)
		self.motifs_set = set(itertools.chain(*self.pairs))
		self.common_reduced = self.reduce_sets()
		self.set1_nr = self.common_reduced & take_from_1
		self.set2_nr = self.common_reduced & take_from_2

def homer_filter(filePath, whatToKeep, filteredFile, openOption = "w"):
	with open(filteredFile, openOption) as newFile:
		with open(filePath, "r") as file:
			canSaveLines = False
			for line in file:
				sequence = line.strip(">").split("\t")[0]
				if (line.startswith(">")):
					canSaveLines = sequence in whatToKeep
				if canSaveLines:
					newFile.write(line)

def is_similiar(motif_tuple, parameters, mode = "compare", pvals = {}):
	"""
	compare the alignment score with set threshold and depending on mode, either return True or the redundant motif
	redundant motif is chosen based on pvalue
	"""
	threshold = parameters['threshold']

	score, score_rev = align(motif_tuple, parameters)
	if score > threshold or score_rev > threshold:
		if mode == "compare":
			return True
		elif mode == "reduce":
			if pvals[motif_tuple[0]] < pvals[motif_tuple[1]]:
				return motif_tuple[1]
			else:
				return motif_tuple[0]
		else:
			print("Invalid mode")

def align(motif_tuple, aligner_parameters):
	motifA = Seq(motif_tuple[0], IUPACAmbiguousDNA())
	motifB = Seq(motif_tuple[1], IUPACAmbiguousDNA())
	motifB_reverse = motifB.reverse_complement()
	dna_dist, gap_penalty, ext_gap_penalty = aligner_parameters['dna_dist'], aligner_parameters['gap_penalty'], aligner_parameters['ext_gap_penalty']
	score = pairwise2.align.localds(motifA, motifB, dna_dist, gap_penalty, ext_gap_penalty, score_only = True) / min(len(motifA), len(motifB))
	score_rev = pairwise2.align.localds(motifA, motifB_reverse, dna_dist, gap_penalty, ext_gap_penalty, score_only = True) / min(len(motifA), len(motifB_reverse))
	return score, score_rev

def scan_againts_known_motifs(input_file, output_directory, cpus, pvalue):
	os.system("compareMotifs.pl %s %s -reduceThresh 1.0 -cpu %s -pvalue %s" % (input_file, output_directory, cpus, pvalue))

#This should be a class method, TODO: make it one
def get_results(motif_set, cpu, p_val, mode = ''):
	if mode != 'duo':
		homer_filter(motif_set.file_path, motif_set.unique, motif_set.out_file)
		scan_againts_known_motifs(motif_set.out_file, motif_set.name, cpu, p_val)
	else:
		homer_filter(motif_set.set1.file_path, motif_set.set1_nr, motif_set.out_file)
		homer_filter(motif_set.set2.file_path, motif_set.set2_nr, motif_set.out_file, openOption = "a")
		scan_againts_known_motifs(motif_set.out_file, motif_set.name, cpu, p_val)

if __name__=='__main__': 
    main()