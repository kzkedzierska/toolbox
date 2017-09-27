#!bin/bash
#The purpose of this script is to check if all required software is installed and to find all the necessarry paths.
#MUST BE RUN IN DIR THAT FISTOM.SH IS LOCALIZED!

error()
{
    echo "$@" 1>&2
    echo "If you are sure that all the necessarry programs are installed and for some reason this script is not working, try specifing the paths in fistom.sh manually."
    usage_and_exit 1
}

usage_and_exit()
{
    usage
    exit $1
}

usage() 
{     
    echo -e "Usage: config.sh
    The sole purpose of this script is to configure PATH variables in fistom.sh"
}

replace() 
{
	sed -i $(echo 's#'$1'.*#'$2'#g') $3
}

ANNOTATE_PEAKS=$(command -v annotatePeaks.pl)
if [ -z "$ANNOTATE_PEAKS" ]; then
	error "annotatePeaks.pl command not found; Are you sure it's installed? annotatePeaks.pl is a part of HOMER package (http://homer.ucsd.edu/homer/) that is required for peak annotation."
fi

BEDTOOLS=$(command -v bedtools)
if [ -z "$BEDTOOLS" ]; then
	error "bedtools command not found. Are you sure it's installed?"
fi

MEME_CHIP=$(command -v meme-chip)
if [ -z "$MEME_CHIP" ]; then
	error "meme-chip command not found. Are you sure this component of MEME-SUITE is installed?"
fi

FASTA_GET_MARKOV=$(command -v fasta-get-markov)
if [ -z "$FASTA_GET_MARKOV" ]; then
	error "fasta-get-markov command not found. Are you sure this component of MEME-SUITE is installed?"
fi

MOTIFS_DB=$(locate ~/*/motif_databases/*.meme | head -n1 | sed 's/motif_databases.*/motif_databases\//')
if [ -z "$MOTIFS_DB" ]; then
	error "Unable to find MEME motif databases. Databases can be download from http://meme-suite.org/doc/download.html"
fi

PYTHON3=$(command -v python3)
if [ -z "$PYTHON3" ]; then
	error "Seems like there is no python 3.x version installed."
fi

#I want to know where the components are kept, it'll be necessary later
FISTOM_PATH=$(pwd -P)
n=1
while : ; do
	if test -s $FISTOM_PATH/jsonExtract.py && test -s $FISTOM_PATH/motifs.db.csv; then
		break
	else
		if [ n -eq 1 ]; then
			echo -e "Hmmm, I cannot to seem to identify the PATH for fistom package. Please provide the PATH to the whole fistom directory where I can find motifs_db and extractor files.\n"
		else
			echo -e "Something didn't go right. You provided $FISTOM but I still cannot find those files there... Try again.\n"
		fi
		read FISTOM_PATH
		if [ n -eg 4 ]; then
			error "To many attempts to supplying the PATH for fistom, verify that you downloaded all the files (visit README for more details) and try again."
		fi
		let "n++"
	fi	 
done

replace ANNOTATE_PEAKS= ANNOTATE_PEAKS=$ANNOTATE_PEAKS fistom.sh
replace BEDTOOLS= BEDTOOLS=$BEDTOOLS fistom.sh
replace FASTA_GET_MARKOV= FASTA_GET_MARKOV=$FASTA_GET_MARKOV fistom.sh
replace FISTOM_PATH= FISTOM_PATH=$FISTOM_PATH fistom.sh
replace MEME_CHIP= MEME_CHIP=$MEME_CHIP fistom.sh
replace MOTIFS_DB= MOTIFS_DB=$MOTIFS_DB fistom.sh
replace PYTHON3= PYTHON3=$PYTHON3 fistom.sh
