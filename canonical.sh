#!bin/bash
#==============================================================================
#description:   Generate bed file with exons for canonical transcripts.
#               INPUT: gtf formatted file (either file or stdin)
#               OUTPUT: bed file witch 4th column with ENSEMBL transcript ID 
#                       and 5th column with gene name. 
#author:        Katarzyna Kedzierska
#date:          December 6th, 2017
#usage:         bash canonical.sh INPUT or to be used in a pipeline (== can 
#               read from stdin)
#==============================================================================


if [[ "X$1" == "X" ]]; then
    INPUT=/dev/stdin
else
    INPUT=$1
fi
cat $INPUT|
    awk -v FS="\t" '$3 ~ "exon" && $9 ~ /transcript_status "KNOWN"/' | 
        sed 's/gene_id.*transcript_id "\([^"]*\)".*gene_name "\([^"]*\)".*/\1\t\2/g' | 
            cut -f1,4,5,9,10 | 
                awk \
'BEGIN {
    lenone=0
    lensecond=0
    OFS="\t"
}

{
    if (gene==$5 && t1==$4) {
        longest[length(longest)+1] = $0;
        lenone+=$3-$2
    }
    else if (gene==$5 && t1!=$4) {
        if (t2!=$4) {
            if (lensecond > lenone > 0) {
                delete longest
                for(i=1; i<length(second)+1; i++){
                    longest[i]=second[i]
                }
            }
            delete second;
            lensecond=0;
            second[1] = $0;
            lensecond+=$3-$2
            t2=$4
        }

        else if (t2==$4) {
            if (lensecond==0) {
                second[1] = $0;
            }
            else {
                second[length(second)+1] = $0;
            }
            lensecond+=$3-$2
        }
        
    }
    else {
        if (lensecond > lenone > 0) {
            delete longest
            for(i=1; i<length(second)+1; i++){
                longest[i]=second[i]
            }
        }
        else if (lensecond == lenone && lenone != 0) {
                print "Problem for gene: "gene" and transcripts: "t1, t2
        }
        if (lenone > 0) {
            for(i=1; i<length(longest)+1; i++) {
                print longest[i]
            }
        }
        gene=$5;
        t1=$4;
        t2="";
        delete longest;
        delete second;
        lensecond=0;
        longest[1]=$0;
        lenone=$3-$2;
    }
}

END {
    if (lenone > 0) {
            for(i=1; i<length(longest)+1; i++) {
                print longest[i]
            }
        }
}'