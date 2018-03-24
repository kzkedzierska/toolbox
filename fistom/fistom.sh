#!/bin/bash
# =============================================================================================================================
# FISTOM - MOTIF SEARCH pipeline
# Author: Katarzyna Kedzierska
# Charlottesville - February, 2017
#
# Usage: motifs.sh [-vqah] [--input INPUT] [--base BASENAME] [--parent PARENT_DIR] [--radius RADIUS] [--markov ORDER]
# [--fasta FASTA_FILE] [-n MOTIFS] [--threads THREADS] [--subset subset] [--meme-db PATH_TO_MEME_DB] [--organism ORGANISM]
#
# Performs thorough motif search with MEME-ChIP from the MEME Suite package. Includes preprocessing of the input
# file and creating of more comprehensible presentation of the results. 
#
# The output consists of the results from the analysis, as well as the processed files all gathered in one dir
# created by basename supplied by user o derieved from input file, region type and narrowing radius in the manner
# nas follows:
#
# directoryName = basename_regionType_narrowingRadius
# 
# Directory can be found in parent DIRectory specified by user. The complete list of the output files with their 
# desription can be found below in the output files bookmark.
#
# The following options are required:
# --input\-i    input peak file, either ANNOTATEd by HOMER or raw peaks in BED format; either full path or just name 
#               IF AND ONLY IF the file is in the parent Directory
# --parent\-p   path to the parent Directory
# --fasta\-f    path to genome fasta file
# --organism\-o     organism, either mouse or zebrafish, required if -annotate option specified or --motif-db not specified
#
# The following options are available:
#
# --annotate\-a     if input is a plain BED file provide annotation with annotatePeaks.pl from homer software 
# --radius\-r       narrowing radius, each peak sequence will be narrowed from teh center of the peak to r bp to the left and 
#                   r bp to the right, default: 250 
# --markov\-m       Markov model order generated for motif search, default: 2
# --threads\-t      number of THREADS used by meme, default: 8. Excerpt from MEME manual:
#                       The parallel version of MEME scales up to about 128 processors. Please see 
#                       http://www.sdsc.edu/~tbailey/papers/cabios96.pdf for a discussion of the parallel program. 
#                       You must bear in mind however, that doubling the total number of sequences input to MEME 
#                       means that you will need 8 times more processors for the job to finish in the same amount of time.
# --nmotifs\-n      number of motifs MEME should look for, increasing the number drastically increses the running time, 
#                   default: 3
# --meme-db\-d      specify path to motif database used by MEME-SUITE, otherwise defaults:
#                   mouse: HOCOMOCO and zebrafish: latest JASPAR_CORE
# --subset\-s       region type, possible regions: gene, intergenic, promoter, geni (intergenic and intragenic) and all, 
#                   default: all
# --base\-b         basename, deafult: basename of the input file
# --verbose         VERBOSE, set -v, 
#                   deafult: --
# --version         prints version of the script
# --help\-h         prints usage info
#
# =============================================================================================================================

#PATHS
ANNOTATE_PEAKS=
BEDTOOLS=
FASTA_GET_MARKOV=
FISTOM_PATH=
MEME_CHIP=
MOTIFS_DB=
PYTHON3=

#set deafults and assign empty variables
ANNOTATE=
BASENAME=
EXITCODE=0
FASTA_FILE=
INPUT_FILE=
LPATH=$(echo $0 | rev | cut -f 2- -d'/' | rev)
MARKOV_MODEL=2
meme_db=
MOTIFS=3
NARROWING_RADIUS=250
ORGANISM=
PARENT_DIR=
PROGRAM=$(basename $0)
REGION_TYPE=all 
THREADS=8 
VERBOSE=
VERSION='0.9 ROT1 (alpha)'


error()
{
    echo -e "$@" 1>&2
    usage_and_exit 1
}

paths()
{
    error 'One or more path variables are undefined. Before running this script remember to run config.sh!'
}

usage() 
{     
    echo -e "Usage: 
$PROGRAM [-vqah] [--input INPUT] [--base BASENAME] [--parent PARENT_DIR] [--radius RADIUS] [--markov ORDER] [--fasta FASTA_FILE]
            [-n MOTIFS] [--threads THREADS] [--subset subset] [--meme-db PATH_TO_MEME_DB] [--organism ORGANISM]

$PROGRAM version $VERSION

Performs thorough motif search with MEME-ChIP from the MEME Suite package. Includes preprocessing of the input file and 
creating of more comprehensible presentation of the results.

The output consists of the results from the analysis, as well as the processed files all gathered in one dir created 
by basename supplied by user o derieved from input file, region type and narrowing radius in the manner as follows:

directoryName = basename_regionType_narrowingRadius
 
Directory can be found in parent DIRectory specified by user. The complete list of the output files with their desription 
can be found below in the output files bookmark.

The following options are required:
    --input\-i      input peak file, either ANNOTATEd by HOMER or raw peaks in BED format; either full path or just name 
                    <=> the file is in the parent Directory
    --parent\-p     path to the parent Directory
    --fasta\-f      path to fasta file
    --organism\-o   organism, either mouse or zebrafish, required if -annotate option specified or --meme-db not specified

The following options are available:

    --annotate\-a   if input is a plain BED file provide annotation with annotatePeaks.pl from homer software
    --radius\-r     narrowing radius, each peak sequence will be narrowed from teh center of the peak to r bp to the left 
                    and r bp to the right, default: 250 
    --markov\-m     Markov model order generated for motif search, default: 2
    --threads\-t    number of THREADS used by meme, default: 8. Excerpt from MEME manual:
                        The parallel version of MEME scales up to about 128 processors. Please see 
                        http://www.sdsc.edu/~tbailey/papers/cabios96.pdf for a discussion of the parallel program. 
                        You must bear in mind however, that doubling the total number of sequences input to MEME 
                        means that you will need 8 times more processors for the job to finish in the same amount of time.
    --nmotifs\-n    number of motifs MEME should look for, increasing the number drastically increses the running time, 
                    default: 3
    --meme-db\-d    specify path to the motif database used by MEME-SUITE, otherwise defaults:
                    mouse: HOCOMOCO and zebrafish: latest JASPAR_CORE
    --subset\-s     region type, possible regions: gene, intergenic, promoter, geni (intergenic and intragenic) and all, 
                    default: all
    --base\-b       basename, deafult: basename of the input file
    --verbose\-v    VERBOSE, set -v, deafult: --
    --version       prints version of the script
    --help\-h       prints usage info"
}

usage_and_exit()
{
    usage
    exit $1
}

version()
{
    echo "$PROGRAM version $VERSION"
}

#warning()
#{
#    echo "$@" 1>&2
#    EXITCODE=`expr $EXITCODE + 1`
#}

#check path variables
if [[ -z $BEDTOOLS || -z $MOTIFS_DB || -z $MEME_CHIP || -z $ANNOTATE_PEAKS || -z $FASTA_GET_MARKOV || -z $PYTHON3 || -z $FISTOM_PATH ]]; then
    paths
fi

echo `date` "Script run with the following options:" $0 $@ >&2 

#options
while test $# -gt 0
do 
    case $1 in
    -i | --input )
        shift  
        INPUT_FILE="$1"
        ;;
    -f | --fasta )
        shift
        FASTA_FILE="$1"
        ;;
    --annotate | -a )  
        ANNOTATE=true
        ;;
    --radius | -r ) 
        shift 
        NARROWING_RADIUS="$1"
        #narrowing radius
        ;;
    --markov | -m )
        shift
        MARKOV_MODEL="$1"
        #Markov model order
        ;;
    --meme-db | -d )
        shift
        meme_db="$1"
        ;;
    --threads | -t )
        shift  
        THREADS="$1"
        ;;
    --nmotifs | -n )  
        shift
        MOTIFS="$1"
        ;;
    --subset | -s )
        shift  
        REGION_TYPE="$1"
        ;;
    --base | -b )  
        shift
        BASENAME="$1"
        ;;
    --parent | -p )
        shift  
        PARENT_DIR="$1"
        ;;
    --verbose | -v)	
        VERBOSE=true
		;;
    --organism | -o )
        shift
        ORGANISM="$1"
        ##supporting only zebrafish and mouse for now
        ;;
    --version )
        version
        exit 0
        ;;
    --help | -h | '-?' | '--?' ) 
         usage_and_exit 0
         ;;
    -*) 
        error "Unrecognized option: $1"
        ;;
    *)
        break
        ;;
    esac
    shift
done

echo $INPUT_FILE $FASTA_FILE $PARENT_DIR >&2

#check for the necessary arguments
if [ -z "$INPUT_FILE" -o -z "$FASTA_FILE" -o -z "$PARENT_DIR" ]; then
    error "Parent directory, input or fasta file not specifed."
fi

if [ -z "$meme_db" -a -z "$ORGANISM" ] || [ -n "$ANNOTATE" -a -z "$ORGANISM" ]; then
    error "Organism option not specified."
fi

#if no basename specified create one from the file name
if [ "X$BASENAME" = "X" ]; then
   BASENAME=$(basename $INPUT_FILE | rev | cut -f1 -d'.' | rev)
fi

#verbose mode
if [ "X$VERBOSE" = "Xtrue" ]; then
	set -v
fi

#subsets 
gene='exon|intron|3-UTR|TTS'
promoter='promoter-TSS|5-UTR'
intergenic='non-coding|Intergenic'
geni='exon|intron|3-UTR|TTS|non-coding|Intergenic'
all='promoter-TSS|5-UTR|exon|intron|3-UTR|TTS|non-coding|Intergenic|NA'

echo 'Running script on a file:' $INPUT_FILE >&2
echo $BASENAME >&2
echo 'Narrowing peaks to summit+/-:' $NARROWING_RADIUS >&2

mkdir -p $PARENT_DIR
cd $PARENT_DIR

DIR=${BASENAME}'_'$REGION_TYPE'_'${NARROWING_RADIUS};

mkdir -p $DIR;
echo $(pwd) >&2

if [ -n "$ORGANISM" ] && [ "X$ORGANISM" != "Xmouse" -a "X$ORGANISM" != "Xzebrafish" ]; then
        error "Error! Invalid argument used for the --organism option:" $ORGANISM "\navailable: mouse or zebrafish"
fi

if [ "X$ORGANISM" = "Xmouse" ]; then 
    genome="mm10";
    meme_db=$MOTIFS_DB/MOUSE/$(ls $MOTIFS_DB/MOUSE/ | grep HOCO*) 
fi

if [ "X$ORGANISM" = "Xzebrafish" ]; then 
    genome="danRer7";
    meme_db=$MOTIFS_DB/JASPAR/$(ls $MOTIFS_DB/JASPAR/ | grep vertebrates | grep -v REDUNDANT | sort -nrk3,3 -t'_' | head -n1) 
fi

#annotating peaks 
if [ "$ANNOTATE" = "true" ]; then
    $ANNOTATE_PEAKS 2>&1 >/dev/null | grep $genome
    if [ $? -ne 0 ]; then
        error "annotatePeaks.pl command error, the genome $genome is not installed, try running \nperl /path-to-homer/configureHomer.pl -install $genome";
        usage_and_exit
    fi
    if [ $ncols -gt 4 ]; then
        error "To many fields in the bed file!"
    fi
    cat $INPUT_FILE | sed 's/^/chr/g' > $DIR/$BASENAME.editedPeaks;
    $ANNOTATE_PEAKS $DIR/$BASENAME.editedPeaks $genome > $DIR/$BASENAME.annotatedPeaks;
    if [ $? -ne 0 ]; then
        error "annotatePeaks.pl command error";
        usage_and_exit
    fi
    INPUT_FILE=$DIR/$BASENAME.annotatedPeaks;
fi

#some cosmetic changes to the INPUT_FILE
sed "s/3' UTR/3-UTR/g" $INPUT_FILE > $INPUT_FILE.tmp;
sed -i "s/5' UTR/5-UTR/g" $INPUT_FILE.tmp;

eval pattern=\$$REGION_TYPE;
echo $pattern >&2 

#filtering specific region from the annotated file
grep -E $pattern $INPUT_FILE.tmp | 
    cut -f2-4,9 | 
        sed 's/^chr//g' | 
            awk -v var=$NARROWING_RADIUS '{print $1,int(($2+$3)/2-var),int(($2+$3)/2+var)}' | 
                sed -e "s/\ /\t/g" | 
                    sort -k1,1n -k2,2n > ${DIR}/sortedNarrow.bed;

echo 'After pattern matching' `date` >&2

#rm -f $INPUT_FILE.tmp

#extracting fasta sequences from bed files
if [ ! -s ${DIR}/peaksSeq.fa ]; then 
   $BEDTOOLS getfasta -fi $FASTA_FILE -bed ${DIR}/sortedNarrow.bed > ${DIR}/peaksSeq.fa;
   echo 'Finished running getfasta:' `date` >&2
fi

#generating Markov model
if [ ! -s ${DIR}/markov_$MARKOV_MODEL.bfile ]; then 
   $FASTA_GET_MARKOV -m $MARKOV_MODEL ${DIR}/peaksSeq.fa ${DIR}/markov_${MARKOV_MODEL}.bfile;
   echo 'Finished runnning markov model (order $MARKOV_MODEL) generator:' `date` >&2
fi

echo 'Starting meme-chip:' `date` >&2
$MEME_CHIP -oc ${DIR}/memeChipOutput \
            -db $meme_db \
            -dna \
            -bfile ${DIR}/markov_${MARKOV_MODEL}.bfile \
            -nmeme $(wc -l < ${DIR}/sortedNarrow.bed) \
            -norand \
            -ccut 150 \
            -meme-maxw 11 \
            -meme-nmotifs ${MOTIFS} \
            -meme-p ${THREADS} \
            -meme-maxsize 10000000 ${DIR}/peaksSeq.fa >&2

#Summarising the data
#possible issues with sed versions and pattern \< or < 
sed -n '/JSON/,/<\/script>/p' ${DIR}/memeChipOutput/index.html | 
    tail -n +2 | 
        sed '/^$/d;s/[[:blank:]]//g' | 
            sed '$ d' | 
                tr -d "\n" | 
                    sed 's/;//g' | 
                        sed 's/vardata=//g' > ${DIR}/memeChipOutput/JSON.txt 

#create clusters
$PYTHON3 $FISTOM_PATH/extractor.py -d $DIR -m $FISTOM_PATH/motifs.db.csv >&2

echo  'Finished:' `date` >&2
