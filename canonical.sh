#!bin/bash
#==============================================================================
#description:   Generate bed file with CDS of exons for canonical transcripts. 
#               INPUT: gtf formatted file (either file or stdin)
#               OUTPUT: bed file witch 4th column with ENSEMBL transcript ID 
#                       and 5th column with gene name. 
#author:        Katarzyna Kedzierska
#date:          December 6th, 2017
#usage:         bash canonical.sh INPUT or to be used in a pipeline (== can 
#               read from stdin)
#==============================================================================

#=======
#TODO:
#* add option for outputing transcripts or transcript-cds instead of exon-cds.
#=======

if [[ "X$1" == "X" ]]; then
    INPUT=/dev/stdin
else
    INPUT=$1
fi

: ' Hierarchy: longest CCDS protein_coding > longest protein_coding > longest CCDS > longest transcript
'

cat $INPUT|
    awk \
'BEGIN {
    OFS=FS="\t"
}
{
    if ($3 == "CDS") {
        type=0
        if($9 ~ /tag \"CCDS\"/) { 
            type++
        } 
        if ($9 ~ /transcript_type "protein_coding"/) {
            type+=2
        }
        print $1,$4,$5,$9,type
    }
}' | sed 's/gene_id.*transcript_id "\([^"]*\)".*gene_name "\([^"]*\).*\([0-9]\)$/\1\t\2\t\3/g' | 
    awk \
'BEGIN {
    lenone=0
    lensecond=0
    OFS="\t"
}
{
    if (gene==$5 && t1==$4) {
        #add exons to transcript length
        longest[length(longest)+1] = $0;
        lenone+=$3-$2
    }
    else if (gene==$5 && t1!=$4) {
        if ($6 >= typeone) { #not interested with transcripts lower in hierarchy
            if (t2 == $4) {
                second[length(second)+1] = $0;
                lensecond+=$3-$2
            }
            else {
                if ((lensecond > lenone) || (typesec > typeone)) {
                    #if have two transcript and encountered third, decide which stays as the longest, CCDS or the longest.
                    delete longest
                    t1=t2
                    lenone=lensecond
                    typeone=typesec
                    for(i=1; i<length(second)+1; i++) {
                        longest[i]=second[i]
                    }
                }
                delete second;
                typesec=$6
                second[1]=$0;
                lensecond=$3-$2
                t2=$4
            }
        }
    }
    else {
        if ((lensecond > lenone > 0 && typesec == typeone) || (typesec > typeone)) {
            #if have two transcript and moved to another gene, check which and keep the longest
            for(i=1; i<length(second)+1; i++) {
                print second[i]
            }
        }
        else if (lenone > 0) {
            for(i=1; i<length(longest)+1; i++) {
                print longest[i]
            }
        }
        gene=$5;
        t1=$4;
        t2="";
        delete longest;
        delete second;
        typeone=$6
        typesec=0
        lensecond=0;
        longest[1]=$0;
        lenone=$3-$2;
    }
}

END {
    if ((lensecond > lenone > 0 && typesec == typeone) || (typesec > typeone)) {
        #if have two transcript and moved to the end of a gene, check which and keep the longest
        for(i=1; i<length(second)+1; i++){
            print second[i]
        }
    }
    else if (lenone > 0) {
        for(i=1; i<length(longest)+1; i++) {
            print longest[i]
        }
    }
}' | cut -f1-5 | sed 's/\.[0-9]*\t/\t/g'
