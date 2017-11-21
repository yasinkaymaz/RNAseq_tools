#!/bin/bash

source new-modules.sh
export PATH=/n/home13/yasinkaymaz/biotools/kallisto_linux-v0.43.1:$PATH

#LABspace=/n/holylfs/LABS/informatics/yasinkaymaz
LABspace=/n/home13/yasinkaymaz/regalSpace

SAMPLE_NAME=$1
LibraryType=$2
nt=$3
Fastq1=$4
Fastq2=$5


if [ -z "$Fastq2" ] ; then
  Pairness='--single -l 200 -s 20'
else
  Pairness=''
fi

kallisto quant -i $LABspace/References/GRCh38/kallisto/GRCh38_ref.transcripts.idx \
-o kallisto."$SAMPLE_NAME" \
$Pairness \
-t $nt \
--bias \
$Fastq1 $Fastq2


#kallisto pseudo -i $LabSpace/References/GRCh38/kallisto/GRCh38_ref.transcripts.idx \
#-t $nt -o kallisto.output -b $BatchFile
