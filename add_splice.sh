#!bin/bash
#==============================================================================
#description:   Add splice regions to CDS intervals.  . 
#author:        Katarzyna Kedzierska
#date:          March 23rd, 2018
#usage:         bash add_splice.sh INPUT or to be used in a pipeline (== can 
#               read from stdin)
#==============================================================================

if [[ "X$1" == "X" ]]; then
    INPUT=/dev/stdin
else
    INPUT=$1
fi

cat $INPUT | 
	sort -k1,1 -k2,2n | awk -v OFS="\t" \
'{if ($4 == transcript) {
  if (count > 1) {
    print chrom, start-8, end+8, transcript, gene
  } else {
    print chrom, start, end+8, transcript, gene
  }
  chrom=$1
  start=$2
  end=$3
  count++
} else {
  if (transcript != "") {
    if (count > 0) {
      print chrom, start-8, end, transcript, gene
    } else {
      print chrom, start, end, transcript, gene
    }
  }
  
  chrom=$1
  start=$2
  end=$3
  count=1
  transcript=$4
  gene=$5
}} 

END {
  if (count > 0) {
    print chrom, start-8, end, transcript, gene
  } else {
    print chrom, start, end, transcript, gene
  }
}'