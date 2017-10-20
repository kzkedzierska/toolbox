import operator
from collections import Counter
import gzip
import numpy as np
from multiprocessing import Pool

### Mutations equivalence
muts_dict = {('C','G'):'C>G', ('G','C'):'C>G', ('C','A'):'C>A', ('G','T'):'C>A', ('C', 'T'):'C>T', ('G','A'):'C>T', ('A','T'):'A>T', ('T','A'):'A>T', ('A', 'G'):'A>G', ('T','C'):'A>G', ('A','C'):'A>C', ('T','G'):'A>C'}


"""
read in region sets, control set of mutations and tumor set(s) of mutations, return the summary of frequencies of mutations in a given sample (control or tumor) in the regions of interest

roughly:
sample\region set | R1 | R2 | ... | Rm
S1 | x1,1 | x1,2 | ... | x1,m
S2 | x2,1 | x2,2 | ... | x2,m
.
.
.
SN | xn,1 | xn,2 | ... | xn,m

//TODO//
sample descriptions
region descriptions
"""

""" GENOMES, just to make it clear
GRCh Build 38 stands for “Genome Reference Consortium Human Reference 38” and it is the primary genome assembly in GenBank; hg38 is the ID used for GRCh Build 38 in the context of the UCSC Genome Browser.
GRCh38 == hg38
GRCh37 == hg19 

The 1000 genome project:
For the phase 1 and phase 3 analysis we mapped to GRCh37. Our fasta file which can be found on our ftp site called human_g1k_v37.fasta.gz, it contains the autosomes, X, Y and MT but no haplotype sequence or EBV.
"""

 
### need to think if I should worry about Human Genome Project using b37 and TCGA maf files are using GRCh38 

### reading in regions sets and generating dictionary with locations



## Read in mafs, easy
maf_file_path = "./TCGA.PRAD.mutect.maf"
tumors_dict={}

with open(maf_file_path, "r") as fi:
	for ln in fi:
		if not ln.startswith("#") and ln.split("\t")[1] != "Hugo_Symbol":
			cols = ln.rstrip().split("\t")
			tumorID = cols[15]
			varianType_extended = '_'.join([cols[9], 'HOM']) if cols[11] == cols[12] else '_'.join([cols[9], 'HET'])
			row = cols[4:6]
			SNVtype = ""
			if cols[9] == "SNP":
				refAllele = cols[10]
				tAllele = cols[11] if cols[11] != refAllele else cols[12]
				SNVtype = muts_dict[(refAllele, tAllele)]
			row.extend([varianType_extended, SNVtype])
			#print(row)
			#print(ln)
			if tumorID in tumors_dict:
				tumors_dict[tumorID].append(row) 
			else:
				tumors_dict[tumorID] = [row]

np.save("tumors_dict.npy", tumors_dict)



def get_counts(matrix):
	"""
	matrix needs to have columns as follows:
	1 - chromosome
	2 - start position, start position <= end positions
	3 - variant type
	4 - SNP type, if variant type != "SNP" should consist of empty string 
	"""
	mut_matrix =  matrix.sort(key = operator.itemgetter(1, 2))
	### generate some stats that I want to use later!
	counts = Counter([x[2] for x in mut_matrix])
	SNPcounts = Counter([x[3] for x in mut_matrix if x != ""])
	return([{'matrix': mut_matrix, 'counts': counts, 'SNPcounts': SNPcounts}])

### {tumor barcode : {things} }

vcf_file_path = "/m/cphg-RLscratch/cphg-RLscratch/kzk5f/ref/one_k_genomes/all_snps.vcf.gz"
samples_dict={}
### Read in VCF, difficult...
with gzip.open(vcf_file_path, "rt") as fi:
	for ln in fi:
		

np.save("onek_samples.npy", samples_dict)
### list.extend([string]) == list.append(string)

def process_line(line):
    if line.startswith("#CHR"):
    	ids = line.rstrip().split("\t")[9:]
    
	if not line.startswith("#"):
		fields = ln.rstrip().split("\t")
		possible_alleles = [fields[3]]
		possible_alleles.extend(fields[4].split(",") )
		"""
		. - call cannot be made in this specific position // will assume reference allele
		0 - reference allele
		1 - for the first allele listed in ALT, 2 for second...
		| - genotype phased
		"""
		sample_compos = [s.replace('.','0') for s in fields[9:]]
		# we're interested only in those that have a specific variant
		which_to_add = [(i,x) for i,x in enumerate(sample_compos) if x != '0|0']
		line_res = map(tempLambda, which_to_add)
		return(line_res)

#vcf_file_path = "/m/cphg-RLscratch/cphg-RLscratch/kzk5f/ref/one_k_genomes/all_snps.vcf.gz"
vcf_file_path = "./all.try.gz"
pool = Pool(16)
with gzip.open(vcf_file_path) as source_file:
    # chunk the work into batches of 4 lines at a time
    results = pool.map(process_line, source_file, 16)

print(results)

def tempLambda(wtadd):
	ind, sample_comp = wtadd
	SNVtype = ""
	changed = [int(x) for x in sample_comp.split("|")]
	changed.sort()
	typExt = "HOMO" if changed[0] == changed[1] else "HET"
	#print(which_to_add)

	### TEST THE MUTATION TYPE
	if len(possible_alleles[0]) < len(possible_alleles[changed[1]]):
		### INSERTION
		varianType_extended='_'.join(["INS", typExt])
	elif len(possible_alleles[0]) > len(possible_alleles[changed[1]]):
		### DELETION
		varianType_extended='_'.join(["DEL", typExt])
	elif len(possible_alleles[0]) == len(possible_alleles[changed[1]]) == 1:
		### SNP
		varianType_extended = '_'.join(["SNP", typExt])
		SNVtype = muts_dict[possible_alleles[0], possible_alleles[changed[1]]]
	else:
		print("Houston, we have a problem!")
		print(fields)
		print(len(possible_alleles[0]))
		print(len(possible_alleles[changed[1]]))
		print(possible_alleles)
	
	print([ids[ind], fields[0], fields[1], varianType_extended, SNVtype])
	return(inds[ind], [fields[0], fields[1], varianType_extended, SNVtype])
