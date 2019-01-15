#!/usr/bin/bash
#==============================================================================
#description:   Get VAFs and REF/ALT counts for alleleCounter files 
#author:        Katarzyna Kedzierska
#date:          January 10, 2019
#place:         Oxford, UK
#usage:         join_alleleCounter_with_ref.sh [-g] [--path PATH] FILEPATH REF
#==============================================================================


# Defining helper functions
error()
{
    echo -e "$@" 1>&2
    usage_and_exit 1
}

usage()
{
  echo -e "
$PROGRAM [-g] [--path OUTPATH] FILEPATH REF

Given alleleCounter output and the reference file with mutation locations 
add columns with REF, ALT, updated DEPTH = REF+ALT and VAF.
  
Arguments:
  
FILEPATH   path to the alleleCounter output
REF        path to the reference file; formatted as gzipped, 
           tab-deliminated file with following columns 
           chrom, start, end, ref_base, alt_base. Assumes no header.
           ftp://ftp.sanger.ac.uk/pub/teams/113/Battenberg/battenberg_1000genomesloci2012_v3.tar.gz

Options:

--gzip\-g          gzip the output [Recomended, reduces the size significantly]
--path\-p OUTPATH  output path, default: ./
--version          prints version of the script
--help\-h          prints usage info"
}

usage_and_exit()
{
    usage
    exit $1
}

# Initializing variables
GZIP=
PARAMS=
OUTPATH="."
PROGRAM=$(basename $0)

# Get options
while (( "$#" )); do
  case "$1" in
    --gzip | -g ) 
      GZIP=true
      shift 1
      ;;
    --help | -h | '-?' | '--?' ) 
      usage_and_exit 0 
      ;;
    -p | --path)
       OUTPATH=$2
       shift 2
       ;;
    --) # end argument parsing
       shift
       break
       ;;
    -*|--*=) # unsupported flags
       error "Error: Unsupported flag $1"
       ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

# Set positional arguments in their proper place
eval set -- "$PARAMS"

# Get arguments
FILEPATH=$1
REF=$2 # path to battenberg_1000genomesloci2012_v3.txt.gz

echo $FILEPATH $REF

# Test
if [ -z $FILEPATH ]; then
  error "Path to the alleleCounter file is missing!"
fi

if [ -z $REF ]; then
  error "Missing the path to reference file!"
fi

if [ ! \( -e $REF -a -e $FILEPATH \) ]; then
  error "At least one of the provided iles does not exist."
fi

# Get the basename of the file, it will serve as the output filename.
FNAME=$(basename ${FILEPATH});

echo "Working on files: alleleCounter: $FNAME and reference: $REF, 
saving output under the name: $FNAME to the following directory: $OUTPATH";


echo -e "CHR\tSTART\tEND\tA\tC\tG\tT\tDEPTH\tREF_BASE\tALT_BASE\tREF\tALT\tDEPTH2\tVAF" > ${OUTPATH}/${FNAME}

join -j 1 <(zcat ${REF} | awk '{print $1":"$2, $0}' | sort -k1,1) \
      <(tail -n+2 ${FILEPATH}  | awk '{print $1":"$2, $0}' | sort -k1,1) | 
  awk -v OFS="\t" '
{
  depth2 = ($($5+8)+$($6+8)); 
  alt = $($6+8); 
  if (depth2 == 0){
    vaf = 0
  } else {
    vaf = alt/depth2
  }; 
    print $2, $3, $4, $9, $10, $11, $12, $13, $5, $6, $($5+8), $($6+8), depth2, vaf}' |
      sort -k1,1 -k2,2n  >> ${OUTPATH}/${FNAME}


if [ ! -z $GZIP ]; then 
  echo "bgzipping the output file."
  /apps/well/tabix/0.2.6/bgzip ${OUTPATH}/${FNAME};
fi
