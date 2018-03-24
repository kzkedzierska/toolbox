#!/usr/bin/python3
import csv
import getopt
import json
import sys
from operator import itemgetter

pwd=''
motdb=''

def main(argv):
    global pwd
    global motdb
    try:
        opts, args = getopt.getopt(argv, "d:m:", ["pwd=,motdb="])
    except getopt.GetoptError:
        print('jsonExtract.py -d <directory> -m <motifDB>')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print('jsonExtract.py -d <directory> -m <motifDB>')
            sys.exit()
        elif opt in ("-d", "--directory"):
            pwd = arg
        elif opt in ("-m", "--motifs"):
            motdb = arg
            
if __name__ == "__main__":
    main(sys.argv[1:])

with open(''.join([pwd, '/memeChipOutput/JSON.txt'])) as data_file:
    data = data_file.readlines()
    dp = json.loads(data[0])

### Families DB
reader = csv.reader(open(motdb, 'r'))
families = dict(reader)

# rewrite the code below,
# not a pythonic way, but what do I know, it's all not pythonic way after all since I don't know how to python :p
### DREME TOMTOM
dreme_tomtom = []
reader = csv.DictReader(open(''.join([pwd, '/memeChipOutput/dreme_tomtom_out/tomtom.txt']), 'r'), delimiter='\t')
next(reader)
for row in reader:
    try:
        dreme_tomtom.append((row['#Query ID'], row['Target ID'].split('_')[0], families[row['Target ID'].split('_')[0]],
                             row['E-value']))
    except KeyError:
        dreme_tomtom.append((row['#Query ID'], row['Target ID'].split('_')[0], '', row['E-value']))

### MEME TOMTOM
meme_tomtom = []
reader = csv.DictReader(open(''.join([pwd, '/memeChipOutput/meme_tomtom_out/tomtom.txt']), 'r'), delimiter='\t')
next(reader)
for row in reader:
    try:
        meme_tomtom.append((row['#Query ID'], row['Target ID'].split('_')[0], families[row['Target ID'].split('_')[0]],
                            row['E-value']))
    except KeyError:
        meme_tomtom.append((row['#Query ID'], row['Target ID'].split('_')[0], '', row['E-value']))

db = []
db_clusters = []
cluster = 0
for group in dp['groups']:
    cluster += 1  # it's easier for humans to look at cluster numbering starting at 1,
    # remember to subtract if ever needed to access the cluster from dp['groups']
    for mot in group:
        tmp = dp['motifs'][mot['motif']]
        try:
            alg = tmp['alt']
            if alg == 'DREME':
                fams = set(list(filter(('').__ne__, set([item[2] for item in dreme_tomtom if item[0] == tmp['id']]))))
                tfs = set([item[1] for item in dreme_tomtom if item[0] == tmp['id']])
            elif alg == 'MEME':
                fams = set(list(filter(('').__ne__, set([item[2] for item in meme_tomtom if item[0] == tmp['id']]))))
                tfs = set([item[1] for item in meme_tomtom if item[0] == tmp['id']])
            db.append((cluster, mot['motif'], tmp['evalue'], alg, tmp['id'], tfs, fams))
        except KeyError:
            try:
                db.append((cluster, mot['motif'], tmp['evalue'], 'CentriMo', tmp['id'], set([tmp['id'].split('_')[0]]),
                           set([families[tmp['id'].split('_')[0]]])))
            except KeyError:
                db.append((cluster, mot['motif'], tmp['evalue'], 'CentriMo', tmp['id'], set([tmp['id'].split('_')[0]]),
                           set([''])))
    # create summary for all clusters, together with the link to the logo
    famis = set()
    tefs = set()
    tmp2 = [itemgetter(1, 2, 5, 6)(x) for x in db if x[0] == cluster]
    evalu = tmp2[0][1]
    for f in tmp2:
        tefs = tefs.union(f[2])
        famis = famis.union(f[3])
    db_clusters.append([cluster, evalu, tefs, famis])

# for f in db_clusters:
#     print(f)

with open(''.join([pwd, '/memeChipOutput/clusters.csv']), 'w') as f:
    writer = csv.writer(f, quoting=csv.QUOTE_MINIMAL, delimiter=',', lineterminator='\r\n')
    for row in db_clusters:
        tefs = row[2]
        famis = row[3]
        try:
            tefs.remove('')
        except KeyError:
            pass
        try:
            famis.remove('')
        except KeyError:
            pass
        writer.writerow([row[0], row[1], ', '.join(map(str, tefs)), ', '.join(map(str, famis))])
