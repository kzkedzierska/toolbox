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
    awk -v FS="\t" '$3 ~ "exon"' | 
        sed 's/gene_id.*transcript_id "\([^"]*\)".*gene_name "\([^"]*\)"; transcript_type "\([^"]*\).*/\1\t\2\t\3/g' | 
            cut -f1,4,5,9- | 
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
        if (t2!=$4) {
            #print t1, typelong, lenone, t2, typesec, lensecond
            if ((lensecond > lenone > 0 && typelong != "protein_coding") || (lensecond > lenone > 0 && typelong == typesec) || (typelong != "protein_coding" && typesec == "protein_coding")) {
                #if have two transcript and encountered third, decide which stays as the longest: protein_coding one or the longest one if both or neither are protein_coding
                delete longest
                t1=t2
                typelong=typesec
                lenone=lensecond
                for(i=1; i<length(second)+1; i++){
                    longest[i]=second[i]
                }
            }
            delete second;
            second[1]=$0;
            lensecond=$3-$2
            t2=$4
            typesec=$6
        }

        else if (t2==$4) {
            if (lensecond==0) {
                second[1]=$0;
                typesec=$6
            }
            else {
                second[length(second)+1] = $0;
            }
            lensecond+=$3-$2
        }
        
    }
    else {
        if ((lensecond > lenone > 0 && typelong != "protein_coding") || (lensecond > lenone > 0 && typelong == typesec) || (typelong != "protein_coding" && typesec == "protein_coding")) {
            #if have two transcript and moved to another gene, decide which stays as the longest: protein_coding one or the longest one if both or neither are protein_coding
            for(i=1; i<length(second)+1; i++){
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
        lensecond=0;
        longest[1]=$0;
        lenone=$3-$2;
        typelong=$6;
        typesec="";
    }
}

END {
    if ((lensecond > lenone > 0 && typelong != "protein_coding") || (lensecond > lenone > 0 && typelong == typesec) || (typelong != "protein_coding" && typesec == "protein_coding")) {
        #if have two transcript and moved to the end of a gene, decide which stays as the longest: protein_coding one or the longest one if both or neither are protein_coding
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
