# I run this script with the following commad:
# tail -n+51 cellosaurus.txt | tr -s ' ' | sed 's/ /\t/g' | awk -v FS="\t" -f cellosaurus_txt_to_tsv.awk  > /mnt/rotation2/endo/data/cellosaurus.tsv
# This won't obviosly work if there are changes to the cellosaurus.txt since those things below are hardcoded. 

#tail -n+31 cellosaurus.txt | head -n 16 | tr -s ' '| cut -f2 -d' ' | awk '{print "arr[\""$0"\"]="NR";"}'
BEGIN {
	arr["ID"]=1;
	arr["AC"]=2;
	arr["AS"]=3;
	arr["SY"]=4;
	arr["DR"]=5;
	arr["RX"]=6;
	arr["WW"]=7;
	arr["CC"]=8;
	arr["ST"]=9;
	arr["DI"]=10;
	arr["OX"]=11;
	arr["HI"]=12;
	arr["OI"]=13;
	arr["SX"]=14;
	arr["AG"]=15;
	arr["CA"]=16;
	nrow=0;
	#tail -n+31 cellosaurus.txt | head -n 16 | tr -s ' '| cut -f2 -d' ' | xargs | sed 's/ /\\t/g'
	print "ID\tAC\tAS\tSY\tDR\tRX\tWW\tCC\tST\tDI\tOX\tHI\tOI\tSX\tAG\tCA";
}

{
	if (code==$1) {
		cont=cont";"$2
	} else {
		if(code=="ID") {
			nrow++
		}
		row[nrow][arr[code]]=cont; 
		cont=$2; 
		code=$1;
	}
}

END {
	for(i=1; i<=nrow; i++) {
		for(j=1; j<16; j++) {
			printf "%s\t", row[i][j]
		}
		printf "%s\n", row[i][j]
	}
}