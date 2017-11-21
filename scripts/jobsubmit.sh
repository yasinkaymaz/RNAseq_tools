

for SAMPLE_NAME in `ls -1 /home/yk42w/project/yk42w/data/RNAseq/eBLSamples/|grep eBL`;
do
ls -al /home/yk42w/project/yk42w/data/RNAseq/eBLSamples/$SAMPLE_NAME;

for type in 1 2;
do

bsub -q long -n 4 -R rusage[mem=20000] -R "select[tmp>1000]" -W 08:00 \
-e "$SAMPLE_NAME"_"$type"_err.%J.txt -o "$SAMPLE_NAME"_"$type"_out.%J.txt \
~/codes/RNAseq_tools/scripts/kallisto-exp-quantify.sh \
"$SAMPLE_NAME"_"$type"_TotalRNA_EBV stranded 4 \
~/project/yk42w/data/RNAseq/eBLSamples/$SAMPLE_NAME/"$SAMPLE_NAME"_cutAdpted_1.fastq.gz \
~/project/yk42w/data/RNAseq/eBLSamples/$SAMPLE_NAME/"$SAMPLE_NAME"_cutAdpted_2.fastq.gz \
EBV $type

sleep 1;

done
done
