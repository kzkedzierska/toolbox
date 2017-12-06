BEGIN {
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
}