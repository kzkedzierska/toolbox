#FISTOM
This piepeline depends on:
meme, meme-chip from MEME Suite; bedtools; annotatePeaks.pl from homer and Python3. FISTOM package itself consist of four files:
  
* config.sh  
script that checks if all required software is installed and configures the path directories in the main program file.                     Need to be run succesfylly only once, but must be run in the same directory that fistom.sh is localized.
* extractor.py  
tool responsible for JSON object extraction and generation of families clusters, (written in Python 3.6.0)  
* fistom.sh  
this is the main program, it invokes all the necessary commands to perform analysis according to given pipeline. For                       more information use fistom.sh --help  
* motifs.db.csv  
database consisitng of motifs ids and families  
