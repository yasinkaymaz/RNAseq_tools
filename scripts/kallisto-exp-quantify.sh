#!/bin/bash

toolDir='/home/yk42w/codes/RNAseq_tools'
export PATH=$toolDir/bin/linux/kallisto_linux-v0.43.1:$PATH

SAMPLE_NAME=$1
#stranded or nonstranded
LibraryType=$2
#number of threads to use.
nt=$3
Fastq1=$4
Fastq2=$5
#organism is ether "human" or "EBV"
Organism=$6
#optional EBV type. Required only when EBV is used. Either 1 or 2.
type=$7


if [ -z "$Fastq2" ] ; then
  Pairness='--single -l 200 -s 20'
else
  Pairness=''
fi

if [ Organism == "human" ];
then
  index_file=''
else
  index_file=$toolDir/'resources/EBV/kallisto/'$EBVtype'/EBV_transcripts'
fi

kallisto quant -i $index_file \
-o kallisto."$SAMPLE_NAME" \
$Pairness \
-t $nt \
--bias \
$Fastq1 $Fastq2
